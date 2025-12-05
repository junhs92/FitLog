import '../../../../shared/models/result.dart';
import '../repositories/auth_repository.dart';

/// Logout use case
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Result<void>> call() async {
    return _repository.signOut();
  }
}
