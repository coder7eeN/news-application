# Code Style Reference

Enforced via `analysis_options.yaml`. Run `flutter analyze --fatal-infos` before every commit.

---

## Naming Conventions

- `camelCase` for variables and functions
- `PascalCase` for classes, enums, and typedefs
- `snake_case` for file names
- Private fields and methods prefixed with `_`

---

## Import Rules

**Order**: `dart:` -> `package:flutter/` -> third-party -> project

**Always use package imports** for project files (not relative imports).
Use single quotes for all strings (enforced by `prefer_single_quotes`).

```dart
// Correct
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:news_app/core/error/failures.dart';

// Wrong
import '../core/error/failures.dart';  // Never use relative imports
import "package:dio/dio.dart";  // Never use double quotes
```

---

## Type Safety (Strict Mode Enabled)

- **No `dynamic` types** — always declare explicit types
- **Always declare return types** on functions and methods
- **Strict inference** and **strict casts** enabled in analyzer
- Use `var` only when type is obvious from right-hand side

```dart
// Correct
Future<Either<Failure, List<Article>>> getArticles() async { ... }
final List<String> names = ['Alice', 'Bob'];
final count = 5;  // OK - type is obvious

// Wrong
getArticles() async { ... }  // Missing return type
var names = getData();  // Type not obvious
List names = ['Alice'];  // Missing type argument
```

---

## Const and Final

- **Prefer const** constructors wherever possible
- **Prefer const** for collections and literals
- **Prefer final** for local variables that won't change
- **Prefer final** for fields that won't be reassigned

```dart
// Correct
const String apiKey = 'key';
final List<Article> articles = [];
const EdgeInsets.all(16.0);
const ['apple', 'banana'];

// Wrong
String apiKey = 'key';  // Should be const
var articles = <Article>[];  // Should be final List<Article>
EdgeInsets.all(16.0);  // Should be const
```

---

## Error Handling

- **No silent catches** — always use `on` clause to catch specific exceptions
- Always log errors or map to `Failure` and propagate
- Never catch without handling — avoid empty catch blocks

```dart
// Correct
try {
  await api.fetch();
} on DioException catch (e) {
  return Left(ServerFailure(e.message));
} on SocketException catch (e) {
  return Left(const NoInternetFailure());
}

// Wrong
try {
  await api.fetch();
} catch (e) {  // Missing 'on' clause
  // empty - silent failure
}
```

---

## Performance Best Practices

- **Avoid function literals in forEach** — use `for-in` loops instead
- **Prefer collection literals** over constructors (`[]` not `List()`)
- **Prefer spread collections** over `.addAll()`
- **Use `const` constructors in immutables**

```dart
// Correct
for (final item in items) {
  print(item);
}
final list = [...oldList, newItem];
const SizedBox(height: 16);

// Wrong
items.forEach((item) => print(item));
final list = List.from(oldList)..add(newItem);
SizedBox(height: 16);  // Should be const
```

---

## Flutter-Specific Rules

- **Avoid unnecessary containers** — use SizedBox, Padding, or Center directly
- **Use SizedBox for whitespace** instead of Container with fixed size
- **Use DecoratedBox** instead of Container when only decoration is needed
- **Use ColoredBox** instead of Container when only color is needed
- **Use super parameters** in constructors (e.g., `super.key` not `key: key`)

```dart
// Correct
const SizedBox(height: 16);
const ColoredBox(color: Colors.red, child: Text('Hi'));
const MyWidget({super.key, required this.title});

// Wrong
Container(height: 16);  // Use SizedBox
Container(color: Colors.red, child: Text('Hi'));  // Use ColoredBox
const MyWidget({Key? key, required this.title}) : super(key: key);  // Use super.key
```

---

## File Size and Structure

- Max ~200 lines per file — split into smaller files if exceeded
- Extract widgets into separate files when they become complex
- Keep presentation/bloc/pages/widgets organized by feature
