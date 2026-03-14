import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:news_app/core/network/dio_client.dart';
import 'package:news_app/core/network/network_info.dart';

/// GetIt service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
/// Call this in main.dart before runApp()
Future<void> init() async {
  // =========================================================================
  // BLoCs — factory (new instance per widget tree injection)
  // =========================================================================
  // Feature BLoCs will be registered here in later tasks

  // =========================================================================
  // Use Cases — lazy singleton
  // =========================================================================
  // Feature use cases will be registered here in later tasks

  // =========================================================================
  // Repositories — lazy singleton, registered as interface
  // =========================================================================
  // Feature repositories will be registered here in later tasks

  // =========================================================================
  // Data Sources — lazy singleton
  // =========================================================================
  // Feature data sources will be registered here in later tasks

  // =========================================================================
  // Core
  // =========================================================================
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton<Dio>(() => DioClient.create());
  sl.registerLazySingleton(() => Connectivity());
}
