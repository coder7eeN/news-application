import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/search/domain/repositories/i_search_repository.dart';

/// Use case for searching news articles by keyword
class SearchArticlesUseCase {
  final ISearchRepository repository;

  const SearchArticlesUseCase(this.repository);

  Future<Either<Failure, (List<Article>, int)>> call(
    String query, {
    int page = 1,
  }) => repository.searchArticles(query, page);
}
