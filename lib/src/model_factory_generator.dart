import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:model_factory/model_factory_annotation.dart';

class ModelFactoryGenerator extends GeneratorForAnnotation<ModelFactory> {
  ModelFactoryGenerator([Map<String, dynamic>? config])
      : _typeDefaults = _parseTypeDefaults(config);

  /// Map from type name (e.g. "String", "int", "DateTime") to Dart code
  /// string to use as default (e.g. "'foo'", "42", "DateTime(2020, 1, 1)").
  final Map<String, String> _typeDefaults;

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ModelFactory/@modelFactory can only be used in classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = classElement.displayName;
    final factoryName = '${className}Factory';

    final buffer = StringBuffer();

    buffer.writeln('class $factoryName {');
    buffer.writeln('  const $factoryName._();');
    buffer.writeln();

    final fields = <_FieldInfo>[];

    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic || field.isPrivate) continue;

      final String? fieldName = field.name;
      if (fieldName == null || fieldName.isEmpty) continue;

      final DartType type = field.type;

      final typeStrNonNull = type.getDisplayString(withNullability: false);
      final paramType = '$typeStrNonNull?';

      final fakeCode = _fakeValueForType(type);
      final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

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
        // Nullable → use parameter as-is (default null)
        buffer.writeln('      ${f.name}: ${f.name},');
      } else {
        // Non-nullable → parameter or fake default
        buffer.writeln('      ${f.name}: ${f.name} ?? ${f.fakeCode},');
      }
    }

    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Decide fake value for a given type, considering:
  /// 1. Override from build.yaml (if configured)
  /// 2. Built-in defaults (String, int, double, bool, DateTime, enums, lists)
  /// 3. Nested model factory (TypeFactory.build())
  String _fakeValueForType(DartType type) {
    // If nullable, just return null (only used when param is not provided)
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return 'null';
    }

    final typeStr = type.getDisplayString(withNullability: false);

    // 1) Check overrides from build.yaml
    final override = _typeDefaults[typeStr];
    if (override != null) {
      // We assume the user provided a valid Dart expression
      return override;
    }

    final element = type.element;

    // ENUMS → first case
    if (element is EnumElement) {
      final enumConstants =
          element.fields.where((f) => f.isEnumConstant).toList();
      if (enumConstants.isNotEmpty) {
        return '$typeStr.${enumConstants.first.name}';
      }
    }

    // Built-in primitives
    if (typeStr == 'String') return "''";
    if (typeStr == 'int') return '0';
    if (typeStr == 'double') return '0.0';
    if (typeStr == 'num') return '0';
    if (typeStr == 'bool') return 'false';
    if (typeStr == 'DateTime') return 'DateTime(2000, 1, 1)';

    // List<T>
    if (type is ParameterizedType &&
        typeStr.startsWith('List<') &&
        typeStr.endsWith('>') &&
        type.typeArguments.isNotEmpty) {
      // First, check if there's a direct override for List<Something>
      final listOverride = _typeDefaults[typeStr];
      if (listOverride != null) {
        return listOverride;
      }

      // Otherwise, generate based on inner type
      final innerFake = _fakeValueForType(type.typeArguments.first);
      return '[$innerFake]';
    }

    // Fallback: assume another @ModelFactory model
    return '${typeStr}Factory.build()';
  }

  /// Reads user configuration from build.yaml.
  ///
  /// Expected format:
  /// builders:
  ///   model_factory|model_factory:
  ///     options:
  ///       defaults:
  ///         String: "'my default'"
  ///         int: "42"
  ///         DateTime: "DateTime(2020, 1, 1)"
  static Map<String, String> _parseTypeDefaults(Map<String, dynamic>? config) {
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
