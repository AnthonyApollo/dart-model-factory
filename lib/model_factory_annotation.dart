library model_factory_annotation;

class ModelFactory {
  /// Optional per-class defaults, e.g.:
  /// @ModelFactory(defaults: { "name": "'John'", "age": "20" })
  final Map<String, String>? defaults;

  const ModelFactory({this.defaults});
}

/// Annotation for overriding default value of a specific field.
class FactoryDefault {
  /// Example:
  /// @FactoryDefault("'MyName'")
  /// @FactoryDefault("42")
  final String code;

  const FactoryDefault(this.code);
}
