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

  const NewsFeedLoaded({required this.articles, this.hasReachedMax = false});

  @override
  List<Object> get props => [articles, hasReachedMax];
}

class NewsFeedError extends NewsFeedState {
  final String message;

  const NewsFeedError(this.message);

  @override
  List<Object> get props => [message];
}
