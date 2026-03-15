import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news_feed/domain/usecases/get_latest_articles.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_state.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  final GetLatestArticlesUseCase getLatestArticles;
  int _currentPage = 1;

  NewsFeedBloc({required this.getLatestArticles})
    : super(const NewsFeedInitial()) {
    on<FetchLatestArticles>(_onFetchLatestArticles);
    on<FetchNextPage>(_onFetchNextPage, transformer: droppable());
    on<RefreshFeed>(_onRefreshFeed, transformer: droppable());
  }

  Future<void> _onFetchLatestArticles(
    FetchLatestArticles event,
    Emitter<NewsFeedState> emit,
  ) async {
    await _fetchFirstPage(emit);
  }

  Future<void> _onFetchNextPage(
    FetchNextPage event,
    Emitter<NewsFeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NewsFeedLoaded || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));
    final result = await getLatestArticles(_currentPage);
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
          NewsFeedLoaded(
            articles: allArticles,
            totalResults: totalResults,
            hasReachedMax: totalResults > 0
                ? allArticles.length >= totalResults
                : allArticles.length == currentState.articles.length,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<NewsFeedState> emit,
  ) async {
    _currentPage = 1;
    await _fetchFirstPage(emit);
  }

  Future<void> _fetchFirstPage(Emitter<NewsFeedState> emit) async {
    emit(const NewsFeedLoading());
    final result = await getLatestArticles(1);
    result.fold(
      (failure) => emit(NewsFeedError(failure.message)),
      (data) {
        final (articles, totalResults) = data;
        _currentPage = 2;
        emit(
          NewsFeedLoaded(
            articles: articles,
            totalResults: totalResults,
            hasReachedMax: totalResults > 0
                ? articles.length >= totalResults
                : false,
          ),
        );
      },
    );
  }
}
