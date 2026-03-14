import 'package:news_app/core/cache/cache_constants.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';

/// Wrapper for cached feed data with TTL tracking.
/// NOT a HiveType — articles and timestamp are stored as separate Hive keys.
class CachedFeed {
  final List<ArticleModel> articles;
  final DateTime cachedAt;

  const CachedFeed({required this.articles, required this.cachedAt});

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > CacheConstants.feedTtl;
}
