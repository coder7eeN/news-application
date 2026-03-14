import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/news_feed/domain/usecases/get_latest_articles.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_state.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  final GetLatestArticlesUseCase getLatestArticles;

  NewsFeedBloc({required this.getLatestArticles})
    : super(const NewsFeedInitial()) {
    on<FetchLatestArticles>(_onFetchLatestArticles);
  }

  Future<void> _onFetchLatestArticles(
    FetchLatestArticles event,
    Emitter<NewsFeedState> emit,
  ) async {
    emit(const NewsFeedLoading());
    final result = await getLatestArticles(1);
    result.fold(
      (failure) => emit(NewsFeedError(failure.message)),
      (articles) => emit(NewsFeedLoaded(articles: articles)),
    );
  }
}
