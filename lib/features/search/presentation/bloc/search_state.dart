import 'package:equatable/equatable.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Base class for all search states
abstract class SearchState extends Equatable {
  const SearchState();
}

/// Initial state — empty search bar
class SearchInitial extends SearchState {
  const SearchInitial();

  @override
  List<Object> get props => [];
}

/// Loading state — spinner (first page only)
class SearchLoading extends SearchState {
  const SearchLoading();

  @override
  List<Object> get props => [];
}

/// Loaded state — results list with pagination support
class SearchLoaded extends SearchState {
  final List<Article> articles;
  final int totalResults;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? paginationError;

  const SearchLoaded({
    required this.articles,
    this.totalResults = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.paginationError,
  });

  SearchLoaded copyWith({
    List<Article>? articles,
    int? totalResults,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? paginationError,
  }) {
    return SearchLoaded(
      articles: articles ?? this.articles,
      totalResults: totalResults ?? this.totalResults,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError,
    );
  }

  @override
  List<Object?> get props => [
        articles,
        totalResults,
        hasReachedMax,
        isLoadingMore,
        paginationError,
      ];
}

/// Empty state — no results found
class SearchEmpty extends SearchState {
  const SearchEmpty();

  @override
  List<Object> get props => [];
}

/// Error state — error message
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}
