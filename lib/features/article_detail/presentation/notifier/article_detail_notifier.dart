import 'package:flutter/foundation.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_state.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// ValueNotifier for article detail screen
/// Simple 3-state lifecycle: loading → loaded / error
class ArticleDetailNotifier extends ValueNotifier<ArticleDetailState> {
  ArticleDetailNotifier() : super(const ArticleDetailLoading());

  void loadArticle(Article article) {
    value = ArticleDetailLoaded(article: article);
  }

  void setError(String message) {
    value = ArticleDetailError(message);
  }
}
