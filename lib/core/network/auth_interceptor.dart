import 'package:dio/dio.dart';

/// Interceptor that injects API key into every request
class AuthInterceptor extends Interceptor {
  static const _apiKey = String.fromEnvironment('NEWS_API_KEY');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject API key into query parameters
    options.queryParameters['apiKey'] = _apiKey;
    handler.next(options);
  }
}
