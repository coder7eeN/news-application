import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:news_app/core/network/dio_client.dart';
import 'package:news_app/core/network/network_info.dart';
import 'package:news_app/features/news_feed/data/datasources/news_feed_remote_datasource.dart';
import 'package:news_app/features/news_feed/data/repositories/news_feed_repository_impl.dart';
import 'package:news_app/features/news_feed/domain/repositories/i_news_feed_repository.dart';
import 'package:news_app/features/news_feed/domain/usecases/get_latest_articles.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:news_app/features/search/data/datasources/search_remote_datasource.dart';
import 'package:news_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:news_app/features/search/domain/repositories/i_search_repository.dart';
import 'package:news_app/features/search/domain/usecases/search_articles.dart';
import 'package:news_app/features/search/presentation/bloc/search_bloc.dart';

/// GetIt service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// Call this in main.dart before runApp()
Future<void> init() async {
  // =========================================================================
  // BLoCs — factory (new instance per widget tree injection)
  // =========================================================================
  sl.registerFactory(() => NewsFeedBloc(getLatestArticles: sl()));
  sl.registerFactory(() => SearchBloc(searchArticles: sl()));

  // =========================================================================
  // Use Cases — lazy singleton
  // =========================================================================
  sl.registerLazySingleton(() => GetLatestArticlesUseCase(sl()));
  sl.registerLazySingleton(() => SearchArticlesUseCase(sl()));

  // =========================================================================
  // Repositories — lazy singleton, registered as interface
  // =========================================================================
  sl.registerLazySingleton<INewsFeedRepository>(
    () => NewsFeedRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ISearchRepository>(
    () => SearchRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // =========================================================================
  // Data Sources — lazy singleton
  // =========================================================================
  sl.registerLazySingleton<NewsFeedRemoteDataSource>(
    () => NewsFeedRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(dio: sl()),
  );

  // =========================================================================
  // Core
  // =========================================================================
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton<Dio>(() => DioClient.create());
  sl.registerLazySingleton(() => Connectivity());
}
