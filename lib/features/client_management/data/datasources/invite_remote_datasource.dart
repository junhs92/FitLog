import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/invite_code_generator.dart';
import '../../domain/entities/invite_entity.dart';

/// Remote data source for invite operations
abstract class InviteRemoteDataSource {
  /// Create a new invite (trainer only)
  Future<InviteEntity> createInvite({String? clientEmail});

  /// Get invite details by code (for client to view before accepting)
  Future<InviteEntity?> getInviteByCode(String code);

  /// Accept an invite (client only)
  Future<void> acceptInvite(String code);

  /// Cancel/revoke an invite (trainer only)
  Future<void> cancelInvite(String inviteId);

  /// List all pending invites for current trainer
  Future<List<InviteEntity>> listPendingInvites();
}

/// Implementation using Supabase
class InviteRemoteDataSourceImpl implements InviteRemoteDataSource {
  final SupabaseClient _client;

  InviteRemoteDataSourceImpl(this._client);

  /// Get current user's account ID
  Future<String> _getMyAccountId() async {
    final result = await _client.rpc('get_my_account_id');
    return result as String;
  }

  /// Select statement for invite data with trainer join
  static const String _inviteSelect = '''
    id,
    trainer_id,
    client_id,
    invitation_code,
    status,
    created_at,
    expires_at,
    invitation_accepted_at,
    trainer:trainer_id(full_name, avatar_url)
  ''';

  @override
  Future<InviteEntity> createInvite({String? clientEmail}) async {
    final trainerId = await _getMyAccountId();
    final code = InviteCodeGenerator.generate();
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    // Create the invite record
    final response = await _client
        .from('trainer_client_relationships')
        .insert({
          'trainer_id': trainerId,
          'invitation_code': code,
          'status': 'pending',
          'invited_by': trainerId,
          'invitation_sent_at': DateTime.now().toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
          if (clientEmail != null) 'client_email': clientEmail,
        })
        .select(_inviteSelect)
        .single();

    return InviteEntity.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<InviteEntity?> getInviteByCode(String code) async {
    final normalizedCode = InviteCodeGenerator.normalize(code);

    try {
      final response = await _client
          .from('trainer_client_relationships')
          .select(_inviteSelect)
          .eq('invitation_code', normalizedCode)
          .eq('status', 'pending')
          .maybeSingle();

      if (response == null) return null;
      return InviteEntity.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> acceptInvite(String code) async {
    final normalizedCode = InviteCodeGenerator.normalize(code);
    final clientId = await _getMyAccountId();

    // Find the invite
    final invite = await getInviteByCode(normalizedCode);
    if (invite == null) {
      throw Exception('Invite not found or already used');
    }

    if (invite.isExpired) {
      throw Exception('This invite has expired');
    }

    // Update the relationship to active
    await _client
        .from('trainer_client_relationships')
        .update({
          'client_id': clientId,
          'status': 'active',
          'invitation_accepted_at': DateTime.now().toIso8601String(),
          'relationship_started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invite.id);
  }

  @override
  Future<void> cancelInvite(String inviteId) async {
    final trainerId = await _getMyAccountId();

    await _client
        .from('trainer_client_relationships')
        .delete()
        .eq('id', inviteId)
        .eq('trainer_id', trainerId)
        .eq('status', 'pending');
  }

  @override
  Future<List<InviteEntity>> listPendingInvites() async {
    final trainerId = await _getMyAccountId();

    final response = await _client
        .from('trainer_client_relationships')
        .select(_inviteSelect)
        .eq('trainer_id', trainerId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InviteEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
