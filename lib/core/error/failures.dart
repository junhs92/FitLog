import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failure
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Network failure (no connection)
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found', super.code});
}

/// Permission denied failure
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied', super.code});
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unknown error occurred', super.code});
}
