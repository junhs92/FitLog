import '../../../../shared/models/result.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

/// Get a single client by ID
class GetClientUseCase {
  final ClientRepository _repository;

  const GetClientUseCase(this._repository);

  Future<Result<ClientEntity>> call(String id) async {
    return _repository.getClientById(id);
  }
}
