import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/domain/usecases/get_latest_articles.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_state.dart';

class MockGetLatestArticlesUseCase extends Mock
    implements GetLatestArticlesUseCase {}

void main() {
  late NewsFeedBloc bloc;
  late MockGetLatestArticlesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetLatestArticlesUseCase();
    bloc = NewsFeedBloc(getLatestArticles: mockUseCase);
  });

  tearDown(() => bloc.close());

  final tArticles = List.generate(
    20,
    (i) => Article(
      id: 'https://example.com/$i',
      title: 'Article $i',
      url: 'https://example.com/$i',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Source $i',
    ),
  );

  final tFewArticles = [
    Article(
      id: 'https://example.com/1',
      title: 'Article 1',
      url: 'https://example.com/1',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Source',
    ),
  ];

  group('FetchLatestArticles', () {
    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Loaded] when fetch succeeds',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => Right(tArticles));
        return bloc;
      },
      act: (b) => b.add(const FetchLatestArticles()),
      expect: () => [
        const NewsFeedLoading(),
        NewsFeedLoaded(articles: tArticles),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Error] when fetch fails',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => const Left(ServerFailure()));
        return bloc;
      },
      act: (b) => b.add(const FetchLatestArticles()),
      expect: () => [
        const NewsFeedLoading(),
        const NewsFeedError('Server error. Please try again.'),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'sets hasReachedMax true when fewer than 20 articles returned',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => Right(tFewArticles));
        return bloc;
      },
      act: (b) => b.add(const FetchLatestArticles()),
      expect: () => [
        const NewsFeedLoading(),
        NewsFeedLoaded(articles: tFewArticles, hasReachedMax: true),
      ],
    );
  });

  group('FetchNextPage', () {
    blocTest<NewsFeedBloc, NewsFeedState>(
      'appends articles when page 2 succeeds',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tFewArticles));
        return bloc;
      },
      seed: () => NewsFeedLoaded(articles: tArticles),
      act: (b) => b.add(const FetchNextPage()),
      expect: () => [
        NewsFeedLoaded(articles: tArticles, isLoadingMore: true),
        NewsFeedLoaded(
          articles: [...tArticles, ...tFewArticles],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'does nothing when hasReachedMax is true',
      build: () => bloc,
      seed: () =>
          NewsFeedLoaded(articles: tArticles, hasReachedMax: true),
      act: (b) => b.add(const FetchNextPage()),
      expect: () => <NewsFeedState>[],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'does nothing when state is not NewsFeedLoaded',
      build: () => bloc,
      act: (b) => b.add(const FetchNextPage()),
      expect: () => <NewsFeedState>[],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits paginationError on pagination failure',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure()));
        return bloc;
      },
      seed: () => NewsFeedLoaded(articles: tArticles),
      act: (b) => b.add(const FetchNextPage()),
      expect: () => [
        NewsFeedLoaded(articles: tArticles, isLoadingMore: true),
        NewsFeedLoaded(
          articles: tArticles,
          paginationError: 'Server error. Please try again.',
        ),
      ],
    );
  });

  group('RefreshFeed', () {
    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Loaded] with fresh articles',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => Right(tArticles));
        return bloc;
      },
      seed: () => NewsFeedLoaded(articles: tFewArticles),
      act: (b) => b.add(const RefreshFeed()),
      expect: () => [
        const NewsFeedLoading(),
        NewsFeedLoaded(articles: tArticles),
      ],
    );

    blocTest<NewsFeedBloc, NewsFeedState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockUseCase(1))
            .thenAnswer((_) async => const Left(NoInternetFailure()));
        return bloc;
      },
      act: (b) => b.add(const RefreshFeed()),
      expect: () => [
        const NewsFeedLoading(),
        const NewsFeedError('No internet connection.'),
      ],
    );
  });
}
