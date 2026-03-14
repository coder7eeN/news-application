import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/search/domain/usecases/search_articles.dart';
import 'package:news_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:news_app/features/search/presentation/bloc/search_event.dart';
import 'package:news_app/features/search/presentation/bloc/search_state.dart';

class MockSearchArticlesUseCase extends Mock implements SearchArticlesUseCase {}

void main() {
  late MockSearchArticlesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockSearchArticlesUseCase();
  });

  const tQuery = 'flutter';

  final tArticles = List.generate(
    20,
    (i) => Article(
      id: 'https://example.com/$i',
      title: 'Article $i',
      url: 'https://example.com/$i',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Tech News',
    ),
  );

  final tPage2Articles = [
    Article(
      id: 'https://example.com/20',
      title: 'Page 2 Article',
      url: 'https://example.com/20',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Tech News',
    ),
  ];

  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when search succeeds',
      build: () {
        when(
          () => mockUseCase(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => Right((tArticles, 100)));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(articles: tArticles, totalResults: 100),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchEmpty] when search returns empty list',
      build: () {
        when(
          () => mockUseCase(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => const Right((<Article>[], 0)));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [const SearchLoading(), const SearchEmpty()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchError] when search fails',
      build: () {
        when(
          () => mockUseCase(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => const Left(ServerFailure()));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        const SearchError('Server error. Please try again.'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when query is empty',
      build: () => SearchBloc(searchArticles: mockUseCase),
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      wait: const Duration(milliseconds: 500),
      expect: () => [const SearchInitial()],
      verify: (_) =>
          verifyNever(() => mockUseCase(any(), page: any(named: 'page'))),
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when query is whitespace only',
      build: () => SearchBloc(searchArticles: mockUseCase),
      act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
      wait: const Duration(milliseconds: 500),
      expect: () => [const SearchInitial()],
      verify: (_) =>
          verifyNever(() => mockUseCase(any(), page: any(named: 'page'))),
    );

    blocTest<SearchBloc, SearchState>(
      'sets hasReachedMax when articles.length >= totalResults',
      build: () {
        when(
          () => mockUseCase(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => Right((tArticles, 20)));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(
          articles: tArticles,
          totalResults: 20,
          hasReachedMax: true,
        ),
      ],
    );
  });

  group('SearchLoadMore', () {
    blocTest<SearchBloc, SearchState>(
      'appends next page articles to existing list',
      build: () {
        when(() => mockUseCase(any(), page: any(named: 'page'))).thenAnswer((
          invocation,
        ) async {
          final page = invocation.namedArguments[#page] as int;
          if (page == 1) return Right((tArticles, 100));
          return Right((tPage2Articles, 100));
        });
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) async {
        bloc.add(const SearchQueryChanged(tQuery));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        bloc.add(const SearchLoadMore());
      },
      wait: const Duration(milliseconds: 1200),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(articles: tArticles, totalResults: 100),
        SearchLoaded(
          articles: tArticles,
          totalResults: 100,
          isLoadingMore: true,
        ),
        SearchLoaded(
          articles: [...tArticles, ...tPage2Articles],
          totalResults: 100,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when hasReachedMax is true',
      build: () => SearchBloc(searchArticles: mockUseCase),
      seed: () => SearchLoaded(
        articles: tArticles,
        totalResults: 20,
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(const SearchLoadMore()),
      wait: const Duration(milliseconds: 500),
      expect: () => <SearchState>[],
      verify: (_) =>
          verifyNever(() => mockUseCase(any(), page: any(named: 'page'))),
    );

    blocTest<SearchBloc, SearchState>(
      'emits pagination error on failure',
      build: () {
        when(() => mockUseCase(any(), page: any(named: 'page'))).thenAnswer((
          invocation,
        ) async {
          final page = invocation.namedArguments[#page] as int;
          if (page == 1) return Right((tArticles, 100));
          return const Left(ServerFailure());
        });
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) async {
        bloc.add(const SearchQueryChanged(tQuery));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        bloc.add(const SearchLoadMore());
      },
      wait: const Duration(milliseconds: 1200),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(articles: tArticles, totalResults: 100),
        SearchLoaded(
          articles: tArticles,
          totalResults: 100,
          isLoadingMore: true,
        ),
        SearchLoaded(
          articles: tArticles,
          totalResults: 100,
          paginationError: 'Server error. Please try again.',
        ),
      ],
    );
  });

  group('Debounce', () {
    blocTest<SearchBloc, SearchState>(
      'does not call use case immediately',
      build: () {
        when(
          () => mockUseCase(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => Right((tArticles, 100)));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 100),
      expect: () => <SearchState>[],
      verify: (_) =>
          verifyNever(() => mockUseCase(any(), page: any(named: 'page'))),
    );
  });
}
