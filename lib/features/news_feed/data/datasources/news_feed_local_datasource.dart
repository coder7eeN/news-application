import 'package:hive_ce/hive.dart';
import 'package:news_app/core/cache/cache_constants.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';
import 'package:news_app/features/news_feed/data/models/cached_feed.dart';

/// Abstract interface for local news feed cache operations
abstract class NewsFeedLocalDataSource {
  /// Returns cached feed for the given page, or null if not cached.
  CachedFeed? getCachedArticles(int page);

  /// Caches articles for the given page with current timestamp.
  Future<void> cacheArticles(int page, List<ArticleModel> articles);

  /// Clears all cached feed data.
  Future<void> clearCache();
}

/// Implementation using Hive box for local storage
class NewsFeedLocalDataSourceImpl implements NewsFeedLocalDataSource {
  final Box<dynamic> box;

  const NewsFeedLocalDataSourceImpl({required this.box});

  @override
  CachedFeed? getCachedArticles(int page) {
    try {
      final key = CacheConstants.feedCacheKey(page);
      final raw = box.get(key);
      final timestamp = box.get('${key}_timestamp');
      if (raw == null || timestamp == null) return null;

      final articles = (raw as List<dynamic>).cast<ArticleModel>();
      return CachedFeed(
        articles: articles,
        cachedAt: timestamp as DateTime,
      );
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> cacheArticles(int page, List<ArticleModel> articles) async {
    if (page > CacheConstants.maxCachedPages) return;

    final key = CacheConstants.feedCacheKey(page);
    await box.put(key, articles);
    await box.put('${key}_timestamp', DateTime.now());
  }

  @override
  Future<void> clearCache() async {
    await box.clear();
  }
}
