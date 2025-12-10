import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:model_factory/model_factory_annotation.dart';

class ModelFactoryGenerator extends GeneratorForAnnotation<ModelFactory> {
  ModelFactoryGenerator([Map<String, dynamic>? config])
      : _globalDefaults = _parseTypeDefaults(config);

  /// Defaults from build.yaml (per type, e.g. "String", "int", "DateTime")
  final Map<String, String> _globalDefaults;

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ModelFactory can only be used on classes',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.displayName;
    final factoryName = '${className}Factory';

    // CLASS-LEVEL DEFAULTS: @ModelFactory(defaults: { 'field': 'code' })
    final classDefaults = _parseClassDefaults(annotation);

    final buffer = StringBuffer();

    buffer.writeln('class $factoryName {');
    buffer.writeln('  const $factoryName._();');
    buffer.writeln();

    final fields = <_FieldInfo>[];

    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic || field.isPrivate) continue;

      final String fieldName = field.name ?? '';
      if (fieldName.isEmpty) continue;

      final DartType type = field.type;

      final typeStrNonNull = type.getDisplayString(withNullability: false);
      final paramType = '$typeStrNonNull?';
      final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

      final fakeCode =
          _resolveFakeValue(field, type, classDefaults, _globalDefaults);

      fields.add(
        _FieldInfo(
          name: fieldName,
          paramType: paramType,
          fakeCode: fakeCode,
          isNullable: isNullable,
        ),
      );
    }

    buffer.writeln('  static $className build({');
    for (final f in fields) {
      buffer.writeln('    ${f.paramType} ${f.name},');
    }
    buffer.writeln('  }) {');

    buffer.writeln('    return $className(');
    for (final f in fields) {
      if (f.isNullable) {
        // Nullable → usa diretamente o parâmetro (default null)
        buffer.writeln('      ${f.name}: ${f.name},');
      } else {
        // Non-nullable → parâmetro ou fake default
        buffer.writeln('      ${f.name}: ${f.name} ?? ${f.fakeCode},');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }

  // ----------------------------------------------------------
  // RESOLUTION PRIORITY
  // field annotation → class defaults → build.yaml → built-in → nested model
  // ----------------------------------------------------------

  String _resolveFakeValue(
    FieldElement field,
    DartType type,
    Map<String, String> classDefaults,
    Map<String, String> globalDefaults,
  ) {
    final typeStr = type.getDisplayString(withNullability: false);

    // 1) FIELD-LEVEL DEFAULT VIA @FactoryDefault
    final fieldDefault = _readFieldAnnotationDefault(field);
    if (fieldDefault != null) return fieldDefault;

    // 2) CLASS-LEVEL DEFAULT VIA @ModelFactory(defaults: {...})
    final classDefault = classDefaults[field.name];
    if (classDefault != null) return classDefault;

    // 3) GLOBAL DEFAULT VIA build.yaml
    final global = globalDefaults[typeStr];
    if (global != null) return global;

    // 4) Built-in defaults
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return 'null';
    }

    final element = type.element;

    // Enums → first case
    if (element is EnumElement) {
      final constants = element.fields.where((f) => f.isEnumConstant).toList();
      if (constants.isNotEmpty) {
        return '$typeStr.${constants.first.name}';
      }
    }

    // Primitives
    if (typeStr == 'String') return "''";
    if (typeStr == 'int') return '0';
    if (typeStr == 'double') return '0.0';
    if (typeStr == 'num') return '0';
    if (typeStr == 'bool') return 'false';
    if (typeStr == 'DateTime') return 'DateTime(2000, 1, 1)';

    // Lists
    if (type is ParameterizedType &&
        typeStr.startsWith('List<') &&
        typeStr.endsWith('>') &&
        type.typeArguments.isNotEmpty) {
      final innerFake = _resolveFakeValue(
        field,
        type.typeArguments.first,
        classDefaults,
        globalDefaults,
      );
      return '[$innerFake]';
    }

    // Fallback → nested model factory
    return '${typeStr}Factory.build()';
  }

  // ----------------------------------------------------------
  // FIELD-LEVEL ANNOTATION @FactoryDefault("...")
  // ----------------------------------------------------------

  String? _readFieldAnnotationDefault(FieldElement field) {
    final dynamic rawMetadata = field.metadata;

    Iterable<dynamic> annotations;

    if (rawMetadata is Iterable) {
      annotations = rawMetadata;
    } else {
      final dynamic maybeAnnotations = (rawMetadata as dynamic).annotations;
      if (maybeAnnotations is Iterable) {
        annotations = maybeAnnotations;
      } else {
        return null;
      }
    }

    for (final ann in annotations) {
      final value = (ann as dynamic).computeConstantValue();
      if (value == null) continue;

      final typeName = value.type?.element?.name;
      if (typeName == 'FactoryDefault') {
        final code = value.getField('code')?.toStringValue();
        if (code != null) {
          return code;
        }
      }
    }
    return null;
  }

  // ----------------------------------------------------------
  // CLASS-LEVEL @ModelFactory(defaults: {...})
  // ----------------------------------------------------------

  Map<String, String> _parseClassDefaults(ConstantReader annotation) {
    final defaultsReader = annotation.peek('defaults');
    if (defaultsReader == null || defaultsReader.isNull) {
      return {};
    }

    final result = <String, String>{};

    defaultsReader.mapValue.forEach((key, value) {
      final k = key?.toStringValue();
      final v = value?.toStringValue();
      if (k != null && v != null) {
        result[k] = v;
      }
    });

    return result;
  }

  // ----------------------------------------------------------
  // GLOBAL DEFAULTS (build.yaml)
  // ----------------------------------------------------------

  static Map<String, String> _parseTypeDefaults(
    Map<String, dynamic>? config,
  ) {
    final result = <String, String>{};

    final defaults = config?['defaults'];
    if (defaults is Map) {
      defaults.forEach((key, value) {
        if (key is String && value is String) {
          result[key] = value;
        }
      });
    }

    return result;
  }
}

class _FieldInfo {
  final String name;
  final String paramType;
  final String fakeCode;
  final bool isNullable;

  _FieldInfo({
    required this.name,
    required this.paramType,
    required this.fakeCode,
    required this.isNullable,
  });
}
