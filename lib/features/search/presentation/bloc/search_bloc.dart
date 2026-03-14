import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/search/domain/usecases/search_articles.dart';
import 'package:news_app/features/search/presentation/bloc/search_event.dart';
import 'package:news_app/features/search/presentation/bloc/search_state.dart';

/// BLoC for search feature with pagination
/// Uses restartable() to cancel previous search when new query arrives
/// Uses droppable() for load more to prevent duplicate page fetches
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchArticlesUseCase searchArticles;
  int _currentPage = 1;
  String _currentQuery = '';

  SearchBloc({required this.searchArticles}) : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<SearchLoadMore>(_onLoadMore, transformer: droppable());
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      _currentQuery = '';
      _currentPage = 1;
      emit(const SearchInitial());
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _currentQuery = event.query;
    _currentPage = 1;
    emit(const SearchLoading());

    final result = await searchArticles(_currentQuery);
    result.fold((failure) => emit(SearchError(failure.message)), (data) {
      final (articles, totalResults) = data;
      if (articles.isEmpty) {
        emit(const SearchEmpty());
      } else {
        _currentPage = 2;
        emit(
          SearchLoaded(
            articles: articles,
            totalResults: totalResults,
            hasReachedMax: articles.length >= totalResults,
          ),
        );
      }
    });
  }

  Future<void> _onLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await searchArticles(_currentQuery, page: _currentPage);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          isLoadingMore: false,
          paginationError: failure.message,
        ),
      ),
      (data) {
        final (newArticles, totalResults) = data;
        final allArticles = [...currentState.articles, ...newArticles];
        _currentPage++;
        emit(
          SearchLoaded(
            articles: allArticles,
            totalResults: totalResults,
            hasReachedMax: allArticles.length >= totalResults,
          ),
        );
      },
    );
  }
}
