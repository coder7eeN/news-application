# Flutter News App — CLAUDE.md

## Project Overview

A production-ready Flutter news application built on **Clean Architecture + MVVM**.
Fetches articles from [NewsAPI](https://newsapi.org/) with offline support, bookmarking, and search.

**3-day deadline project. Every decision prioritizes clarity, testability, and speed.**

- **IDE:** Android Studio (Hedgehog or later) with Flutter + Dart plugins
- **Flutter channel:** stable
- **Min SDK:** Android 21 / iOS 13

---

## Common Commands

Run these from the **Android Studio Terminal** tab (View > Tool Windows > Terminal).

```bash
# Install dependencies
flutter pub get

# Run app on connected device/emulator — always pass API key
flutter run --dart-define=NEWS_API_KEY=your_key_here

# Run with a specific device (get IDs via: flutter devices)
flutter run -d emulator-5554 --dart-define=NEWS_API_KEY=your_key_here

# Run all unit tests with coverage
flutter test test/features/ --coverage

# Run tests for a single feature
flutter test test/features/news_feed/ --coverage

# Static analysis — must pass zero warnings before every commit
flutter analyze --fatal-infos

# Build release APK
flutter build apk \
  --dart-define=NEWS_API_KEY=$NEWS_API_KEY \
  --obfuscate \
  --split-debug-info=build/debug-info

# Regenerate Hive adapters after any model change
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android Studio Run Configuration (one-time setup)
In **Run > Edit Configurations**, add to "Additional run args":
```
--dart-define=NEWS_API_KEY=your_key_here
```
This avoids typing the key manually on every run.

---

## Project Structure

```
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart           # Failure sealed class hierarchy
│   │   └── exceptions.dart         # AppException types
│   ├── network/
│   │   ├── dio_client.dart         # Dio singleton with interceptors
│   │   ├── auth_interceptor.dart   # Injects NEWS_API_KEY into every request
│   │   ├── error_interceptor.dart  # Maps DioException → AppException
│   │   └── network_info.dart       # NetworkInfo abstract + ConnectivityImpl
│   ├── cache/
│   │   ├── hive_helper.dart        # openBox, clearBox, TTL check helpers
│   │   └── cache_constants.dart    # Box names, TTL duration, max pages
│   └── di/
│       └── injection_container.dart
│
├── features/
│   ├── news_feed/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── news_feed_remote_datasource.dart
│   │   │   │   └── news_feed_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── article_model.dart      # JSON ↔ Entity + Hive adapter
│   │   │   └── repositories/
│   │   │       └── news_feed_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── article.dart            # Pure Dart, zero external imports
│   │   │   ├── repositories/
│   │   │   │   └── i_news_feed_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_latest_articles_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── news_feed_bloc.dart
│   │       │   ├── news_feed_event.dart
│   │       │   └── news_feed_state.dart
│   │       └── pages/
│   │           ├── news_feed_page.dart
│   │           └── widgets/
│   │               ├── article_card.dart
│   │               ├── feed_error_view.dart
│   │               └── feed_loading_view.dart
│   │
│   ├── search/                         # Mirrors news_feed structure
│   │   └── presentation/bloc/
│   │       ├── search_bloc.dart        # Uses restartable() transformer
│   │       ├── search_event.dart
│   │       └── search_state.dart
│   │
│   ├── article_detail/
│   │   └── presentation/
│   │       ├── notifier/
│   │       │   └── article_detail_notifier.dart   # ValueNotifier
│   │       └── pages/
│   │           └── article_detail_page.dart
│   │
│   └── bookmark/
│       └── presentation/
│           ├── notifier/
│           │   └── bookmark_notifier.dart   # ChangeNotifier
│           └── pages/
│               └── bookmark_page.dart
│
test/
└── features/
    ├── news_feed/
    │   ├── bloc/news_feed_bloc_test.dart
    │   └── usecases/get_latest_articles_usecase_test.dart
    ├── search/
    │   └── bloc/search_bloc_test.dart
    └── bookmark/
        └── notifier/bookmark_notifier_test.dart

└── main.dart
```

---

## Architecture Rules

### The Dependency Rule — NEVER violate

```
presentation → domain ← data
```

- `domain` imports **nothing** from `data`, `presentation`, or any Flutter/third-party package
- `data` implements interfaces defined in `domain`
- `presentation` calls use cases from `domain` only
- **Cross-feature imports are forbidden** — wire everything through GetIt

### Layer Contracts with Code Examples

**Entity** — pure Dart value object, no serialization:
```dart
// domain/entities/article.dart
class Article extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final String sourceName;
  final DateTime publishedAt;

  const Article({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
  });

  @override
  List<Object?> get props => [id, title, url, publishedAt];
}
```

**Model** — handles JSON and Hive serialization, extends Entity:
```dart
// data/models/article_model.dart
@HiveType(typeId: 0)
class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.title,
    super.description,
    required super.url,
    super.imageUrl,
    required super.sourceName,
    required super.publishedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
    id: json['url'] as String,   // NewsAPI has no unique id — use url
    title: json['title'] as String,
    description: json['description'] as String?,
    url: json['url'] as String,
    imageUrl: json['urlToImage'] as String?,
    sourceName: (json['source'] as Map)['name'] as String,
    publishedAt: DateTime.parse(json['publishedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'url': id,
    'title': title,
    'description': description,
    'urlToImage': imageUrl,
    'source': {'name': sourceName},
    'publishedAt': publishedAt.toIso8601String(),
  };
}
```

**Repository Interface** in domain:
```dart
// domain/repositories/i_news_feed_repository.dart
abstract class INewsFeedRepository {
  Future<Either<Failure, List<Article>>> getLatestArticles(int page);
  Future<Either<Failure, List<Article>>> searchArticles(String query);
}
```

**Use Case** — single responsibility, single `call()` method:
```dart
// domain/usecases/get_latest_articles_usecase.dart
class GetLatestArticlesUseCase {
  final INewsFeedRepository repository;
  const GetLatestArticlesUseCase(this.repository);

