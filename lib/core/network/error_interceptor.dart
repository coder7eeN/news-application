import 'package:dio/dio.dart';
import 'package:news_app/core/error/exceptions.dart';

/// Interceptor that maps DioException to AppException
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        exception = const TimeoutException();
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        String errorMessage = 'Server error';

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message']?.toString() ?? errorMessage;
        }

        if (statusCode != null && statusCode >= 500) {
          exception = ServerException(errorMessage);
        } else {
          exception = ServerException(
            responseData is Map<String, dynamic>
                ? responseData['message']?.toString() ??
                      'Request failed with status $statusCode'
                : 'Request failed with status $statusCode',
          );
        }
        break;

      case DioExceptionType.connectionError:
        exception = const NetworkException();
        break;

      case DioExceptionType.cancel:
        // Request was cancelled, just pass through
        handler.next(err);
        return;

      default:
        exception = ServerException(err.message ?? 'Unknown error occurred');
    }

    // Reject with our custom exception
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
      ),
    );
  }
}
