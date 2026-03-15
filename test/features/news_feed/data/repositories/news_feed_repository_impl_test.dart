import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/network/network_info.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_local_datasource.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_remote_datasource.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';
import 'package:news_app/features/news_feed/data/models/cached_feed.dart';
import 'package:news_app/features/news_feed/data/repositories/news_feed_repository_impl.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

class MockRemoteDataSource extends Mock implements NewsFeedRemoteDataSource {}

class MockLocalDataSource extends Mock implements NewsFeedLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late NewsFeedRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late MockNetworkInfo mockNetwork;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    mockNetwork = MockNetworkInfo();
    repository = NewsFeedRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      networkInfo: mockNetwork,
    );
  });

  final tArticleModels = [
    ArticleModel(
      id: 'https://example.com/1',
      title: 'Test Article 1',
      url: 'https://example.com/1',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Test Source',
    ),
  ];

  final tCachedFeed = CachedFeed(
    articles: tArticleModels,
    cachedAt: DateTime.now(),
  );

  final tExpiredCachedFeed = CachedFeed(
    articles: tArticleModels,
    cachedAt: DateTime.now().subtract(const Duration(minutes: 20)),
  );

  void stubCacheArticles() {
    when(() => mockLocal.cacheArticles(any(), any()))
        .thenAnswer((_) async {});
  }

  group('getLatestArticles — cache hit (valid)', () {
    test('returns cached articles immediately when cache is valid', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(tCachedFeed);
      when(() => mockRemote.fetchArticles(any()))
          .thenAnswer((_) async => (tArticleModels, 100));
      stubCacheArticles();

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Right<Failure, (List<Article>, int)>>());
      verify(() => mockLocal.getCachedArticles(1)).called(1);
    });

    test('triggers background refresh on valid cache hit', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(tCachedFeed);
      when(() => mockRemote.fetchArticles(1))
          .thenAnswer((_) async => (tArticleModels, 100));
      stubCacheArticles();

      await repository.getLatestArticles(1);
      // Allow background future to complete
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRemote.fetchArticles(1)).called(1);
    });
  });

  group('getLatestArticles — cache miss', () {
    test('fetches from remote and caches result when no cache', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(null);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenAnswer((_) async => (tArticleModels, 100));
      stubCacheArticles();

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Right<Failure, (List<Article>, int)>>());
      verify(() => mockLocal.cacheArticles(1, tArticleModels)).called(1);
    });
  });

  group('getLatestArticles — cache expired', () {
    test('fetches from remote when cache is expired', () async {
      when(() => mockLocal.getCachedArticles(1))
          .thenReturn(tExpiredCachedFeed);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenAnswer((_) async => (tArticleModels, 100));
      stubCacheArticles();

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Right<Failure, (List<Article>, int)>>());
      verify(() => mockRemote.fetchArticles(1)).called(1);
    });

    test('caches fresh data after remote fetch', () async {
      when(() => mockLocal.getCachedArticles(1))
          .thenReturn(tExpiredCachedFeed);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenAnswer((_) async => (tArticleModels, 100));
      stubCacheArticles();

      await repository.getLatestArticles(1);
      await Future<void>.delayed(Duration.zero);

      verify(() => mockLocal.cacheArticles(1, tArticleModels)).called(1);
    });
  });

  group('getLatestArticles — offline', () {
    test('returns stale cache when offline and cache exists', () async {
      when(() => mockLocal.getCachedArticles(1))
          .thenReturn(tExpiredCachedFeed);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Right<Failure, (List<Article>, int)>>());
      verifyNever(() => mockRemote.fetchArticles(any()));
    });

    test('returns NoInternetFailure when offline and no cache', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(null);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);

      final result = await repository.getLatestArticles(1);

      expect(
        result,
        const Left<Failure, (List<Article>, int)>(NoInternetFailure()),
      );
    });
  });

  group('getLatestArticles — remote errors', () {
    test('returns ServerFailure on ServerException', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(null);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenThrow(const ServerException());

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Left<Failure, (List<Article>, int)>>());
    });

    test('returns TimeoutFailure on TimeoutException', () async {
      when(() => mockLocal.getCachedArticles(1)).thenReturn(null);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenThrow(const TimeoutException());

      final result = await repository.getLatestArticles(1);

      expect(
        result,
        const Left<Failure, (List<Article>, int)>(TimeoutFailure()),
      );
    });

    test('falls back to stale cache on remote failure', () async {
      when(() => mockLocal.getCachedArticles(1))
          .thenReturn(tExpiredCachedFeed);
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockRemote.fetchArticles(1))
          .thenThrow(const ServerException());

      final result = await repository.getLatestArticles(1);

      expect(result, isA<Right<Failure, (List<Article>, int)>>());
    });
  });
}
