import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/network/network_info.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_remote_datasource.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/domain/repositories/i_news_feed_repository.dart';

/// Remote-only repository implementation for US-03
/// Cache-first logic with LocalDataSource will be added in US-05
class NewsFeedRepositoryImpl implements INewsFeedRepository {
  final NewsFeedRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const NewsFeedRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Article>>> getLatestArticles(int page) async {
    if (!await networkInfo.isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final articles = await remoteDataSource.fetchArticles(page);
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    }
  }

  @override
  Future<Either<Failure, List<Article>>> searchArticles(String query) async {
    if (!await networkInfo.isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      // Search uses the same remote datasource for now
      // A dedicated search datasource will be added in the search feature
      final articles = await remoteDataSource.fetchArticles(1);
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    }
  }
}
