import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/connection_request_entity.dart';

/// Data source for connection request operations
class ConnectionRequestDataSource {
  final SupabaseClient _client;

  ConnectionRequestDataSource(this._client);

  /// Get current user's account ID
  Future<String?> _getCurrentAccountId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .single();

    return response['id'] as String?;
  }

  /// Search for clients that trainer can send requests to
  /// Returns clients NOT already connected to ANY trainer
  Future<List<Map<String, dynamic>>> searchAvailableClients(String query) async {
    final trainerId = await _getCurrentAccountId();
    if (trainerId == null) throw Exception('Not authenticated');

    // Get all accounts - we'll filter in Dart for reliability
    final response = await _client
        .from('accounts')
        .select('id, full_name, email, avatar_url, role')
        .limit(100);

    print('DEBUG: Found ${(response as List).length} total accounts');
    for (var acc in response) {
      print('DEBUG: Account - id: ${acc['id']}, name: ${acc['full_name']}, role: ${acc['role']}');
    }

    // Get clients who already have ANY trainer connection (active status)
    List<dynamic> connectedClients = [];
    try {
      connectedClients = await _client
          .from('trainer_client_relationships')
          .select('client_id')
          .eq('status', 'active')
          .not('client_id', 'is', null);  // Only where client_id is not null
      print('DEBUG: Found ${connectedClients.length} existing trainer-client connections');
      for (var c in connectedClients) {
        print('DEBUG: Connected client_id: ${c['client_id']}');
      }
    } catch (e) {
      print('DEBUG: trainer_client_relationships query error: $e');
    }

    // Get clients with pending requests from THIS trainer (for UI indicator, not exclusion)
    Set<String> pendingRequestClientIds = {};
    try {
      final pendingRequests = await _client
          .from('connection_requests')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .eq('status', 'pending');
      pendingRequestClientIds = (pendingRequests as List)
          .map((e) => e['client_id'] as String)
          .toSet();
      print('DEBUG: Found ${pendingRequestClientIds.length} pending requests from this trainer');
    } catch (e) {
      print('DEBUG: connection_requests query error: $e');
    }

    // Only exclude already-connected clients and self (NOT pending requests)
    final excludeIds = <String>{
      ...connectedClients.map((e) => e['client_id'] as String),
      trainerId, // Exclude self
    };

    print('DEBUG: Excluding ${excludeIds.length} IDs');

    // Filter results in Dart for reliability
    final results = <Map<String, dynamic>>[];

    for (final client in response) {
      final id = client['id'] as String;
      final role = client['role'] as String?;
      final name = client['full_name'] as String? ?? '';

      print('DEBUG: Checking $name (id: $id, role: $role)');

      // Must not be excluded (already connected or pending)
      if (excludeIds.contains(id)) {
        print('DEBUG: EXCLUDED $name - already connected/pending (id in excludeIds)');
        continue;
      }

      // Must be client or both role (can connect with clients)
      if (role != 'client' && role != 'both') {
        print('DEBUG: EXCLUDED $name - wrong role: "$role" (need "client" or "both")');
        continue;
      }

      // If query provided, must match name or email
      if (query.isNotEmpty) {
        final nameLower = name.toLowerCase();
        final email = (client['email'] as String? ?? '').toLowerCase();
        final q = query.toLowerCase();
        if (!nameLower.contains(q) && !email.contains(q)) {
          print('DEBUG: EXCLUDED $name - does not match search query');
          continue;
        }
      }

      print('DEBUG: INCLUDED $name - passed all filters');
      final clientMap = Map<String, dynamic>.from(client as Map);
      // Add flag to indicate if request is already pending
      clientMap['has_pending_request'] = pendingRequestClientIds.contains(id);
      results.add(clientMap);
    }

    print('DEBUG: Final result count: ${results.length}');
    return results;
  }

  /// Send connection request from trainer to client
  Future<ConnectionRequestEntity> sendRequest(String clientId) async {
    final trainerId = await _getCurrentAccountId();
    if (trainerId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('connection_requests')
        .insert({
          'trainer_id': trainerId,
          'client_id': clientId,
          'status': 'pending',
        })
        .select('''
          *,
          client:client_id(full_name, email, avatar_url)
        ''')
        .single();

    return _mapToEntity(response);
  }

  /// Get pending requests for current client
  Future<List<ConnectionRequestEntity>> getPendingRequestsForClient() async {
    final clientId = await _getCurrentAccountId();
    if (clientId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('connection_requests')
        .select('''
          *,
          trainer:trainer_id(full_name, email, avatar_url)
        ''')
        .eq('client_id', clientId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    print('DEBUG getPendingRequestsForClient: $response');
    for (var r in (response as List)) {
      print('DEBUG: trainer data = ${r['trainer']}');
    }

    return response.map((e) => _mapToEntityWithTrainer(e)).toList();
  }

  /// Get sent requests by trainer
  Future<List<ConnectionRequestEntity>> getSentRequestsByTrainer() async {
    final trainerId = await _getCurrentAccountId();
    if (trainerId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('connection_requests')
        .select('''
          *,
          client:client_id(full_name, email, avatar_url)
        ''')
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => _mapToEntity(e)).toList();
  }

  /// Accept a connection request (as client)
  Future<void> acceptRequest(String requestId) async {
    final clientId = await _getCurrentAccountId();
    if (clientId == null) throw Exception('Not authenticated');

    // Get the request first
    final request = await _client
        .from('connection_requests')
        .select()
        .eq('id', requestId)
        .eq('client_id', clientId)
        .single();

    final trainerId = request['trainer_id'] as String;

    // Update request status
    await _client
        .from('connection_requests')
        .update({
          'status': 'approved',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);

    print('DEBUG: Request status updated to approved');

    // Get client email for the relationship record
    String? clientEmail;
    try {
      final clientAccount = await _client
          .from('accounts')
          .select('email')
          .eq('id', clientId)
          .single();
      clientEmail = clientAccount['email'] as String?;
    } catch (_) {}

    // Create or update trainer_client_relationships entry
    // Use upsert to handle reconnecting with previously ended relationships
    final now = DateTime.now().toIso8601String();
    final invitationSentAt = request['created_at'] as String?;

    try {
      await _client.from('trainer_client_relationships').upsert(
        {
          'trainer_id': trainerId,
          'client_id': clientId,
          'status': 'active',
          'invited_by': trainerId,
          'invitation_sent_at': invitationSentAt,
          'invitation_accepted_at': now,
          'relationship_started_at': now,
          'relationship_ended_at': null,
          'end_reason': null,
          'client_email': clientEmail,
          'updated_at': now,
        },
        onConflict: 'trainer_id,client_id',
      );
      print('DEBUG: trainer_client_relationships upserted successfully');
    } catch (e) {
      print('DEBUG: Failed to upsert trainer_client_relationships: $e');
      rethrow;
    }
  }

  /// Reject a connection request (as client)
  Future<void> rejectRequest(String requestId) async {
    final clientId = await _getCurrentAccountId();
    if (clientId == null) throw Exception('Not authenticated');

    await _client
        .from('connection_requests')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('client_id', clientId);
  }

  /// Cancel a pending request (as trainer)
  Future<void> cancelRequest(String requestId) async {
    final trainerId = await _getCurrentAccountId();
    if (trainerId == null) throw Exception('Not authenticated');

    await _client
        .from('connection_requests')
        .delete()
        .eq('id', requestId)
        .eq('trainer_id', trainerId)
        .eq('status', 'pending');
  }

  /// Cancel a pending request by client ID (as trainer)
  Future<void> cancelRequestByClientId(String clientId) async {
    final trainerId = await _getCurrentAccountId();
    if (trainerId == null) throw Exception('Not authenticated');

    await _client
        .from('connection_requests')
        .delete()
        .eq('client_id', clientId)
        .eq('trainer_id', trainerId)
        .eq('status', 'pending');
  }

  ConnectionRequestEntity _mapToEntity(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;

    return ConnectionRequestEntity(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      status: ConnectionRequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      clientName: client?['full_name'] as String?,
      clientEmail: client?['email'] as String?,
      clientAvatarUrl: client?['avatar_url'] as String?,
    );
  }

  ConnectionRequestEntity _mapToEntityWithTrainer(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;

    return ConnectionRequestEntity(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      status: ConnectionRequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      trainerName: trainer?['full_name'] as String?,
      trainerEmail: trainer?['email'] as String?,
      trainerAvatarUrl: trainer?['avatar_url'] as String?,
    );
  }
}
