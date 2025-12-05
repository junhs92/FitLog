import 'package:dartz/dartz.dart';

/// Type alias for Either with Failure and success type
typedef Result<T> = Either<Failure, T>;

/// Base failure class for error handling
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

/// Server-side failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed']);
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache operation failed']);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

/// Extension for easier Result handling
extension ResultExtension<T> on Result<T> {
  /// Get value or throw
  T getOrThrow() => fold(
        (failure) => throw Exception(failure.message),
        (value) => value,
      );

  /// Get value or default
  T getOrElse(T defaultValue) => fold(
        (_) => defaultValue,
        (value) => value,
      );

  /// Check if is success
  bool get isSuccess => isRight();

  /// Check if is failure
  bool get isFailure => isLeft();
}
