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
/// Queries trainer_client_relationships joined with accounts table
class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final SupabaseClient _client;

  ClientRemoteDataSourceImpl(this._client);

  /// Get current user's account ID using the helper function
  Future<String> _getMyAccountId() async {
    final result = await _client.rpc('get_my_account_id');
    return result as String;
  }

  /// Select statement for client data with accounts join
  static const String _clientSelect = '''
    id,
    trainer_id,
    trainer_notes,
    client:accounts!trainer_client_relationships_client_id_fkey(
      id,
      full_name,
      email,
      phone,
      date_of_birth,
      gender,
      height_cm,
      weight_kg,
      fitness_goals,
      avatar_url,
      created_at,
      updated_at
    )
  ''';

  @override
  Future<List<ClientModel>> getClients() async {
    final trainerAccountId = await _getMyAccountId();

    final response = await _client
        .from('trainer_client_relationships')
        .select(_clientSelect)
        .eq('trainer_id', trainerAccountId)
        .eq('status', 'active');

    return (response as List).map((json) => ClientModel.fromJson(json)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    final trainerAccountId = await _getMyAccountId();

    final response = await _client
        .from('trainer_client_relationships')
        .select(_clientSelect)
        .eq('trainer_id', trainerAccountId)
        .eq('client_id', id)
        .eq('status', 'active')
        .single();

    return ClientModel.fromJson(response);
  }

  @override
  Future<ClientModel> createClient(ClientModel client) async {
    // Creating a client means creating a relationship with an existing account
    // The client account must already exist (they sign up themselves)
    // This method creates the trainer-client relationship
    final trainerAccountId = await _getMyAccountId();

    if (client.email == null || client.email!.isEmpty) {
      throw Exception('Client email is required to create a relationship');
    }

    // First, find the client account by email
    final clientAccount = await _client
        .from('accounts')
        .select('id')
        .eq('email', client.email!)
        .single();

    // Create the relationship
    final relationshipResponse = await _client
        .from('trainer_client_relationships')
        .insert({
          'trainer_id': trainerAccountId,
          'client_id': clientAccount['id'],
          'status': 'active',
          'trainer_notes': client.notes,
        })
        .select(_clientSelect)
        .single();

    return ClientModel.fromJson(relationshipResponse);
  }

  @override
  Future<ClientModel> updateClient(ClientModel client) async {
    final trainerAccountId = await _getMyAccountId();

    // Update trainer notes in relationship table
    await _client
        .from('trainer_client_relationships')
        .update(client.toRelationshipUpdateJson())
        .eq('trainer_id', trainerAccountId)
        .eq('client_id', client.id);

    // Fetch updated data
    return getClientById(client.id);
  }

  @override
  Future<void> deleteClient(String id) async {
    final trainerAccountId = await _getMyAccountId();

    // End the relationship (don't delete the client account)
    await _client.from('trainer_client_relationships').update({
      'status': 'ended',
      'relationship_ended_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('trainer_id', trainerAccountId).eq('client_id', id);
  }

  @override
  Future<List<ClientModel>> searchClients(String query) async {
    final trainerAccountId = await _getMyAccountId();

    // Get all active relationships first
    final response = await _client
        .from('trainer_client_relationships')
        .select(_clientSelect)
        .eq('trainer_id', trainerAccountId)
        .eq('status', 'active');

    // Filter by name client-side (Supabase doesn't support filtering on joined tables directly)
    final clients = (response as List)
        .map((json) => ClientModel.fromJson(json))
        .where((client) =>
            client.name.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return clients;
  }
}
