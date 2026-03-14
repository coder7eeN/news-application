import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/search/domain/usecases/search_articles.dart';
import 'package:news_app/features/search/presentation/bloc/search_event.dart';
import 'package:news_app/features/search/presentation/bloc/search_state.dart';

/// BLoC for search feature
/// Uses restartable() to cancel previous search when new query arrives
/// 400ms debounce prevents excessive API calls during typing
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchArticlesUseCase searchArticles;

  SearchBloc({required this.searchArticles}) : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));

    emit(const SearchLoading());

    final result = await searchArticles(event.query);
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (articles) => emit(
        articles.isEmpty
            ? const SearchEmpty()
            : SearchLoaded(articles: articles),
      ),
    );
  }
}
