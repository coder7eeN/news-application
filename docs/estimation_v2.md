# Flutter News App — Estimation Document
> Based on Technical Plan v5.0

---

## Story Point Scale

| Points | Complexity | Description |
|---|---|---|
| 1 | Trivial | Straightforward task, no unknowns |
| 2 | Simple | Minor logic, low risk |
| 3 | Medium | Some complexity, clear approach |
| 5 | Complex | Multiple moving parts, moderate risk |
| 8 | Hard | High complexity, cross-layer impact |
| 13 | Very Hard | Significant unknowns, requires design decisions |

---

## Epic Overview

| Epic | User Stories | Total Story Points |
|---|---|---|
| EP-1 Foundation & CI/CD | US-01, US-02 | 8 |
| EP-2 News Feed | US-03, US-04, US-05 | 16 |
| EP-3 Search | US-06, US-07 | 11 |
| EP-4 Article Detail | US-08 | 5 |
| EP-5 Bookmarks | US-09, US-10 | 8 |
| EP-6 Error Handling | US-11 | 5 |
| EP-7 Security & Final QA | US-12, US-13 | 5 |
| **Total** | **13 User Stories** | **58 points** |

---

## DAY 1 — Foundation + CI/CD + News Feed

---

### US-01 — Project Foundation Setup
> **As a developer**, I want a clean project structure with dependency injection and core infrastructure ready, so that all features can be built on a consistent and scalable base.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-01-1 | Initialize Flutter project, configure folder structure (`core/`, `features/`) | 30m |
| ST-01-2 | Add all dependencies to `pubspec.yaml`, run `flutter pub get` | 20m |
| ST-01-3 | Set up GetIt service locator — `injection_container.dart` with initial registrations | 45m |
| ST-01-4 | Configure Dio client — base URL, headers, timeout, logging interceptor | 45m |
| ST-01-5 | Set up Hive — open boxes (`articles_cache`, `bookmarks`), register adapters | 30m |
| ST-01-6 | Implement `NetworkInfo` abstraction + `NetworkInfoImpl` using `connectivity_plus` | 30m |
| ST-01-7 | Define `Failure` base class and subtypes (`ServerFailure`, `NoInternetFailure`, `CacheFailure`) | 20m |

**Total: ~3h 40m**

---

### US-02 — CI/CD Pipeline Setup
> **As a developer**, I want automated tests and Copilot code review to run on every Pull Request, and an APK to build automatically on merge to main, so that code quality is enforced from the very first commit.

**Story Points: 3**

> ⚠️ **Must be completed before any feature PR is raised** — this ensures the pipeline is active throughout Day 1, Day 2, and Day 3.

| # | Subtask | Estimate |
|---|---|---|
| ST-02-1 | Create `.github/workflows/ci.yml` — PR trigger, `flutter test test/features/ --coverage`, `flutter analyze --fatal-infos` | 30m |
| ST-02-2 | Create `.github/workflows/build.yml` — push to `main` trigger, build APK with `--dart-define` + `--obfuscate` + `--split-debug-info` | 30m |
| ST-02-3 | Add `NEWS_API_KEY` to GitHub Secrets | 10m |
| ST-02-4 | Enable Copilot Auto Review in repository settings | 10m |
| ST-02-5 | Open a test PR to verify pipeline runs correctly end-to-end | 20m |

**Total: ~1h 40m**

---

### US-03 — View Latest News Articles
> **As a user**, I want to see a list of the latest news articles when I open the app, so that I can quickly catch up on current events.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-03-1 | Create `Article` entity in domain layer (pure Dart, Equatable, no Flutter deps) | 20m |
| ST-03-2 | Create `ArticleModel` in data layer with `fromJson` / `toJson` + Hive `TypeAdapter` | 40m |
| ST-03-3 | Define `INewsFeedRepository` abstract interface in domain layer | 15m |
| ST-03-4 | Implement `RemoteDataSource` — call NewsAPI `/top-headlines`, map response to `ArticleModel` list | 45m |
| ST-03-5 | Implement `NewsFeedRepositoryImpl` — wire `RemoteDataSource`, return `Either<Failure, List<Article>>` | 30m |
| ST-03-6 | Implement `GetLatestArticlesUseCase` — single responsibility, calls repository interface | 20m |
| ST-03-7 | Build `NewsFeedPage` and `ArticleCard` widget — display title, image, source, published date | 45m |

**Total: ~3h 35m**

---

