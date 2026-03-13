# Flutter News App — Technical Plan (3-Day Deadline)

## 1. Project Overview

This project aims to build a **production-ready Flutter news application** that is scalable, maintainable, and reliable within a **3-day development deadline**.

The application retrieves news articles from **NewsAPI** and provides users with a smooth reading experience including searching, bookmarking, and offline access.

**Key priorities:**
- Clean and scalable architecture following SOLID principles
- Efficient API usage with caching
- Smooth user experience
- Offline bookmark support
- Reliable error handling
- Core business logic testing
- Automated CI/CD pipeline

**API Provider:** https://newsapi.org/

---

## 2. Core Features

### 2.1 News Feed
Displays the latest articles retrieved from the API.

- Infinite scroll pagination (offset-based, page size: 20)
- Pull-to-refresh
- Loading / error / empty states
- Cache-first strategy (serve from cache while fetching fresh data in background)

### 2.2 Search Articles
Allows users to search for articles by keyword.

- Debounced input (400ms) via `EventTransformer` in BLoC
- Cancel outdated requests using Dio's `CancelToken`
- Loading / empty / error states
- Search results are **not cached** (too dynamic, would waste storage)

### 2.3 Article Details
Displays the selected article.

- Render article summary + open full article via `webview_flutter`
- Lightweight state: loading / loaded / error
- Share article functionality (optional)

### 2.4 Bookmarks
Users can save articles to read later.

- Add / remove bookmarks
- **Fully offline accessible** — stored in Hive
- Reactive UI: bookmark icon updates immediately without page reload

### 2.5 Error Handling
Gracefully handles common failures across all features.

| Scenario | Behavior |
|---|---|
| No Internet | Show cached data (Feed) or offline message |
| Server Error (5xx) | Friendly error message + Retry button |
| API Timeout | Retry option with exponential backoff |
| Empty Results | Empty state illustration + suggestion |
| API Key Invalid | Log error, show generic error (never expose key) |

---

## 3. Architecture

The project follows **Clean Architecture + MVVM**, divided into 3 main layers:

```
lib/
├── core/
│   ├── error/              # Failure classes, exceptions
│   ├── network/            # Dio client, interceptors, connectivity check
│   ├── cache/              # Hive helpers, cache constants (TTL, box names)
│   └── di/                 # GetIt service locator setup
│
├── features/
│   ├── news_feed/
│   │   ├── data/
│   │   │   ├── datasources/    # RemoteDataSource (Dio), LocalDataSource (Hive)
│   │   │   ├── models/         # ArticleModel (JSON ↔ Entity)
│   │   │   └── repositories/   # NewsFeedRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/       # Article (pure Dart, no Flutter deps)
│   │   │   ├── repositories/   # INewsFeedRepository (abstract)
│   │   │   └── usecases/       # GetLatestArticlesUseCase
│   │   └── presentation/
│   │       ├── bloc/           # NewsFeedBloc, NewsFeedEvent, NewsFeedState
│   │       └── pages/          # NewsFeedPage, widgets/
│   │
│   ├── search/             # Same structure as news_feed
│   │   └── presentation/
│   │       └── bloc/       # SearchBloc with debounce transformer
│   │
│   ├── article_detail/
│   │   └── presentation/
│   │       └── notifier/   # ArticleDetailNotifier (ValueNotifier)
│   │
│   └── bookmark/
│       └── presentation/
│           └── notifier/   # BookmarkNotifier (ChangeNotifier)
│
└── main.dart
```

**Dependency Rule:** Inner layers (domain) NEVER import outer layers (data/presentation).

---

## 4. MVVM + State Management Mapping

| Feature | State Management | Reason |
|---|---|---|
| News Feed | `BLoC` | Handles pagination events, async streams, complex state transitions |
| Search | `BLoC` + `EventTransformer` | Debounced input stream, cancel outdated requests |
| Article Detail | `ValueNotifier` | Simple 3-state UI: loading / loaded / error |
| Bookmarks | `ChangeNotifier` | Local reactive state, no async complexity |

**Why Hybrid?**
BLoC adds boilerplate overhead that isn't justified for simple UI states. Using `ValueNotifier`/`ChangeNotifier` for Article Detail and Bookmarks demonstrates the ability to **choose the right tool**, not just apply one pattern everywhere.

---

## 5. BLoC Concurrency Strategy

Each BLoC event is configured with an explicit `EventTransformer` to control concurrent event handling. Transformers are provided by the `bloc_concurrency` package.

```dart
// Feed: ignore duplicate fetch while one is in progress
on<FetchNextPage>(
  _fetchNext,
  transformer: droppable(),
);

// Refresh: same — prevent simultaneous refresh calls
on<RefreshFeed>(
  _onRefresh,
  transformer: droppable(),
);

// Search: cancel previous event when new keystroke arrives
on<SearchQueryChanged>(
  _onQueryChanged,
  transformer: restartable(),
);
```

| Event | Transformer | Reason |
|---|---|---|
| `FetchNextPage` | `droppable()` | Drop duplicate scroll triggers mid-fetch |
| `RefreshFeed` | `droppable()` | Prevent simultaneous pull-to-refresh |
| `SearchQueryChanged` | `restartable()` | Cancel previous search, start fresh |