  Future<Either<Failure, List<Article>>> call(int page) =>
      repository.getLatestArticles(page);
}
```

---

## State Management Rules

| Feature | Tool | Reason |
|---|---|---|
| News Feed | `BLoC` | Pagination events, async streams, complex state transitions |
| Search | `BLoC` + `EventTransformer` | Debounced input stream, cancel outdated requests |
| Article Detail | `ValueNotifier` | Simple 3-state UI: loading / loaded / error |
| Bookmarks | `ChangeNotifier` | Local reactive state, no async complexity |

**Do NOT use BLoC for Article Detail or Bookmarks** — boilerplate overhead is not justified.

### BLoC Events and States

```dart
// news_feed_event.dart
abstract class NewsFeedEvent extends Equatable {}
class FetchLatestArticles extends NewsFeedEvent {
  @override List<Object> get props => [];
}
class FetchNextPage extends NewsFeedEvent {
  @override List<Object> get props => [];
}
class RefreshFeed extends NewsFeedEvent {
  @override List<Object> get props => [];
}
```

```dart
// news_feed_state.dart
abstract class NewsFeedState extends Equatable {}
class NewsFeedInitial extends NewsFeedState {
  @override List<Object> get props => [];
}
class NewsFeedLoading extends NewsFeedState {
  @override List<Object> get props => [];
}
class NewsFeedLoaded extends NewsFeedState {
  final List<Article> articles;
  final bool hasReachedMax;
  const NewsFeedLoaded({required this.articles, this.hasReachedMax = false});
  @override List<Object> get props => [articles, hasReachedMax];
}
class NewsFeedError extends NewsFeedState {
  final String message;
  const NewsFeedError(this.message);
  @override List<Object> get props => [message];
}
```

### BLoC Concurrency — Required Transformers

```dart
// news_feed_bloc.dart
class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  final GetLatestArticlesUseCase getLatestArticles;
  int _currentPage = 1;

  NewsFeedBloc({required this.getLatestArticles}) : super(NewsFeedInitial()) {
    on<FetchNextPage>(_onFetchNextPage, transformer: droppable());
    on<RefreshFeed>(_onRefresh, transformer: droppable());
  }

  Future<void> _onFetchNextPage(
    FetchNextPage event,
    Emitter<NewsFeedState> emit,
  ) async {
    if (state is NewsFeedLoaded && (state as NewsFeedLoaded).hasReachedMax) return;
    emit(NewsFeedLoading());
    final result = await getLatestArticles(_currentPage);
    result.fold(
      (failure) => emit(NewsFeedError(failure.message)),
      (articles) {
        _currentPage++;
        final existing = state is NewsFeedLoaded
            ? (state as NewsFeedLoaded).articles
            : <Article>[];
        emit(NewsFeedLoaded(
          articles: [...existing, ...articles],
          hasReachedMax: articles.length < 20,
        ));
      },
    );
  }
}
```

```dart
// search_bloc.dart — restartable() cancels previous search on new keystroke
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchArticlesUseCase searchArticles;

  SearchBloc({required this.searchArticles}) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) { emit(SearchInitial()); return; }
    await Future.delayed(const Duration(milliseconds: 400)); // debounce
    emit(SearchLoading());
    final result = await searchArticles(event.query);
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (articles) => emit(
        articles.isEmpty ? SearchEmpty() : SearchLoaded(articles: articles),
      ),
    );
  }
}
```

---

## Caching Rules

All constants live in `core/cache/cache_constants.dart` — never hardcode inline:

```dart
// core/cache/cache_constants.dart
class CacheConstants {
  static const String feedBoxName      = 'articles_cache';
  static const String bookmarksBoxName = 'bookmarks';
  static const Duration feedTtl        = Duration(minutes: 15);
  static const int maxCachedPages      = 5;

