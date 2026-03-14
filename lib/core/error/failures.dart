import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Used for error handling in domain and presentation layers
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure when server returns an error (5xx or other server issues)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// Failure when there is no internet connection
class NoInternetFailure extends Failure {
  const NoInternetFailure([super.message = 'No internet connection.']);
}

/// Failure when request times out
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out.']);
}

/// Failure when cache operation fails
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not load cached data.']);
}
