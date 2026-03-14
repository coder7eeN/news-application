import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Repository interface for search operations
abstract class ISearchRepository {
  Future<Either<Failure, List<Article>>> searchArticles(String query);
}