### US-04 — Paginate Through News Articles
> **As a user**, I want to scroll down and automatically load more articles, so that I can read beyond the first page without any manual action.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-04-1 | Implement `NewsFeedBloc` with events: `FetchFeed`, `FetchNextPage`, `RefreshFeed` and state properties: `articles`, `page`, `isLoading`, `hasReachedMax` | 1h |
| ST-04-2 | Configure `droppable()` transformer on `FetchNextPage` and `RefreshFeed` via `bloc_concurrency` | 20m |
| ST-04-3 | Attach `ScrollController` to `ListView` — dispatch `FetchNextPage` when scroll reaches 80% | 30m |
| ST-04-4 | Show pagination loading indicator at the bottom of the list during next-page fetch | 20m |
| ST-04-5 | Handle `hasReachedMax` — stop dispatching `FetchNextPage` when API returns empty list | 20m |

**Total: ~2h 30m**

---

### US-05 — Cache News Feed for Fast Loading
> **As a user**, I want to see articles instantly when I open the app even before the API responds, so that the experience feels fast and never shows a blank screen.

**Story Points: 6**

| # | Subtask | Estimate |
|---|---|---|
| ST-05-1 | Implement `LocalDataSource` — `getCachedArticles(page)` and `cacheArticles(page, articles)` using Hive box `"articles_cache"` with key format `"feed_page_{page}"` | 45m |
| ST-05-2 | Add TTL logic — store timestamp alongside cache data, check 15-minute expiry on every read | 30m |
| ST-05-3 | Update `NewsFeedRepositoryImpl` — cache-first flow: serve Hive instantly → fetch API in background → update cache on success | 45m |
| ST-05-4 | Handle pull-to-refresh — force API fetch, reset TTL, update UI with fresh data | 30m |
| **ST-05-5** | **Unit tests: `NewsFeedBloc`** — emits loading→loaded on success, emits error state on API failure, pagination appends articles correctly | **45m** |
| **ST-05-6** | **Unit tests: `GetLatestArticlesUseCase`** — returns cached data when offline (`NoInternetFailure`), fetches remote when cache is expired | **30m** |

**Total: ~3h 45m**

> ✅ Unit tests for `NewsFeedBloc` and `GetLatestArticlesUseCase` are written on Day 1 — same day the BLoC and UseCase are implemented — so CI catches regressions from the first PR.

---

## DAY 2 — Search + Article Detail + Bookmarks

---

### US-06 — Search Articles by Keyword
> **As a user**, I want to type a keyword and see relevant articles, so that I can find news on specific topics I care about.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-06-1 | Implement `SearchRemoteDataSource` — call NewsAPI `/everything?q={query}`, reuse `ArticleModel` | 40m |
| ST-06-2 | Implement `ISearchRepository` interface + `SearchRepositoryImpl` with `NetworkInfo` check | 30m |
| ST-06-3 | Implement `SearchArticlesUseCase` | 15m |
| ST-06-4 | Build `SearchPage` with `TextField`, results `ListView`, and loading / empty / error states | 45m |

**Total: ~2h 10m**

---

### US-07 — Optimized Search with Debounce and Request Cancellation
> **As a user**, I want the search to not spam the API while I'm still typing, and for stale results to never replace fresh ones, so that the experience is smooth and accurate.

**Story Points: 6**

| # | Subtask | Estimate |
|---|---|---|
| ST-07-1 | Implement `SearchBloc` with `SearchQueryChanged` event using `restartable()` transformer | 45m |
| ST-07-2 | Apply 400ms debounce inside `SearchBloc` — delay dispatch before calling UseCase | 20m |
| ST-07-3 | Pass `CancelToken` from Dio into `SearchRemoteDataSource.search()` — cancel on new query via `restartable()` | 45m |
| ST-07-4 | Handle empty query — emit `SearchInitial` state without firing API call | 20m |
| **ST-07-5** | **Unit tests: `SearchBloc`** — emits results after debounce delay, cancels previous request when new query arrives, emits empty state on blank input | **45m** |

**Total: ~2h 55m**

---

### US-08 — View Full Article Content
> **As a user**, I want to tap an article and see its full content or read it in a browser view, so that I can consume the complete news story without leaving the app.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-08-1 | Implement `ArticleDetailNotifier` using `ValueNotifier<ArticleDetailState>` — 3 states: loading / loaded / error | 30m |
| ST-08-2 | Build `ArticleDetailPage` — display title, hero image, description, source, published date | 45m |
| ST-08-3 | Integrate `webview_flutter` — load article URL, show linear loading progress indicator | 45m |
| ST-08-4 | Handle WebView errors — fallback to open URL in external browser | 30m |
| ST-08-5 | Register `ArticleDetailNotifier` in GetIt | 15m |

