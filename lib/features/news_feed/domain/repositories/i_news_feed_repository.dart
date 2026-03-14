import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Repository interface for news feed operations
/// Implemented by data layer, used by use cases in domain layer
abstract class INewsFeedRepository {
  /// Fetch latest articles for a given page
  Future<Either<Failure, List<Article>>> getLatestArticles(int page);

  /// Search articles by query keyword
  Future<Either<Failure, List<Article>>> searchArticles(String query);
}
