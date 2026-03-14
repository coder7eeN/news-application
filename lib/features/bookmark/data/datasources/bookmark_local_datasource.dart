import 'package:hive_ce/hive.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Abstract interface for bookmark persistence operations
abstract class BookmarkLocalDataSource {
  List<Article> getAllBookmarks();
  void saveBookmark(Article article);
  void removeBookmark(String articleId);
  bool isBookmarked(String articleId);
}

/// Hive-backed implementation keyed by article ID (URL)
class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  final Box<dynamic> box;

  const BookmarkLocalDataSourceImpl({required this.box});

  @override
  List<Article> getAllBookmarks() {
    return box.values
        .whereType<ArticleModel>()
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  @override
  void saveBookmark(Article article) {
    final model = _toModel(article);
    box.put(article.id, model);
  }

  @override
  void removeBookmark(String articleId) {
    box.delete(articleId);
  }

  @override
  bool isBookmarked(String articleId) {
    return box.containsKey(articleId);
  }

  ArticleModel _toModel(Article article) {
    if (article is ArticleModel) return article;
    return ArticleModel(
      id: article.id,
      title: article.title,
      description: article.description,
      urlToImage: article.urlToImage,
      url: article.url,
      content: article.content,
      publishedAt: article.publishedAt,
      sourceName: article.sourceName,
      author: article.author,
    );
  }
}