**Total: ~2h 45m**

---

### US-09 — Bookmark Articles to Read Later
> **As a user**, I want to save articles by tapping a bookmark icon, so that I can easily come back to read them later.

**Story Points: 3**

| # | Subtask | Estimate |
|---|---|---|
| ST-09-1 | Implement `BookmarkNotifier` using `ChangeNotifier` — in-memory `List<Article>` backed by Hive box `"bookmarks"` | 45m |
| ST-09-2 | Implement `toggleBookmark(Article)` — add if not bookmarked, remove if already saved | 20m |
| ST-09-3 | Expose `isBookmarked(String url)` for reactive icon state in feed and detail pages | 15m |
| ST-09-4 | Add bookmark icon to `ArticleCard` — listens to `BookmarkNotifier`, updates instantly (optimistic UI) | 30m |
| ST-09-5 | Register `BookmarkNotifier` as singleton in GetIt | 10m |

**Total: ~2h**

---

### US-10 — Access Bookmarks Offline
> **As a user**, I want my saved articles to be fully accessible without an internet connection, so that I can always read bookmarked content regardless of network status.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-10-1 | Load all bookmarks from Hive on app startup — pre-populate `BookmarkNotifier` before first frame renders | 20m |
| ST-10-2 | Build `BookmarkPage` — list of saved articles using `BookmarkNotifier`, empty state if none saved | 45m |
| ST-10-3 | Verify `BookmarkPage` is fully functional without network — reads only from Hive, no API calls | 20m |
| **ST-10-4** | **Unit tests: `BookmarkNotifier`** — toggle adds article correctly, toggle removes existing article, state persists to Hive | **45m** |

**Total: ~2h 10m**

---

## DAY 3 — Polish + Security + Final QA

---

### US-11 — Graceful Error and Offline Handling Across All Features
> **As a user**, I want to see clear, friendly messages and retry options whenever something goes wrong, so that I'm never stuck on a broken or empty screen.

**Story Points: 5**

| # | Subtask | Estimate |
|---|---|---|
| ST-11-1 | Add offline detection banner (top Snackbar / persistent bar) using `connectivity_plus` stream — appears when device goes offline | 30m |
| ST-11-2 | Build reusable `ErrorStateWidget` — displays message + Retry button — shared across Feed, Search, Article Detail | 30m |
| ST-11-3 | Build reusable `EmptyStateWidget` — illustration placeholder + contextual suggestion text | 20m |
| ST-11-4 | Map all `Failure` subtypes to user-friendly messages in presentation layer — `ServerFailure`, `NoInternetFailure`, `CacheFailure` | 30m |
| ST-11-5 | Verify error flows end-to-end: no internet → Feed shows cached data, Search shows offline message; server error → Retry button appears | 30m |

**Total: ~2h 20m**

---

### US-12 — Secure API Key for Production Build
> **As a developer**, I want the API key compiled into the binary and never stored as a plain asset, so that the key cannot be extracted from the distributed APK.

**Story Points: 2**

| # | Subtask | Estimate |
|---|---|---|
| ST-12-1 | Replace any hardcoded key references with `String.fromEnvironment('NEWS_API_KEY')` in Dio setup | 20m |
| ST-12-2 | Update local dev run command in README to use `--dart-define=NEWS_API_KEY=...` | 10m |
| ST-12-3 | Confirm `build.yml` uses `--dart-define` + `--obfuscate` + `--split-debug-info` | 10m |
| ST-12-4 | Add any local env files to `.gitignore` | 10m |

**Total: ~50m**

---

### US-13 — Final QA and Documentation
> **As a developer**, I want a final quality pass and a clear README, so that the project is clean, well-documented, and ready to submit.

**Story Points: 3**

| # | Subtask | Estimate |
|---|---|---|
| ST-13-1 | Run full test suite locally and confirm all tests pass in CI pipeline | 20m |
| ST-13-2 | Manual smoke test — full user flow: Feed → Search → Article Detail → Bookmark → Offline mode | 30m |
| ST-13-3 | Write `README.md` — project overview, setup instructions, `--dart-define` usage, how to run tests | 30m |
| ST-13-4 | Code cleanup — remove debug `print()` statements, unused imports, dead code | 20m |

**Total: ~1h 40m**

---

## Dependency Map

