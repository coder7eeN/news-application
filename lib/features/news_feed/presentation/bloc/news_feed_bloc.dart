import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/cache/cache_constants.dart';
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
    emit(const NewsFeedLoading());
    final result = await getLatestArticles(1);
    result.fold(
      (failure) => emit(NewsFeedError(failure.message)),
      (articles) {
        _currentPage = 2;
        emit(NewsFeedLoaded(
          articles: articles,
          hasReachedMax: articles.length < CacheConstants.pageSize,
        ));
      },
    );
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
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (newArticles) {
        _currentPage++;
        emit(NewsFeedLoaded(
          articles: [...currentState.articles, ...newArticles],
          hasReachedMax: newArticles.length < CacheConstants.pageSize,
        ));
      },
    );
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<NewsFeedState> emit,
  ) async {
    _currentPage = 1;
    emit(const NewsFeedLoading());
    final result = await getLatestArticles(1);
    result.fold(
      (failure) => emit(NewsFeedError(failure.message)),
      (articles) {
        _currentPage = 2;
        emit(NewsFeedLoaded(
          articles: articles,
          hasReachedMax: articles.length < CacheConstants.pageSize,
        ));
      },
    );
  }
}
