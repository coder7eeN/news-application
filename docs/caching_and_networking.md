# Caching and Networking Reference

---

## Cache Constants

All constants live in `core/cache/cache_constants.dart` — never hardcode inline.

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

| Config | Value |
|---|---|
| Feed box | `"articles_cache"` |
| Bookmarks box | `"bookmarks"` |
| Cache key | `"feed_page_{page}"` |
| TTL | 15 minutes |
| Max pages cached | 5 (100 articles) |
| Search results | Never cached |
| Bookmarks TTL | Infinite — user-controlled only |

Pull-to-refresh -> force-fetch, reset TTL, ignore existing cache.

---

## Cache-First Repository Implementation

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

---

## Networking — Dio Only

Never use `http` package or `dart:io` HttpClient directly.

### Dio Client Setup

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

### Auth Interceptor

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

### CancelToken for Search

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

## Security Rules

**NEVER use `flutter_dotenv`** — `.env` files are bundled as assets and extractable from APK.

```bash
# Correct — key compiled into binary, not extractable
flutter run --dart-define=NEWS_API_KEY=abc123

# Wrong — key lives in assets/, extractable from APK
# (using flutter_dotenv + .env file)
```

Access key in code:
```dart
// Evaluated at compile time — not at runtime
const apiKey = String.fromEnvironment('NEWS_API_KEY');
```

### Security Checklist

- [ ] `NEWS_API_KEY` stored in GitHub Secrets only — never hardcoded
- [ ] `--obfuscate` flag present in build command
- [ ] `--split-debug-info=build/debug-info` present
- [ ] No API key in any committed file
- [ ] `.gitignore` covers any local env files
