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
    box.put(article.id, ArticleModel.fromEntity(article));
  }

  @override
  void removeBookmark(String articleId) {
    box.delete(articleId);
  }

  @override
  bool isBookmarked(String articleId) {
    return box.containsKey(articleId);
  }
}
