# **model_factory**

A lightweight and powerful code generator that creates **factory classes** for your Dart/Flutter models.
The generated factories make it easy to create fake or partially-customized instances of your classes — ideal for **unit tests**, **widget tests**, and **mock data scenarios**.

# 📚 **Index**

* [🚀 What does this package do?](#-what-does-this-package-do)
* [⚙️ Why use model_factory?](#️-why-use-model_factory)
* [🧩 Usage](#-usage)
* [🧪 Perfect for Unit Tests](#-perfect-for-unit-tests)
* [🟣 Mock Data Scenarios](#-mock-data--skeleton-loading-eg-skeletonizer)
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
* A static `build()` method with optional parameters for each field in the model
* Default **fake values** for:

  * strings
  * numbers
  * booleans
  * enums (first case)
  * lists
  * nullable fields
  * nested models (must also be annotated with `@ModelFactory`)

### 🔗 Nested Models (auto-generated)

Factories cascade automatically through nested models:

```dart
OrderFactory.build()
// → Order(customer: CustomerFactory.build(), ...)
```

### 🎯 Nullable Fields (smart defaults)

* `T?` → defaults to **null**
* `T`  → defaults to a fake predefined value
* Override any field manually in `build()` as needed.

### 🏗️ Supported Fake Values

| Type         | Generated Fake Value |
| ------------ | -------------------- |
| `String`     | `'abc'`              |
| `int`        | `0`                  |
| `double`     | `0.0`                |
| `bool`       | `false`              |
| `enum`       | first case           |
| `List<T>`    | `[fakeValue]`        |
| `T?`         | `null`               |
| Custom model | `TFactory.build()`   |

## ⚙️ **Why use model_factory?**

* ✔ Eliminates boilerplate in tests and mock data scenarios
* ✔ Reduces maintenance when models change
* ✔ Automatically generates default values
* ✔ Makes tests more readable and expressive
* ✔ Zero runtime dependencies — everything is generated at build time
* ✔ No reflection, no dynamic magic, fully type-safe

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

This generates:

```dart
UserFactory.build();
// → User(id: 0, name: 'abc', email: null)
```

Or with overrides:

```dart
UserFactory.build(id: 123);
```

## 🧪 **Perfect for Unit Tests**

Instead of manually constructing dummy objects:

### Without model_factory ❌

```dart
final user = User(
  id: 1,
  name: 'John Doe',
  email: null,
);
```

### With model_factory ✅

```dart
final user = UserFactory.build();
```

Or customize only what matters:

```dart
final user = UserFactory.build(name: "Alice");
```

This keeps tests clean, readable, and focused.

## 🟣 **Mock Data Scenarios**

This package is ideal for UI libraries that expect real model shapes for placeholder rendering:

* skeletonizer
* shimmer-based skeletons
* loading placeholders
* preview UIs
* prototyping flows

Example:

```dart
Skeletonizer(
  child: UserCard(
    user: UserFactory.build(),
  ),
);
```

## 🧭 **Roadmap (future features)**

Potential enhancements:

* Custom default values

## ❤️ **Contributions**

Feedback, suggestions, and pull requests are welcome!
Feel free to open an issue.

## 📄 **License**

MIT License
Use freely for commercial or personal projects.
