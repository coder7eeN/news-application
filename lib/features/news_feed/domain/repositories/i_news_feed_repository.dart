import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Repository interface for news feed operations
/// Implemented by data layer, used by use cases in domain layer
abstract class INewsFeedRepository {
  /// Fetch latest articles for a given page
  /// Returns (articles, totalResults)
  Future<Either<Failure, (List<Article>, int)>> getLatestArticles(int page);
}
