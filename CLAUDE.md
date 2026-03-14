# Flutter News App — CLAUDE.md

## Project Overview

A production-ready Flutter news application built on **Clean Architecture + MVVM**.
Fetches articles from [NewsAPI](https://newsapi.org/) with offline support, bookmarking, and search.

- **Flutter channel:** stable | **Min SDK:** Android 21 / iOS 13
- **3-day deadline. Every decision prioritizes clarity, testability, and speed.**

---

## Quick Commands

```bash
flutter pub get                                          # Install deps
flutter run --dart-define=NEWS_API_KEY=your_key_here     # Run app
flutter test test/features/ --coverage                   # Run all tests
flutter test test/features/news_feed/ --coverage         # Single feature
flutter analyze --fatal-infos                            # Lint (must pass)
flutter pub run build_runner build --delete-conflicting-outputs  # Regen Hive
```

---

## Project Structure

```
lib/
├── core/
│   ├── error/        # failures.dart, exceptions.dart
│   ├── network/      # dio_client, auth_interceptor, error_interceptor, network_info
│   ├── cache/        # hive_helper, cache_constants
│   └── di/           # injection_container.dart
├── features/
│   ├── news_feed/    # data/ domain/ presentation/
│   ├── search/       # presentation/bloc/
│   ├── article_detail/  # presentation/notifier/ pages/
│   └── bookmark/     # presentation/notifier/ pages/
test/features/        # Mirrors lib/features/ structure
```

---

## Architecture — The Dependency Rule

```
presentation → domain ← data
```

- **domain** imports NOTHING from data/, presentation/, or any Flutter/third-party package
- **data** implements interfaces defined in domain
- **presentation** calls use cases from domain only
- **Cross-feature imports are forbidden** — wire through GetIt

### Layer Contracts

- **Entity** — pure Dart value object, extends Equatable, no serialization
- **Model** — extends Entity, handles JSON + Hive serialization (@HiveType)
- **Repository Interface** — abstract class in domain, returns `Either<Failure, T>`
- **Use Case** — single `call()` method, delegates to repository
- **BLoC** — events + states extend Equatable, use concurrency transformers
- **Notifier** — ValueNotifier or ChangeNotifier for simple state

> Full code templates: [docs/architecture_reference.md](docs/architecture_reference.md)

---

## State Management

| Feature | Tool | Reason |
|---|---|---|
| News Feed | `BLoC` | Pagination, async streams, complex state |
| Search | `BLoC` + `restartable()` | Debounced input, cancel outdated requests |
| Article Detail | `ValueNotifier` | Simple 3-state UI |
| Bookmarks | `ChangeNotifier` | Local reactive state |

**Do NOT use BLoC for Article Detail or Bookmarks.**

---

## Code Rules (One-Liners)

- Package imports only (`package:news_app/...`) — never relative
- Single quotes, explicit return types, no `dynamic`
- `const` constructors, `final` locals, `super.key`
- `SizedBox` not `Container` for spacing
- `for-in` not `forEach`, spread not `.addAll()`
- `on` clause on every catch — never bare `catch(e)`
- All repo methods return `Either<Failure, T>`, both paths handled in `.fold()`
- Max ~200 lines per file

> Full style guide: [docs/code_style_reference.md](docs/code_style_reference.md)

---

## Caching & Networking

- **Dio only** — never `http` package
- Cache constants in `CacheConstants` — never hardcode inline
- Cache-first with 15min TTL, max 5 pages cached
- Search results never cached
- `CancelToken` required for search datasource
- **Never use `flutter_dotenv`** — use `--dart-define` for API key

> Full reference: [docs/caching_and_networking.md](docs/caching_and_networking.md)

---

## Key Packages

| Package | Purpose |
|---|---|
| `flutter_bloc` + `bloc_concurrency` | BLoC + event transformers |
| `provider` | ChangeNotifier/ValueNotifier wiring |
| `dio` | HTTP client |
| `hive_ce` + `hive_ce_flutter` | Local storage (NOT `hive`/`hive_flutter`) |
| `get_it` | DI container |
| `equatable` | Value equality |
| `dartz` | `Either<Failure, T>` |
| `connectivity_plus` | Online/offline detection |
| `mocktail` | Testing mocks (NOT `mockito`) |
| `bloc_test` | BLoC test helpers |

> `hive_ce_generator` + `build_runner` in **dev_dependencies** only.

---

## Prohibited Patterns

- `flutter_dotenv`, `hive`/`hive_flutter`, `http` package, `mockito`
- BLoC calling DataSources directly (must go through UseCase -> Repository)
- Caching search results
- Domain importing data/presentation/infrastructure packages
- `hive_ce_generator`/`build_runner` in dependencies (dev_dependencies only)
- Exposing raw exceptions or API keys in UI

---

## Pre-Commit Checklist

```bash
flutter analyze --fatal-infos          # Must exit 0
flutter test test/features/ --coverage # All green
```

- [ ] No domain file imports data/, presentation/, or infra packages
- [ ] Every `.fold()` handles both failure and success paths

---

## Workflow Commands

| Command | Agent | What it does |
|---|---|---|
| `/plan` | Architecture Planner | Scan codebase, produce layer-ordered task list |
| `/implement` | Flutter Implementer | Generate production code for a task |
| `/review` | Code Reviewer | Run 4-point quality checklist (read-only) |
| `/fix` | Code Fixer | Fix all lint, test, and architecture issues |
| `/ship` | Release Manager | Quality gate, commit, push, create PR |
