import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/timestamp_utils.dart';
import '../models/schedule_entry_model.dart';

/// Remote data source for schedule operations via Supabase
class ScheduleRemoteDataSource {
  final SupabaseClient _client;

  ScheduleRemoteDataSource(this._client);

  /// Select query with client join
  static const String _selectQuery = '''
    id, trainer_id, client_id, scheduled_at, duration_minutes,
    status, notes, created_at,
    accounts!client_schedules_client_id_fkey(full_name, avatar_url)
  ''';

  /// Fetch schedules for a date range
  Future<List<ScheduleEntryModel>> getSchedulesForRange({
    required String trainerId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
    List<String>? statuses,
  }) async {
    var query = _client
        .from('client_schedules')
        .select(_selectQuery)
        .eq('trainer_id', trainerId)
        .gte('scheduled_at', toLocalIso8601(startDate))
        .lte('scheduled_at', toLocalIso8601(endDate));

    if (clientIds != null && clientIds.isNotEmpty) {
      query = query.inFilter('client_id', clientIds);
    }

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }

    final response = await query.order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => ScheduleEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new schedule
  Future<ScheduleEntryModel> createSchedule({
    required String trainerId,
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  }) async {
    final response = await _client
        .from('client_schedules')
        .insert({
          'trainer_id': trainerId,
          'client_id': clientId,
          'scheduled_at': toLocalIso8601(scheduledAt),
          'duration_minutes': durationMinutes,
          'notes': notes,
        })
        .select(_selectQuery)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Update a schedule
  Future<ScheduleEntryModel> updateSchedule({
    required String scheduleId,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? status,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{};
    if (scheduledAt != null) {
      updateData['scheduled_at'] = toLocalIso8601(scheduledAt);
    }
    if (durationMinutes != null) {
      updateData['duration_minutes'] = durationMinutes;
    }
    if (status != null) {
      updateData['status'] = status;
    }
    if (notes != null) {
      updateData['notes'] = notes;
    }

    final response = await _client
        .from('client_schedules')
        .update(updateData)
        .eq('id', scheduleId)
        .select(_selectQuery)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Update schedule status
  Future<ScheduleEntryModel> updateStatus({
    required String scheduleId,
    required String status,
  }) async {
    final response = await _client
        .from('client_schedules')
        .update({'status': status})
        .eq('id', scheduleId)
        .select(_selectQuery)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('client_schedules').delete().eq('id', scheduleId);
  }

  /// Get schedule by ID
  Future<ScheduleEntryModel> getScheduleById(String scheduleId) async {
    final response = await _client
        .from('client_schedules')
        .select(_selectQuery)
        .eq('id', scheduleId)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Check if a schedule already exists for a client at a specific time
  Future<bool> hasConflictingSchedule({
    required String trainerId,
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  }) async {
    // Check for overlapping schedules
    final startTime = scheduledAt;
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));

    // Get schedules that might overlap (within a reasonable window)
    final windowStart = startTime.subtract(const Duration(hours: 3));
    final windowEnd = endTime.add(const Duration(hours: 3));

    var query = _client
        .from('client_schedules')
        .select('id, scheduled_at, duration_minutes')
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .neq('status', 'cancelled')
        .gte('scheduled_at', toLocalIso8601(windowStart))
        .lte('scheduled_at', toLocalIso8601(windowEnd));

    if (excludeScheduleId != null) {
      query = query.neq('id', excludeScheduleId);
    }

    final response = await query;

    // Check for actual time overlap
    for (final row in response as List) {
      final existingStart = DateTime.parse(row['scheduled_at'] as String);
      final existingDuration = row['duration_minutes'] as int;
      final existingEnd = existingStart.add(Duration(minutes: existingDuration));

      // Check if times overlap
      if (startTime.isBefore(existingEnd) && endTime.isAfter(existingStart)) {
        return true;
      }
    }

    return false;
  }

  /// Check if trainer has ANY schedule (any client) at a specific time
  /// Returns the conflicting client name if found, null otherwise
  Future<String?> getTrainerScheduleConflict({
    required String trainerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  }) async {
    // Check for overlapping schedules across ALL clients
    final startTime = scheduledAt;
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));

    // Get schedules that might overlap (within a reasonable window)
    final windowStart = startTime.subtract(const Duration(hours: 3));
    final windowEnd = endTime.add(const Duration(hours: 3));

    var query = _client
        .from('client_schedules')
        .select('id, scheduled_at, duration_minutes, accounts!client_schedules_client_id_fkey(full_name)')
        .eq('trainer_id', trainerId)
        .neq('status', 'cancelled')
        .gte('scheduled_at', toLocalIso8601(windowStart))
        .lte('scheduled_at', toLocalIso8601(windowEnd));

    if (excludeScheduleId != null) {
      query = query.neq('id', excludeScheduleId);
    }

    final response = await query;

    // Check for actual time overlap
    for (final row in response as List) {
      final existingStart = DateTime.parse(row['scheduled_at'] as String);
      final existingDuration = row['duration_minutes'] as int;
      final existingEnd = existingStart.add(Duration(minutes: existingDuration));

      // Check if times overlap
      if (startTime.isBefore(existingEnd) && endTime.isAfter(existingStart)) {
        // Return the conflicting client's name
        final accounts = row['accounts'] as Map<String, dynamic>?;
        return accounts?['full_name'] as String? ?? '다른 회원';
      }
    }

    return null;
  }

