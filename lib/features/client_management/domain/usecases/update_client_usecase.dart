import '../../../../shared/models/result.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

/// Update an existing client
class UpdateClientUseCase {
  final ClientRepository _repository;

  const UpdateClientUseCase(this._repository);

  Future<Result<ClientEntity>> call(ClientEntity client) async {
    final updatedClient = client.copyWith(
      updatedAt: DateTime.now(),
    );
    return _repository.updateClient(updatedClient);
  }
}
