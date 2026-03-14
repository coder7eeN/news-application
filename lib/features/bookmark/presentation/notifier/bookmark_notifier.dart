import 'package:flutter/foundation.dart';
import 'package:news_app/features/bookmark/data/datasources/bookmark_local_datasource.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// ChangeNotifier for bookmark state management.
/// Maintains an in-memory list backed by BookmarkLocalDataSource.
class BookmarkNotifier extends ChangeNotifier {
  final BookmarkLocalDataSource _localDataSource;
  List<Article> _bookmarks = [];

  BookmarkNotifier({required BookmarkLocalDataSource localDataSource})
      : _localDataSource = localDataSource {
    loadBookmarks();
  }

  List<Article> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(String articleId) =>
      _localDataSource.isBookmarked(articleId);

  void loadBookmarks() {
    _bookmarks = _localDataSource.getAllBookmarks();
    notifyListeners();
  }

  void toggleBookmark(Article article) {
    if (isBookmarked(article.id)) {
      _localDataSource.removeBookmark(article.id);
    } else {
      _localDataSource.saveBookmark(article);
    }
    _bookmarks = _localDataSource.getAllBookmarks();
    notifyListeners();
  }
}
