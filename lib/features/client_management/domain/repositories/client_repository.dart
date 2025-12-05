import '../../../../shared/models/result.dart';
import '../entities/client_entity.dart';

/// Client repository contract
abstract class ClientRepository {
  /// Get all clients for the current trainer
  Future<Result<List<ClientEntity>>> getClients();

  /// Get a single client by ID
  Future<Result<ClientEntity>> getClientById(String id);

  /// Create a new client
  Future<Result<ClientEntity>> createClient(ClientEntity client);

  /// Update an existing client
  Future<Result<ClientEntity>> updateClient(ClientEntity client);

  /// Delete a client
  Future<Result<void>> deleteClient(String id);

  /// Search clients by name
  Future<Result<List<ClientEntity>>> searchClients(String query);
}