  /// Get overdue scheduled appointments (20+ minutes past their time)
  /// These are appointments still marked as "scheduled" but past due
  Future<List<ScheduleEntryModel>> getOverdueScheduledAppointments({
    required String trainerId,
  }) async {
    // Get appointments that are 20+ minutes past their scheduled time
    // and still have status = 'scheduled'
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 20));

    final response = await _client
        .from('client_schedules')
        .select(_selectQuery)
        .eq('trainer_id', trainerId)
        .eq('status', 'scheduled')
        .lt('scheduled_at', toLocalIso8601(cutoffTime))
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => ScheduleEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Find a schedule that matches a session's client and time (within tolerance)
  /// Used for auto-completing schedules when sessions are completed
  Future<ScheduleEntryModel?> findScheduleForSession({
    required String trainerId,
    required String clientId,
    required DateTime sessionStartTime,
    int toleranceMinutes = 30,
  }) async {
    final startWindow = sessionStartTime.subtract(Duration(minutes: toleranceMinutes));
    final endWindow = sessionStartTime.add(Duration(minutes: toleranceMinutes));

    final response = await _client
        .from('client_schedules')
        .select(_selectQuery)
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .eq('status', 'scheduled')
        .gte('scheduled_at', toLocalIso8601(startWindow))
        .lte('scheduled_at', toLocalIso8601(endWindow))
        .order('scheduled_at', ascending: true)
        .limit(1);

    final responseList = response as List;
    if (responseList.isEmpty) return null;
    return ScheduleEntryModel.fromJson(responseList.first as Map<String, dynamic>);
  }

  /// Get schedule counts by day for a month
  Future<Map<DateTime, int>> getScheduleCountsByDay({
    required String trainerId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
  }) async {
    var query = _client
        .from('client_schedules')
        .select('scheduled_at')
        .eq('trainer_id', trainerId)
        .gte('scheduled_at', toLocalIso8601(startDate))
        .lte('scheduled_at', toLocalIso8601(endDate));

    if (clientIds != null && clientIds.isNotEmpty) {
      query = query.inFilter('client_id', clientIds);
    }

    final response = await query;

    final counts = <DateTime, int>{};
    for (final row in response as List) {
      final scheduledAt = DateTime.parse(row['scheduled_at'] as String).toLocal();
      final dayKey = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
      counts[dayKey] = (counts[dayKey] ?? 0) + 1;
    }

    return counts;
  }
}
