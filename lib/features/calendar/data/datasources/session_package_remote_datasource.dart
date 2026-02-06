import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_package_model.dart';

/// Remote data source for session package operations via Supabase
class SessionPackageRemoteDataSource {
  final SupabaseClient _client;

  SessionPackageRemoteDataSource(this._client);

  /// Get all packages for a client
  Future<List<SessionPackageModel>> getClientPackages({
    required String trainerId,
    required String clientId,
    bool activeOnly = true,
  }) async {
    var query = _client
        .from('session_packages')
        .select()
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('purchased_at', ascending: true);

    return (response as List)
        .map((json) => SessionPackageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get active package for a client (oldest non-expired, non-depleted)
  Future<SessionPackageModel?> getActivePackage({
    required String trainerId,
    required String clientId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('session_packages')
        .select()
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .eq('is_active', true)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('purchased_at', ascending: true);

    final packages = (response as List)
        .map((json) => SessionPackageModel.fromJson(json as Map<String, dynamic>))
        .where((p) => p.sessionsRemaining > 0)
        .toList();

    return packages.isNotEmpty ? packages.first : null;
  }

  /// Create a new session package
  Future<SessionPackageModel> createPackage({
    required String trainerId,
    required String clientId,
    required String packageName,
    required int totalSessions,
    double? price,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final response = await _client
        .from('session_packages')
        .insert({
          'trainer_id': trainerId,
          'client_id': clientId,
          'package_name': packageName,
          'total_sessions': totalSessions,
          if (price != null) 'price': price,
          if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();

    return SessionPackageModel.fromJson(response);
  }

  /// Deduct a session from a package
  Future<SessionPackageModel> deductSession(String packageId) async {
    // First get current sessions_used
    final current = await _client
        .from('session_packages')
        .select('sessions_used')
        .eq('id', packageId)
        .single();

    final currentUsed = current['sessions_used'] as int;

    // Update with incremented value
    final response = await _client
        .from('session_packages')
        .update({'sessions_used': currentUsed + 1})
        .eq('id', packageId)
        .select()
        .single();

    return SessionPackageModel.fromJson(response);
  }

  /// Update package details
  Future<SessionPackageModel> updatePackage({
    required String packageId,
    String? packageName,
    int? totalSessions,
    double? price,
    DateTime? expiresAt,
    bool? isActive,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{};
    if (packageName != null) updateData['package_name'] = packageName;
    if (totalSessions != null) updateData['total_sessions'] = totalSessions;
    if (price != null) updateData['price'] = price;
    if (expiresAt != null) {
      updateData['expires_at'] = expiresAt.toUtc().toIso8601String();
    }
    if (isActive != null) updateData['is_active'] = isActive;
    if (notes != null) updateData['notes'] = notes;

    final response = await _client
        .from('session_packages')
        .update(updateData)
        .eq('id', packageId)
        .select()
        .single();

    return SessionPackageModel.fromJson(response);
  }

  /// Get total remaining sessions for a client
  Future<int> getTotalRemainingSessions({
    required String trainerId,
    required String clientId,
  }) async {
    final packages = await getClientPackages(
      trainerId: trainerId,
      clientId: clientId,
      activeOnly: true,
    );

    return packages
        .where((p) => !p.isExpired && !p.isDepleted)
        .fold<int>(0, (sum, p) => sum + p.sessionsRemaining);
  }
}
