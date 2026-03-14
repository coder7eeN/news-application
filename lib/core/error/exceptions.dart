/// Base class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when server returns 5xx error
class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred']);
}

/// Thrown when request times out
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}

/// Thrown when there is no internet connection
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Thrown when cache operation fails
class CacheException extends AppException {
  const CacheException([super.message = 'Cache operation failed']);
}