### Foundation Dependencies (blockers for everything)

```
ST-01-1  Project setup & folder structure
    └── ST-01-2  Add dependencies (pubspec.yaml)
            ├── ST-01-3  GetIt setup           → required by ALL features
            ├── ST-01-4  Dio client            → required by ALL RemoteDataSources
            ├── ST-01-5  Hive setup            → required by ALL LocalDataSources
            ├── ST-01-6  NetworkInfo           → required by ALL RepositoryImpl
            └── ST-01-7  Failure classes       → required by ALL UseCases & BLoCs
```

> US-01 must be **fully complete** before any feature work begins. ST-01-1 through ST-01-7 are hard blockers.

---

### CI/CD Dependency

| Dependency | Rule |
|---|---|
| US-02 depends on ST-01-1 | Repo must exist before workflows can be committed |
| US-02 must finish before first feature PR | CI pipeline must be active before any feature code is reviewed |

> US-02 is set up on **Day 1 morning**, immediately after project init — so every PR from the first feature onward is automatically tested and reviewed.

---

### News Feed Dependencies (Day 1)

| Subtask | Depends On | Reason |
|---|---|---|
| ST-03-1 `Article` entity | ST-01-7 Failure classes | Entity used in `Either<Failure, List<Article>>` return types |
| ST-03-2 `ArticleModel` | ST-03-1 `Article` entity | Model maps JSON → Entity |
| ST-03-3 `INewsFeedRepository` | ST-03-1 `Article` entity | Interface signature uses `Article` |
| ST-03-4 `RemoteDataSource` | ST-01-4 Dio client, ST-03-2 `ArticleModel` | Dio must be configured; model needed for JSON mapping |
| ST-03-5 `NewsFeedRepositoryImpl` | ST-03-3, ST-03-4, ST-01-5, ST-01-6 | Requires interface, datasource, Hive, and NetworkInfo |
| ST-03-6 `GetLatestArticlesUseCase` | ST-03-3 `INewsFeedRepository` | UseCase depends on repository interface, not impl |
| ST-04-1 `NewsFeedBloc` | ST-03-6 UseCase | BLoC calls UseCase |
| ST-04-2 Concurrency transformers | ST-04-1 `NewsFeedBloc` | Transformers are registered on BLoC events |
| ST-03-7 `NewsFeedPage` UI | ST-04-1 `NewsFeedBloc` | Page consumes BLoC states |
| ST-04-3 Scroll pagination | ST-03-7 `NewsFeedPage` | `ScrollController` added to the list widget |
| ST-05-1 `LocalDataSource` | ST-01-5 Hive setup | Reads/writes to Hive box |
| ST-05-2 TTL logic | ST-05-1 `LocalDataSource` | TTL wraps LocalDataSource reads |
| ST-05-3 Cache-first in Repository | ST-05-1, ST-05-2, ST-03-5 | Extends RepositoryImpl with cache layer |
| ST-05-5 Unit tests: `NewsFeedBloc` | ST-04-1 `NewsFeedBloc` | BLoC must exist before it can be tested |
| ST-05-6 Unit tests: `GetLatestArticlesUseCase` | ST-03-6 UseCase, ST-05-3 Cache-first | Tests the full offline + cache flow |

---

### Search Dependencies (Day 2)

| Subtask | Depends On | Reason |
|---|---|---|
| ST-06-1 `SearchRemoteDataSource` | ST-01-4 Dio, ST-03-2 `ArticleModel` | Reuses Dio client and existing ArticleModel |
| ST-06-2 `SearchRepositoryImpl` | ST-06-1, ST-01-6 NetworkInfo | Needs datasource + connectivity check |
| ST-06-3 `SearchArticlesUseCase` | ST-06-2 `ISearchRepository` | UseCase depends on repository interface |
| ST-07-1 `SearchBloc` | ST-06-3 UseCase | BLoC calls UseCase |
| ST-07-2 Debounce logic | ST-07-1 `SearchBloc` | Debounce applied inside BLoC event handler |
| ST-07-3 `CancelToken` integration | ST-06-1 `SearchRemoteDataSource` | Must modify datasource method signature |
| ST-06-4 `SearchPage` UI | ST-07-1 `SearchBloc` | Page consumes BLoC states |
| ST-07-5 Unit tests: `SearchBloc` | ST-07-1, ST-07-2, ST-07-3 | Tests debounce + cancel — both must be implemented first |

---

### Article Detail Dependencies (Day 2)

