import '../../../../shared/models/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Parameters for login use case
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}

/// Login use case
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<Result<UserEntity>> call(LoginParams params) async {
    return _repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