  static String feedCacheKey(int page) => 'feed_page_$page';
}
```

### Cache-First Repository Implementation

```dart
// data/repositories/news_feed_repository_impl.dart
@override
Future<Either<Failure, List<Article>>> getLatestArticles(int page) async {
  // 1. Serve from cache immediately if valid
  final cached = await localDataSource.getCachedArticles(page);
  if (cached != null && !cached.isExpired) {
    unawaited(_refreshInBackground(page)); // refresh in background silently
    return Right(cached.articles.map((m) => m.toEntity()).toList());
  }

  // 2. Cache miss — check connectivity before hitting API
  if (!await networkInfo.isConnected) {
    return cached != null
        ? Right(cached.articles.map((m) => m.toEntity()).toList()) // stale ok
        : Left(const NoInternetFailure());
  }

  // 3. Fetch fresh data
  try {
    final models = await remoteDataSource.fetchArticles(page);
    await localDataSource.cacheArticles(page, models);
    return Right(models.map((m) => m.toEntity()).toList());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on TimeoutException {
    return Left(const TimeoutFailure());
  }
}
```

| Config | Value |
|---|---|
| Feed box | `"articles_cache"` |
| Bookmarks box | `"bookmarks"` |
| Cache key | `"feed_page_{page}"` |
| TTL | 15 minutes |
| Max pages cached | 5 (100 articles) |
| Search results | ❌ Never cached |
| Bookmarks TTL | ∞ — user-controlled only |

Pull-to-refresh → force-fetch, reset TTL, ignore existing cache.

---

## Networking Rules

**Dio only** — never use `http` package or `dart:io` HttpClient directly.

```dart
// core/network/dio_client.dart
class DioClient {
  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://newsapi.org/v2',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      if (kDebugMode) LogInterceptor(responseBody: true),
    ]);
    return dio;
  }
}
```

```dart
// core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  static const _apiKey = String.fromEnvironment('NEWS_API_KEY');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters['apiKey'] = _apiKey;
    handler.next(options);
  }
}
```

Always use `CancelToken` in Search DataSource:
```dart
CancelToken? _cancelToken;

