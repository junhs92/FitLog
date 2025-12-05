import '../../../../shared/models/result.dart';
import '../repositories/client_repository.dart';

/// Delete a client
class DeleteClientUseCase {
  final ClientRepository _repository;

  const DeleteClientUseCase(this._repository);

  Future<Result<void>> call(String id) async {
    return _repository.deleteClient(id);
  }
}
