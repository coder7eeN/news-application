import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:news_app/core/network/auth_interceptor.dart';
import 'package:news_app/core/network/error_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Factory class for creating configured Dio instance
class DioClient {
  /// Creates a Dio instance with base configuration and interceptors
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://newsapi.org/v2',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Add interceptors in order
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: true,
        ),
    ]);

    return dio;
  }
}
