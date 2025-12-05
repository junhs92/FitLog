import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_model.dart';

/// Remote data source for client operations
abstract class ClientRemoteDataSource {
  Future<List<ClientModel>> getClients();
  Future<ClientModel> getClientById(String id);
  Future<ClientModel> createClient(ClientModel client);
  Future<ClientModel> updateClient(ClientModel client);
  Future<void> deleteClient(String id);
  Future<List<ClientModel>> searchClients(String query);
}

/// Implementation using Supabase
class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final SupabaseClient _client;
  static const String _tableName = 'clients';

  ClientRemoteDataSourceImpl(this._client);

  String get _currentUserId => _client.auth.currentUser!.id;

  @override
  Future<List<ClientModel>> getClients() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('trainer_id', _currentUserId)
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ClientModel.fromJson(json))
        .toList();
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('trainer_id', _currentUserId)
        .single();

    return ClientModel.fromJson(response);
  }

  @override
  Future<ClientModel> createClient(ClientModel client) async {
    final data = client.toInsertJson();
    data['trainer_id'] = _currentUserId;

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();

    return ClientModel.fromJson(response);
  }

  @override
  Future<ClientModel> updateClient(ClientModel client) async {
    final response = await _client
        .from(_tableName)
        .update(client.toUpdateJson())
        .eq('id', client.id)
        .eq('trainer_id', _currentUserId)
        .select()
        .single();

    return ClientModel.fromJson(response);
  }

  @override
  Future<void> deleteClient(String id) async {
    await _client
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('trainer_id', _currentUserId);
  }

  @override
  Future<List<ClientModel>> searchClients(String query) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('trainer_id', _currentUserId)
        .ilike('name', '%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((json) => ClientModel.fromJson(json))
        .toList();
  }
}
