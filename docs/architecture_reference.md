# Architecture Reference

Code templates and patterns for Clean Architecture + MVVM implementation.

---

## Entity — Pure Dart Value Object

No serialization, no Flutter/third-party imports. Lives in `domain/entities/`.

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

---

## Model — JSON + Hive Serialization

Extends Entity, lives in `data/models/`. Uses `@HiveType` and `@HiveField` annotations.

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

---

## Repository Interface — Domain Layer

Lives in `domain/repositories/`. Returns `Either<Failure, T>`.

```dart
// domain/repositories/i_news_feed_repository.dart
abstract class INewsFeedRepository {
  Future<Either<Failure, List<Article>>> getLatestArticles(int page);
  Future<Either<Failure, List<Article>>> searchArticles(String query);
}
```

---

## Use Case — Single Responsibility

Lives in `domain/usecases/`. Single `call()` method.

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

## BLoC Events and States

### Events

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

### States

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

---

## BLoC with Concurrency Transformers

### NewsFeedBloc — `droppable()`

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

### SearchBloc — `restartable()`

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

## Failure Hierarchy

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

## Testing Patterns

### Test Structure (bloc_test + mocktail)

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

### Mocking Pattern (mocktail — NEVER mockito)

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
