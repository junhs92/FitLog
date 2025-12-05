import 'package:dartz/dartz.dart';

import '../../../../shared/models/result.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';
import '../models/client_model.dart';

/// Implementation of ClientRepository
class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource _remoteDataSource;

  ClientRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ClientEntity>>> getClients() async {
    try {
      final clients = await _remoteDataSource.getClients();
      return Right(clients.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ClientEntity>> getClientById(String id) async {
    try {
      final client = await _remoteDataSource.getClientById(id);
      return Right(client.toEntity());
    } catch (e) {
      if (e.toString().contains('Row not found')) {
        return const Left(NotFoundFailure('Client not found'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ClientEntity>> createClient(ClientEntity client) async {
    try {
      final model = ClientModel.fromEntity(client);
      final created = await _remoteDataSource.createClient(model);
      return Right(created.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ClientEntity>> updateClient(ClientEntity client) async {
    try {
      final model = ClientModel.fromEntity(client);
      final updated = await _remoteDataSource.updateClient(model);
      return Right(updated.toEntity());
    } catch (e) {
      if (e.toString().contains('Row not found')) {
        return const Left(NotFoundFailure('Client not found'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteClient(String id) async {
    try {
      await _remoteDataSource.deleteClient(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ClientEntity>>> searchClients(String query) async {
    try {
      final clients = await _remoteDataSource.searchClients(query);
      return Right(clients.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
