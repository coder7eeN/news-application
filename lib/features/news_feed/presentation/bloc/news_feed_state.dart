import 'package:equatable/equatable.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

abstract class NewsFeedState extends Equatable {
  const NewsFeedState();
}

class NewsFeedInitial extends NewsFeedState {
  const NewsFeedInitial();

  @override
  List<Object> get props => [];
}

class NewsFeedLoading extends NewsFeedState {
  const NewsFeedLoading();

  @override
  List<Object> get props => [];
}

class NewsFeedLoaded extends NewsFeedState {
  final List<Article> articles;
  final int totalResults;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? paginationError;

  const NewsFeedLoaded({
    required this.articles,
    this.totalResults = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.paginationError,
  });

  NewsFeedLoaded copyWith({
    List<Article>? articles,
    int? totalResults,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? paginationError,
  }) {
    return NewsFeedLoaded(
      articles: articles ?? this.articles,
      totalResults: totalResults ?? this.totalResults,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError,
    );
  }

  @override
  List<Object?> get props =>
      [articles, totalResults, hasReachedMax, isLoadingMore, paginationError];
}

class NewsFeedError extends NewsFeedState {
  final String message;

  const NewsFeedError(this.message);

  @override
  List<Object> get props => [message];
}