---

## 6. Tech Stack

| Category | Technology | Reason |
|---|---|---|
| Framework | Flutter (stable) | Required |
| Architecture | Clean Architecture + MVVM | Separation of concerns, testability |
| State Management | `flutter_bloc`, `provider` | Hybrid as required |
| Networking | `dio` | Interceptors, CancelToken, error handling |
| Local Storage | `hive` + `hive_flutter` | Fast NoSQL, works offline |
| Dependency Injection | `get_it` | Service locator, decoupled DI |
| Equality | `equatable` | BLoC state comparison |
| Testing | `bloc_test`, `mocktail` | BLoC unit testing |
| WebView | `webview_flutter` | Full article rendering |
| Connectivity | `connectivity_plus` | Detect online/offline state |
| Environment | `--dart-define` (not dotenv) | Harder to extract from APK |

---

## 7. Caching Strategy

### Strategy: Cache-First with TTL

```
User opens Feed
    └── Load from Hive cache (instant display)
    └── Fetch from API in background
        ├── Success → Update cache + refresh UI
        └── Failure → Keep showing cache (no error flash)
```

### Cache Implementation Details

| Config | Value |
|---|---|
| Hive Box (Feed) | `"articles_cache"` |
| Hive Box (Bookmarks) | `"bookmarks"` |
| Cache Key (Feed) | `"feed_page_{pageNumber}"` |
| TTL | 15 minutes |
| Max cached pages | 5 pages (100 articles) |
| Search results | ❌ Not cached |
| Bookmarks TTL | ∞ (never expire, user-controlled) |

### Cache Invalidation
- TTL expired → fetch fresh, overwrite cache
- Pull-to-refresh → force fetch, reset TTL
- App cold start → check TTL, serve stale if within limit

---

## 8. Security & Environment

### API Key Handling

Use `--dart-define` instead of `flutter_dotenv`:

```bash
# Development
flutter run --dart-define=NEWS_API_KEY=your_key_here

# Production build
flutter build apk \
  --dart-define=NEWS_API_KEY=${{ secrets.NEWS_API_KEY }} \
  --obfuscate \
  --split-debug-info=build/debug-info
```

Access in code:
```dart
const apiKey = String.fromEnvironment('NEWS_API_KEY');
```

**Why not `flutter_dotenv`?**
`.env` files are bundled as assets and extractable from APK via `apktool`. `--dart-define` compiles the value into the binary and is significantly harder to reverse engineer.

### Security Checklist
- `.gitignore` includes any local env files
- API key stored in **GitHub Secrets**, never hardcoded
- Code obfuscation enabled on production builds (`--obfuscate`)
- Debug symbols split (`--split-debug-info`) for crash reporting without exposing logic

---

## 9. Testing Strategy

### Scope (realistic for 3 days)
Focus on **BLoC + UseCase** unit tests only. Skip widget/integration tests unless time permits.

### Priority Test Cases

| # | Test Target | Scenario |
|---|---|---|
| 1 | `NewsFeedBloc` | Emits loading → loaded states on fetch success |
| 2 | `NewsFeedBloc` | Emits error state when API fails |
| 3 | `NewsFeedBloc` | Pagination: appends new articles to existing list |
| 4 | `SearchBloc` | Emits results after debounce delay |
| 5 | `SearchBloc` | Cancels previous request when new query arrives |
| 6 | `GetLatestArticlesUseCase` | Returns cached data when offline |
| 7 | `BookmarkNotifier` | Toggle bookmark adds/removes article correctly |

### Test Structure
```dart
// Example: NewsFeedBloc test
blocTest<NewsFeedBloc, NewsFeedState>(
  'emits [Loading, Loaded] when fetch succeeds',
  build: () {
    when(() => mockUseCase(any())).thenAnswer((_) async => Right(articles));
    return NewsFeedBloc(getArticles: mockUseCase);
  },
  act: (bloc) => bloc.add(FetchArticlesEvent()),
  expect: () => [NewsFeedLoading(), NewsFeedLoaded(articles: articles)],
);
```

---

## 10. CI/CD Pipeline (GitHub Actions)

### Overview

| Workflow | Trigger | Jobs |
|---|---|---|
| `ci.yml` | Pull Request (opened / updated) | Test → Analyze → Copilot Review |
| `build.yml` | Push to `main` | Build APK debug |

---

### Workflow 1: `ci.yml` — PR Checks

```yaml
name: CI — PR Checks

on:
  pull_request:
    branches: [main, develop]

jobs:
  test:
    name: Run Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests (BLoC focus)
        run: flutter test test/features/ --coverage

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/lcov.info

  analyze:
    name: Flutter Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          cache: true
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
```

> **Copilot Auto Review:** Enable in **Repository Settings → Copilot → Code Review → Automatic review on pull requests**. Copilot will automatically comment on PRs — no workflow YAML needed.

---

### Workflow 2: `build.yml` — Build APK on Merge to Main

