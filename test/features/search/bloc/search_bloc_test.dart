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

class MockSearchArticlesUseCase extends Mock
    implements SearchArticlesUseCase {}

void main() {
  late MockSearchArticlesUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockSearchArticlesUseCase();
  });

  const tQuery = 'flutter';

  final tArticles = [
    Article(
      id: 'https://example.com/1',
      title: 'Flutter Article',
      url: 'https://example.com/1',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Tech News',
    ),
    Article(
      id: 'https://example.com/2',
      title: 'Dart Article',
      url: 'https://example.com/2',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Dev Blog',
    ),
  ];

  group('SearchQueryChanged', () {
    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when search succeeds',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tArticles));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        SearchLoaded(articles: tArticles),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchEmpty] when search returns empty list',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right([]));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        const SearchEmpty(),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchError] when search fails',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure()));
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
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when query is whitespace only',
      build: () => SearchBloc(searchArticles: mockUseCase),
      act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
      wait: const Duration(milliseconds: 500),
      expect: () => [const SearchInitial()],
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );
  });

  group('Debounce', () {
    blocTest<SearchBloc, SearchState>(
      'does not call use case immediately',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tArticles));
        return SearchBloc(searchArticles: mockUseCase);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(tQuery)),
      wait: const Duration(milliseconds: 100),
      expect: () => <SearchState>[],
      verify: (_) => verifyNever(() => mockUseCase(any())),
    );
  });
}
