/// Cache configuration constants
class CacheConstants {
  const CacheConstants._();

  /// Box name for articles feed cache
  static const String feedBoxName = 'articles_cache';

  /// Box name for user bookmarks
  static const String bookmarksBoxName = 'bookmarks';

  /// Time-to-live for cached feed data
  static const Duration feedTtl = Duration(minutes: 15);

  /// Maximum number of pages to cache
  static const int maxCachedPages = 5;

  /// Generate cache key for a specific page
  static String feedCacheKey(int page) => 'feed_page_$page';
}
