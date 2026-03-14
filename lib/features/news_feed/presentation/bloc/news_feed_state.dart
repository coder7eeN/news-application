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
  final bool hasReachedMax;
  final bool isLoadingMore;

  const NewsFeedLoaded({
    required this.articles,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  NewsFeedLoaded copyWith({
    List<Article>? articles,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return NewsFeedLoaded(
      articles: articles ?? this.articles,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [articles, hasReachedMax, isLoadingMore];
}

class NewsFeedError extends NewsFeedState {
  final String message;

  const NewsFeedError(this.message);

  @override
  List<Object> get props => [message];
}
