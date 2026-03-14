import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/network/network_info.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/search/data/datasources/search_remote_datasource.dart';
import 'package:news_app/features/search/domain/repositories/i_search_repository.dart';

/// Remote-only repository implementation for search
/// Search results are NEVER cached
class SearchRepositoryImpl implements ISearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Article>>> searchArticles(String query) async {
    if (!await networkInfo.isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final articles = await remoteDataSource.searchArticles(query);
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on DioException catch (_) {
      rethrow;
    }
  }
}
