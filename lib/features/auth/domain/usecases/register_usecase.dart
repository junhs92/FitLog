import '../../../../shared/models/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Parameters for register use case
class RegisterParams {
  final String email;
  final String password;
  final String name;
  final String role;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });
}

/// Register use case
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Result<UserEntity>> call(RegisterParams params) async {
    return _repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      name: params.name,
      role: params.role,
    );
  }
}
