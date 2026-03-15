import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/core/network/network_info.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_local_datasource.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_remote_datasource.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/domain/repositories/i_news_feed_repository.dart';

/// Cache-first repository implementation
/// Serves valid cache immediately with background refresh,
/// falls back to stale cache when offline.
class NewsFeedRepositoryImpl implements INewsFeedRepository {
  final NewsFeedRemoteDataSource remoteDataSource;
  final NewsFeedLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const NewsFeedRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, (List<Article>, int)>> getLatestArticles(
    int page,
  ) async {
    // Check local cache
    final cached = localDataSource.getCachedArticles(page);

    if (cached != null && !cached.isExpired) {
      // Valid cache — return immediately, refresh in background
      // totalResults is unknown from cache, use 0 to signal unknown
      unawaited(_refreshInBackground(page));
      return Right((cached.articles, 0));
    }

    // Cache miss or expired — check connectivity
    if (!await networkInfo.isConnected) {
      // Offline — return stale cache if available
      if (cached != null) {
        return Right((cached.articles, 0));
      }
      return const Left(NoInternetFailure());
    }

    // Fetch from remote
    try {
      final (articles, totalResults) = await remoteDataSource.fetchArticles(
        page,
      );
      unawaited(localDataSource.cacheArticles(page, articles));
      return Right((articles, totalResults));
    } on ServerException catch (e) {
      // Fall back to stale cache on remote failure
      if (cached != null) {
        return Right((cached.articles, 0));
      }
      return Left(ServerFailure(e.message));
    } on TimeoutException {
      if (cached != null) {
        return Right((cached.articles, 0));
      }
      return const Left(TimeoutFailure());
    }
  }

  Future<void> _refreshInBackground(int page) async {
    try {
      final (articles, _) = await remoteDataSource.fetchArticles(page);
      await localDataSource.cacheArticles(page, articles);
    } on ServerException {
      // Swallow — background refresh failing is not user-facing
    } on TimeoutException {
      // Swallow
    }
  }
}