| Subtask | Depends On | Reason |
|---|---|---|
| ST-08-1 `ArticleDetailNotifier` | ST-03-1 `Article` entity | Notifier receives and holds an `Article` object |
| ST-08-2 `ArticleDetailPage` | ST-08-1 `ArticleDetailNotifier` | Page listens to notifier state |
| ST-08-3 WebView integration | ST-08-2 `ArticleDetailPage` | WebView is embedded inside the page |
| ST-08-4 WebView error fallback | ST-08-3 WebView | Fallback handles WebView failure events |

---

### Bookmark Dependencies (Day 2)

| Subtask | Depends On | Reason |
|---|---|---|
| ST-09-1 `BookmarkNotifier` | ST-01-5 Hive, ST-03-1 `Article` entity | Stores `Article` objects in Hive |
| ST-09-2 `toggleBookmark` | ST-09-1 `BookmarkNotifier` | Method lives inside the notifier |
| ST-09-3 `isBookmarked` | ST-09-1 `BookmarkNotifier` | Query method on notifier state |
| ST-09-4 Bookmark icon in `ArticleCard` | ST-09-1, ST-09-3 | Card calls `isBookmarked` and `toggleBookmark` |
| ST-10-1 Load bookmarks on startup | ST-09-1 `BookmarkNotifier` | Requires notifier singleton to be registered |
| ST-10-2 `BookmarkPage` | ST-09-1, ST-10-1 | Page renders the notifier's article list |
| ST-10-3 Offline verification | ST-10-2 `BookmarkPage` | Requires completed UI to verify offline behavior |
| ST-10-4 Unit tests: `BookmarkNotifier` | ST-09-1, ST-09-2 | Tests toggle + Hive persistence after notifier is complete |

---

### Day 3 Dependencies

| Subtask | Depends On | Reason |
|---|---|---|
| ST-11-1 Offline banner | ST-01-6 `NetworkInfo` | Subscribes to connectivity stream |
| ST-11-2 `ErrorStateWidget` | ST-01-7 Failure classes | Displays message based on `Failure` type |
| ST-11-4 Failure → message mapping | ST-01-7, ST-11-2 | Requires widget + all Failure subtypes defined |
| ST-11-5 End-to-end error verification | All feature pages complete | Requires Feed, Search, Detail pages to exist |
| ST-12-1 `--dart-define` in Dio | ST-01-4 Dio client | Updates existing Dio configuration |
| ST-13-1 Full test suite | All unit test subtasks (ST-05-5, ST-05-6, ST-07-5, ST-10-4) | All tests must exist before final CI run |
| ST-13-2 Smoke test | All feature pages complete | Requires all UI screens to be functional |
| ST-13-3 README | ST-12-1, ST-12-2 | Documents `--dart-define` usage — needs security step done first |

---

### Parallel Work Opportunities

Once US-01 Foundation is done and `Article` entity (ST-03-1) exists, the following can proceed **in parallel**:

```
US-01 Foundation + US-02 CI/CD complete
    │
    ├── US-03 → US-04 → US-05    News Feed chain (sequential, Day 1)
    │
    └── After ST-03-1 Article entity exists:
            ├── US-06 → US-07    Search  (Day 2, independent of Bookmark)
            ├── US-08            Article Detail  (Day 2, independent of Search)
            └── US-09 → US-10   Bookmarks  (Day 2, independent of Search)
```

Search, Article Detail, and Bookmarks share only the `Article` entity — they do **not** depend on each other and can be developed in any order on Day 2.

---

## Total Time Summary by Day

| Day | Epics Covered | User Stories | Est. Hours |
|---|---|---|---|
| Day 1 | EP-1 Foundation + CI/CD, EP-2 News Feed (+ unit tests) | US-01, US-02, US-03, US-04, US-05 | ~9h |
| Day 2 | EP-3 Search (+ unit tests), EP-4 Article Detail, EP-5 Bookmarks (+ unit tests) | US-06, US-07, US-08, US-09, US-10 | ~9h |
| Day 3 | EP-6 Error Handling, EP-7 Security & Final QA | US-11, US-12, US-13 | ~7h |
| **Total** | 7 Epics | **13 User Stories / 58 pts** | **~25h** |

> **Key principle reflected in this estimate:** Unit tests are written on the **same day** as the feature — `NewsFeedBloc` tests on Day 1, `SearchBloc` and `BookmarkNotifier` tests on Day 2. CI/CD is active from **Day 1** so every PR is automatically tested and Copilot-reviewed throughout the entire project.