```yaml
name: Build — APK on Merge

on:
  push:
    branches: [main]

jobs:
  build:
    name: Build Debug APK
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK
        run: |
          flutter build apk \
            --dart-define=NEWS_API_KEY=${{ secrets.NEWS_API_KEY }} \
            --obfuscate \
            --split-debug-info=build/debug-info
        env:
          NEWS_API_KEY: ${{ secrets.NEWS_API_KEY }}

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: debug-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          retention-days: 7
```

### GitHub Secrets Required
Go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `NEWS_API_KEY` | Your NewsAPI key |

---

## 11. 3-Day Development Timeline

> **Principle:** CI/CD is set up on Day 1 — before any feature code is written. This ensures every commit from Day 1 onward is automatically tested and reviewed by Copilot, which is the entire point of having a pipeline. Unit tests are written **in the same day** as the feature they cover.

### Day 1 — Foundation + CI/CD + News Feed
- [ ] Project setup: folder structure, dependencies, GetIt DI
- [ ] **GitHub Actions: `ci.yml` + `build.yml`** ← set up before writing features
- [ ] **Enable Copilot Auto Review in repo settings** ← active from first PR
- [ ] Dio client with interceptors (auth header, error handling, logging)
- [ ] Hive setup: open boxes, cache helper with TTL logic
- [ ] `Article` entity + `ArticleModel` (JSON parsing)
- [ ] `INewsFeedRepository` + `NewsFeedRepositoryImpl`
- [ ] `GetLatestArticlesUseCase`
- [ ] `NewsFeedBloc` (fetch + pagination)
- [ ] **Unit tests: `NewsFeedBloc`** (loading → loaded, error state, pagination) ← same day as BLoC
- [ ] **Unit tests: `GetLatestArticlesUseCase`** (offline cache scenario) ← same day as UseCase
- [ ] `NewsFeedPage` UI with infinite scroll + pull-to-refresh
- [ ] Error / empty / loading states for Feed

### Day 2 — Search + Article Detail + Bookmarks + Unit Tests
- [ ] `SearchBloc` with debounce `EventTransformer` + `CancelToken`
- [ ] **Unit tests: `SearchBloc`** (debounce, cancel previous request) ← same day as BLoC
- [ ] Search UI + states
- [ ] `ArticleDetailPage` with `ValueNotifier`
- [ ] WebView integration for full article
- [ ] `BookmarkNotifier` with Hive persistence
- [ ] **Unit tests: `BookmarkNotifier`** (add/remove toggle) ← same day as Notifier
- [ ] Bookmark UI (add/remove, offline list)

### Day 3 — Polish + Security + Final QA
- [ ] Connectivity check + offline banner
- [ ] Error handling review across all features
- [ ] `--dart-define` for API key + obfuscation flags in build command
- [ ] Additional unit tests for edge cases
- [ ] Final test run + bug fixes
- [ ] README with setup instructions (include `--dart-define` usage)

---

## 12. Data Flow Diagram

```
NewsAPI
   │
   ▼
RemoteDataSource (Dio)
   │
   ▼
NewsFeedRepositoryImpl
   ├── Cache miss / TTL expired → fetch API → save to Hive
   └── Cache hit → return Hive data
   │
   ▼
GetLatestArticlesUseCase
   │
   ▼
NewsFeedBloc
   │ emits states
   ▼
NewsFeedPage (Flutter UI)
```

---

---

## 13. Repository Interface Example

The domain layer defines repository contracts as abstract classes. The data layer provides the concrete implementation — this is Dependency Inversion in practice.

```dart
// domain/repositories/i_news_feed_repository.dart
abstract class INewsFeedRepository {
  Future<Either<Failure, List<Article>>> getLatestArticles(int page);
  Future<Either<Failure, List<Article>>> searchArticles(String query);
}
```

```dart
// data/repositories/news_feed_repository_impl.dart
class NewsFeedRepositoryImpl implements INewsFeedRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NewsFeedRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Article>>> getLatestArticles(int page) async {
    final cached = await localDataSource.getCachedArticles(page);
    if (cached != null && !cached.isExpired) {
      return Right(cached.articles);
    }
    try {
      final articles = await remoteDataSource.fetchArticles(page);
      await localDataSource.cacheArticles(page, articles);
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

Using `Either<Failure, T>` keeps error handling **explicit at the type level** — callers are forced to handle both success and failure paths, eliminating silent null returns.

---

## 14. Connectivity Strategy

Connectivity detection uses `connectivity_plus`. The check runs inside the repository — BLoC never touches network state directly.

```dart
// core/network/network_info.dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

Decision flow inside every repository call:

```
NetworkInfo.isConnected?
    ├── true  → RemoteDataSource.fetch()
    │               ├── success → save to Hive cache → return Right(data)
    │               └── failure → return cache if valid, else Left(ServerFailure)
    └── false → return Hive cache if available
                    └── cache empty → return Left(NoInternetFailure)
```

This keeps BLoC clean — it only reacts to `Failure` types, never infrastructure concerns.

---

*Plan version: 5.0 — Unit tests now co-located with feature in same day; NewsFeedBloc tests moved to Day 1.