Future<List<ArticleModel>> searchArticles(String query) async {
  _cancelToken?.cancel('superseded by new query');
  _cancelToken = CancelToken();
  final response = await dio.get(
    '/everything',
    queryParameters: {'q': query, 'pageSize': 20},
    cancelToken: _cancelToken,
  );
  return (response.data['articles'] as List)
      .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

---

## Error Handling Rules

All repository methods return `Either<Failure, T>`. Both paths must always be handled by callers.

```dart
// core/error/failures.dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override List<Object> get props => [message];
}

class ServerFailure    extends Failure { const ServerFailure([super.message = 'Server error. Please try again.']); }
class NoInternetFailure extends Failure { const NoInternetFailure([super.message = 'No internet connection.']); }
class TimeoutFailure   extends Failure { const TimeoutFailure([super.message = 'Request timed out.']); }
class CacheFailure     extends Failure { const CacheFailure([super.message = 'Could not load cached data.']); }
```

| Scenario | Failure Type | UI Behavior |
|---|---|---|
| No internet | `NoInternetFailure` | Show cached feed or offline banner |
| Server 5xx | `ServerFailure` | Error message + Retry button |
| Timeout | `TimeoutFailure` | Retry with exponential backoff |
| Empty results | `Right([])` | Empty state illustration |
| Invalid API key | `ServerFailure` (generic) | Log internally — never show key in UI |

---

## Security Rules

**NEVER use `flutter_dotenv`** — `.env` files are bundled as assets and extractable from APK via `apktool`.

```bash
# ✅ Correct — key compiled into binary, not extractable
flutter run --dart-define=NEWS_API_KEY=abc123

# ❌ Wrong — key lives in assets/, extractable from APK
# (using flutter_dotenv + .env file)
```

Access key in code:
```dart
// Evaluated at compile time — not at runtime
const apiKey = String.fromEnvironment('NEWS_API_KEY');
```

Security checklist before every release:
- [ ] `NEWS_API_KEY` stored in GitHub Secrets only — never hardcoded
- [ ] `--obfuscate` flag present in build command
- [ ] `--split-debug-info=build/debug-info` present
- [ ] No API key in any committed file
- [ ] `.gitignore` covers any local env files

---

## Testing Rules

**Scope:** BLoC + UseCase unit tests only. Widget/integration tests only if Day 3 is ahead of schedule.

**Rule:** Write tests **same day** as the feature — never deferred.

### Test File Example

```dart
// test/features/news_feed/bloc/news_feed_bloc_test.dart
void main() {
  late NewsFeedBloc bloc;
  late MockGetLatestArticlesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetLatestArticlesUseCase();
    bloc = NewsFeedBloc(getLatestArticles: mockUseCase);
  });

  tearDown(() => bloc.close());

  group('FetchNextPage', () {
    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Loaded] when fetch succeeds',
      build: () {
        when(() => mockUseCase(1)).thenAnswer((_) async => Right(tArticles));
        return bloc;
      },
      act: (b) => b.add(FetchNextPage()),
      expect: () => [NewsFeedLoading(), NewsFeedLoaded(articles: tArticles)],
      verify: (_) => verify(() => mockUseCase(1)).called(1),
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Error] when fetch fails',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => Left(const ServerFailure()));
        return bloc;
      },
      act: (b) => b.add(FetchNextPage()),
      expect: () => [NewsFeedLoading(), isA<NewsFeedError>()],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'appends articles on page 2',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tArticles));
        return NewsFeedBloc(getLatestArticles: mockUseCase)
          ..emit(NewsFeedLoaded(articles: tArticles));
      },
      act: (b) => b.add(FetchNextPage()),
      expect: () => [
        NewsFeedLoading(),
        NewsFeedLoaded(articles: [...tArticles, ...tArticles]),
      ],
    );
  });
}
```

### Mocking Pattern (mocktail — never mockito)
```dart
class MockGetLatestArticlesUseCase extends Mock
    implements GetLatestArticlesUseCase {}

setUpAll(() {
  registerFallbackValue(Left<Failure, List<Article>>(const ServerFailure()));
});
```

### Test Priority by Day

| Day | Test Target |
|---|---|
| Day 1 | `NewsFeedBloc` (loading, error, pagination) + `GetLatestArticlesUseCase` (offline) |
| Day 2 | `SearchBloc` (debounce, cancel) + `BookmarkNotifier` (add/remove toggle) |
| Day 3 | Edge cases, TTL expiry, empty state scenarios |

---

## Dependency Injection (GetIt)

```dart
// core/di/injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs — factory (new instance per widget tree injection)
  sl.registerFactory(() => NewsFeedBloc(getLatestArticles: sl()));
  sl.registerFactory(() => SearchBloc(searchArticles: sl()));
  sl.registerFactory(() => BookmarkNotifier(localDataSource: sl()));

  // Use Cases — lazy singleton
  sl.registerLazySingleton(() => GetLatestArticlesUseCase(sl()));
  sl.registerLazySingleton(() => SearchArticlesUseCase(sl()));

  // Repositories — lazy singleton, registered as interface
  sl.registerLazySingleton<INewsFeedRepository>(
    () => NewsFeedRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources — lazy singleton
  sl.registerLazySingleton<NewsFeedRemoteDataSource>(
    () => NewsFeedRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<NewsFeedLocalDataSource>(
    () => NewsFeedLocalDataSourceImpl(
      box: Hive.box(CacheConstants.feedBoxName),
    ),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton(() => DioClient.create());
  sl.registerLazySingleton(() => Connectivity());
}
```

---

## CI/CD

Two GitHub Actions workflows — configured **Day 1** before any feature code is written.

`ci.yml` triggers on Pull Request, `build.yml` triggers on push to `main`.
All PRs must pass CI before merge. Enable Copilot Auto Review in repo settings (no YAML needed).

GitHub Secret required: `NEWS_API_KEY` → Settings → Secrets and variables → Actions.

---

## Code Style

The project enforces strict linting rules via `analysis_options.yaml`. Always run `flutter analyze --fatal-infos` before commits.

### Naming Conventions
- `camelCase` for variables and functions
- `PascalCase` for classes, enums, and typedefs
- `snake_case` for file names
- Private fields and methods prefixed with `_`

### Import Rules
- **Order**: `dart:` → `package:flutter/` → third-party → project
- **Always use package imports** for project files (not relative imports)
- Use single quotes for all strings (enforced by `prefer_single_quotes`)

**Example:**
```dart
// ✅ Correct
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:news_app/core/error/failures.dart';

// ❌ Wrong
import '../core/error/failures.dart';  // Never use relative imports
import "package:dio/dio.dart";  // Never use double quotes
```

### Type Safety (Strict Mode Enabled)
- **No `dynamic` types** — always declare explicit types
- **Always declare return types** on functions and methods
- **Strict inference** and **strict casts** enabled in analyzer
- Use `var` only when type is obvious from right-hand side

**Example:**
```dart
// ✅ Correct
Future<Either<Failure, List<Article>>> getArticles() async { ... }
final List<String> names = ['Alice', 'Bob'];
final count = 5;  // OK - type is obvious

// ❌ Wrong
getArticles() async { ... }  // Missing return type
var names = getData();  // Type not obvious
List names = ['Alice'];  // Missing type argument
```

### Const and Final
- **Prefer const** constructors wherever possible
- **Prefer const** for collections and literals
- **Prefer final** for local variables that won't change
- **Prefer final** for fields that won't be reassigned

**Example:**
```dart
// ✅ Correct
const String apiKey = 'key';
final List<Article> articles = [];
const EdgeInsets.all(16.0);
const ['apple', 'banana'];

// ❌ Wrong
String apiKey = 'key';  // Should be const
var articles = <Article>[];  // Should be final List<Article>
EdgeInsets.all(16.0);  // Should be const
```

### Error Handling
- **No silent catches** — always use `on` clause to catch specific exceptions
- Always log errors or map to `Failure` and propagate
- Never catch without handling — avoid empty catch blocks

**Example:**
```dart
// ✅ Correct
try {
  await api.fetch();
} on DioException catch (e) {
  return Left(ServerFailure(e.message));
} on SocketException catch (e) {
  return Left(const NoInternetFailure());
}

// ❌ Wrong
try {
  await api.fetch();
} catch (e) {  // Missing 'on' clause
  // empty - silent failure
}
```

### Performance Best Practices
- **Avoid function literals in forEach** — use `for-in` loops instead
- **Prefer collection literals** over constructors (`[]` not `List()`)
- **Prefer spread collections** over `.addAll()`
- **Use `const` constructors in immutables**

**Example:**
```dart
// ✅ Correct
for (final item in items) {
  print(item);
}
final list = [...oldList, newItem];
const SizedBox(height: 16);

// ❌ Wrong
items.forEach((item) => print(item));
final list = List.from(oldList)..add(newItem);
SizedBox(height: 16);  // Should be const
```

### Flutter-Specific Rules
- **Avoid unnecessary containers** — use SizedBox, Padding, or Center directly
- **Use SizedBox for whitespace** instead of Container with fixed size
- **Use DecoratedBox** instead of Container when only decoration is needed
- **Use ColoredBox** instead of Container when only color is needed
- **Use super parameters** in constructors (e.g., `super.key` not `key: key`)

**Example:**
```dart
// ✅ Correct
const SizedBox(height: 16);
const ColoredBox(color: Colors.red, child: Text('Hi'));
const MyWidget({super.key, required this.title});

// ❌ Wrong
Container(height: 16);  // Use SizedBox
Container(color: Colors.red, child: Text('Hi'));  // Use ColoredBox
const MyWidget({Key? key, required this.title}) : super(key: key);  // Use super.key
```

### File Size and Structure
- Max ~200 lines per file — split into smaller files if exceeded
- Extract widgets into separate files when they become complex
- Keep presentation/bloc/pages/widgets organized by feature

---

## Key Packages

### dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | BLoC state management |
| `bloc_concurrency` | `droppable()` / `restartable()` event transformers |
| `provider` | ChangeNotifier / ValueNotifier widget wiring |
| `dio` | HTTP client with interceptors and CancelToken |
| `hive_ce` + `hive_ce_flutter` | Local NoSQL storage (cache + bookmarks) — community-maintained fork of Hive, actively updated |
| `get_it` | Service locator / dependency injection |
| `equatable` | Value equality for BLoC states and events |
| `dartz` | `Either<Failure, T>` functional error handling |
| `webview_flutter` | Render full articles |
| `connectivity_plus` | Online/offline detection |

### dev_dependencies

| Package | Purpose |
|---|---|
| `hive_ce_generator` | Code generation for `@HiveType` / `@HiveField` annotations — required by `hive_ce` |
| `build_runner` | Runs code generation — required to generate `.g.dart` adapter files |
| `bloc_test` | BLoC unit test helpers |
| `mocktail` | Mocking (never use mockito) |

> ⚠️ `hive_ce_generator` and `build_runner` must be in `dev_dependencies`, not `dependencies`.
> After any change to a `@HiveType` model, always run:
> `flutter pub run build_runner build --delete-conflicting-outputs`

---

## What Claude Should NOT Do

### Architecture Violations
- **Do not use `flutter_dotenv`** — `.env` files are extractable from APK
- **Do not use `hive` or `hive_flutter`** — use `hive_ce` and `hive_ce_flutter` (original packages are unmaintained)
- **Do not put `hive_ce_generator` or `build_runner` in `dependencies`** — they belong in `dev_dependencies` only
- **Do not let BLoC call DataSources directly** — always UseCase → Repository → DataSource
- **Do not cache search results** — too dynamic, wastes Hive storage
- **Do not import `data` or `presentation` from `domain`** — hard Dependency Rule
- **Do not use the `http` package** — Dio only
- **Do not use `mockito`** — use `mocktail`
- **Do not write widget or integration tests** unless explicitly ahead of schedule on Day 3
- **Do not expose raw exceptions or API keys in UI messages** — always map to generic Failure
- **Do not create a BLoC for Article Detail or Bookmarks** — use ValueNotifier / ChangeNotifier
- **Do not hardcode box names, TTL values, or cache keys inline** — use `CacheConstants`

### Code Style Violations (Will Fail Linting)
- **Do not use relative imports** — always use package imports (`package:news_app/...`)
- **Do not use double quotes** for strings — always use single quotes
- **Do not omit return types** — every function/method must declare its return type
- **Do not use `dynamic`** — always use explicit types
- **Do not use `var` when type is not obvious** — declare explicit types
- **Do not skip `const`** — use `const` for constructors, literals, and collections when possible
- **Do not skip `final`** — use `final` for local variables and fields that won't be reassigned
- **Do not catch without `on` clause** — always specify exception type
- **Do not use `Container()` for whitespace** — use `SizedBox`
- **Do not use `Container()` for color only** — use `ColoredBox`
- **Do not use `Container()` for decoration only** — use `DecoratedBox`
- **Do not use old constructor syntax** — use super parameters (`super.key` not `key: key`)
- **Do not use `forEach` with function literals** — use `for-in` loops instead
- **Do not use `List()` constructor** — use `[]` literal
- **Do not use `.addAll()`** — use spread operator `[...list, item]`

---

## After Every Task — Local Review Checklist

Before committing, always run:

```bash
# 1. Static analysis — must be zero warnings and zero infos
flutter analyze --fatal-infos

# 2. Feature tests — all must be green
flutter test test/features/[feature]/ --coverage
```

**Manual checks (cannot be automated):**

3. **Domain import check** — open every file just created or modified in `domain/`:
   - Must NOT contain any import from `data/`, `presentation/`, `dio`, `hive_ce`, or any Flutter package
   - Allowed imports: `dart:core`, `equatable`, `dartz`, other `domain/` files

4. **Either fold check** — search all new code for `.fold(` calls:
   - Every `fold()` must handle BOTH `(failure) =>` and `(data) =>` paths
   - Silent left-side ignoring `(_) {}` is not acceptable

**Checklist before every `git commit`:**
- [ ] `flutter analyze --fatal-infos` exits with code 0
- [ ] `flutter test test/features/[feature]/` — all tests green
- [ ] No domain file imports `data/`, `presentation/`, or infrastructure packages
- [ ] Every `.fold()` call handles both failure and success paths
