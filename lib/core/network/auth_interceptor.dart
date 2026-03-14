import 'package:dio/dio.dart';

/// Interceptor that injects API key into every request
class AuthInterceptor extends Interceptor {
  static const key = '4cfadfeec04444f281ca8cfb55f32bd7';
  static const _apiKey = String.fromEnvironment(key);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject API key into query parameters
    options.queryParameters['apiKey'] = _apiKey;
    handler.next(options);
  }
}
