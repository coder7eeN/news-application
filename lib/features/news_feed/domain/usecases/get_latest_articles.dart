import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/domain/repositories/i_news_feed_repository.dart';

/// Use case for fetching latest news articles
/// Delegates to [INewsFeedRepository] — single responsibility
class GetLatestArticlesUseCase {
  final INewsFeedRepository repository;

  const GetLatestArticlesUseCase(this.repository);

  Future<Either<Failure, (List<Article>, int)>> call(int page) =>
      repository.getLatestArticles(page);
}
