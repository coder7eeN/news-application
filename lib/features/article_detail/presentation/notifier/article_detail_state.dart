import 'package:equatable/equatable.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Base class for article detail states
sealed class ArticleDetailState extends Equatable {
  const ArticleDetailState();
}

/// Initial loading state
class ArticleDetailLoading extends ArticleDetailState {
  const ArticleDetailLoading();

  @override
  List<Object> get props => [];
}

/// Article loaded successfully
class ArticleDetailLoaded extends ArticleDetailState {
  final Article article;

  const ArticleDetailLoaded({required this.article});

  @override
  List<Object> get props => [article];
}

/// Error loading article
class ArticleDetailError extends ArticleDetailState {
  final String message;

  const ArticleDetailError(this.message);

  @override
  List<Object> get props => [message];
}
