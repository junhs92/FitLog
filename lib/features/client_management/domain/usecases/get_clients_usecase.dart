import '../../../../shared/models/result.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

/// Get all clients for the current trainer
class GetClientsUseCase {
  final ClientRepository _repository;

  const GetClientsUseCase(this._repository);

  Future<Result<List<ClientEntity>>> call() async {
    return _repository.getClients();
  }
}
