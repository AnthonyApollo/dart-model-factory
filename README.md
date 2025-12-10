# **model_factory**

A lightweight and powerful code generator that creates **factory classes** for your Dart/Flutter models.
The generated factories make it easy to create fake or partially-customized instances of your classes — ideal for **unit tests**, **widget tests**, and **mock data scenarios**.

# 📚 **Index**

* [🚀 What does this package do?](#-what-does-this-package-do)
* [⚙️ Why use model_factory?](#️-why-use-model_factory)
* [🧩 Usage](#-usage)
* [🧪 Perfect for Unit Tests](#-perfect-for-unit-tests)
* [🟣 Mock Data Scenarios](#-mock-data-scenarios)
* [🧭 Roadmap](#-roadmap-future-features)
* [❤️ Contributions](#️-contributions)
* [📄 License](#-license)

## 🚀 **What does this package do?**

When you annotate a class with:

```dart
@ModelFactory()
```

The package (via `build_runner`) automatically generates:

* A `<ClassName>Factory` class
* A static `build()` method
* Optional parameters for every field
* Automatic fake values for:

  * strings
  * numbers
  * booleans
  * enums (first case)
  * lists
  * nullable fields
  * nested models (must also be annotated with `@ModelFactory`)

### 🔗 Nested Models (auto-generated)

```dart
OrderFactory.build()
// → Order(customer: CustomerFactory.build(), ...)
```

### 🎯 Nullable Fields (smart defaults)

* `T?` → defaults to **null**
* `T`  → defaults to fake predefined value
* All values can be overridden when calling `build()`

### 🏗️ Supported Fake Values

| Type         | Generated Fake Value |
| ------------ | -------------------- |
| `String`     | `''`                 |
| `int`        | `0`                  |
| `double`     | `0.0`                |
| `bool`       | `false`              |
| `enum`       | first enum case      |
| `List<T>`    | `[fakeValue]`        |
| `T?`         | `null`               |
| Custom model | `<T>Factory.build()` |

## ⚙️ **Why use model_factory?**

* ✔ Removes boilerplate from tests
* ✔ Keeps tests clean and expressive
* ✔ Automatically updates when your models change
* ✔ Works with nested models
* ✔ Fully type-safe — no runtime reflection
* ✔ Zero runtime cost (everything generated at build time)

## 🧩 **Usage**

### 1. Import the annotation

```dart
import 'package:model_factory/model_factory_annotation.dart';
```

### 2. Annotate your model

```dart
part 'user.factory.g.dart';

@ModelFactory()
class User {
  final int id;
  final String name;
  final String? email;

  const User({
    required this.id,
    required this.name,
    this.email,
  });
}
```

### 3. Run the generator

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated factory:

```dart
UserFactory.build();
// → User(id: 0, name: '', email: null)
```

Override only what you need:

```dart
UserFactory.build(id: 100);
```

### 🔧 **Configuring Custom Default Values**

Model Factory allows **three levels** of configuration.
The priority order is:

> **Field > Class > Global > Built-in defaults**

Meaning:

1. `@FactoryDefault` overrides everything
2. `@ModelFactory(defaults: {...})` overrides global defaults
3. `build.yaml` overrides built-in defaults
4. Built-in defaults are used only if nothing else is configured

#### **(1) Field-Level Defaults — `@FactoryDefault`**

This annotation lets you set a custom default **for one specific field**:

```dart
class User {
  @FactoryDefault("'Admin'")
  final String role;

  @FactoryDefault('21')
  final int age;

  final String name;

  const User({
    required this.role,
    required this.age,
    required this.name,
  });
}
```

Result:

```dart
UserFactory.build();
// role → 'Admin'
// age  → 21
// name → '' (or overridden by other configuration)
```

**Highest priority.**

#### **(2) Class-Level Defaults — `@ModelFactory(defaults: {...})`**

You can define per-field defaults at the class annotation:

```dart
@ModelFactory(
  defaults: {
    'id': '999',
    'name': "'John Doe'",
  },
)
class User { ... }
```

These override global defaults and built-in defaults, but are overridden by `@FactoryDefault`.

Example:

```dart
UserFactory.build();
// id   → 999
// name → 'John Doe'
// email → null
```

#### **(3) Global Defaults — via `build.yaml`**

Configure defaults **per type**, affecting your entire project.

```yaml
targets:
  $default:
    builders:
      model_factory|model_factory_generator:
        options:
          defaults:
            String: "'Lorem ipsum'"
            int: '42'
            double: '3.14'
            bool: 'true'
            DateTime: 'DateTime(2024, 1, 1)'
            UserRole: 'UserRole.admin'
            List<String>: "['A', 'B', 'C']"
```

Result:

```dart
UserFactory.build();
// name  → 'Lorem ipsum'
// id    → 42
// email → null
```

## 🧪 **Perfect for Unit Tests**

Instead of manually constructing dummy objects:

### Without model_factory ❌

```dart
final user = User(
  id: 1,
  name: 'John',
  email: null,
);
```

### With model_factory ✅

```dart
final user = UserFactory.build();
```

Or customize only what matters:

```dart
final user = UserFactory.build(name: 'Alice');
```

Clean, maintainable, expressive.

## 🟣 **Mock Data Scenarios**

`model_factory` is ideal for UI libraries that require *real model shapes*, such as:

* skeletonizer
* shimmer placeholders
* loading previews
* prototype UIs
* list placeholders

Example:

```dart
Skeletonizer(
  child: UserCard(
    user: UserFactory.build(),
  ),
);
```

## ❤️ **Contributions**

Feedback, suggestions, and pull requests are welcome!
Feel free to open an issue.

## 📄 **License**

MIT License
Use freely for commercial or personal projects.
