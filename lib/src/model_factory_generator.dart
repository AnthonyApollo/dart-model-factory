import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:model_factory/model_factory_annotation.dart';

class ModelFactoryGenerator extends GeneratorForAnnotation<ModelFactory> {
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
        buffer.writeln('      ${f.name}: ${f.name},');
      } else {
        buffer.writeln('      ${f.name}: ${f.name} ?? ${f.fakeCode},');
      }
    }

    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }

  String _fakeValueForType(DartType type) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return 'null';
    }

    final typeStr = type.getDisplayString(withNullability: false);
    final element = type.element;

    if (element is EnumElement) {
      final enumConstants =
          element.fields.where((f) => f.isEnumConstant).toList();
      if (enumConstants.isNotEmpty) {
        return '$typeStr.${enumConstants.first.name}';
      }
    }

    if (typeStr == 'String') return "'abc'";
    if (typeStr == 'int') return '0';
    if (typeStr == 'double') return '0.0';
    if (typeStr == 'num') return '0';
    if (typeStr == 'bool') return 'false';
    if (typeStr == 'DateTime') return 'DateTime(2000, 1, 1)';

    if (type is ParameterizedType &&
        typeStr.startsWith('List<') &&
        typeStr.endsWith('>') &&
        type.typeArguments.isNotEmpty) {
      final innerFake = _fakeValueForType(type.typeArguments.first);
      return '[$innerFake]';
    }

    return '${typeStr}Factory.build()';
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
