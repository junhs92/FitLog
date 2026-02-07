import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/timestamp_utils.dart';

/// Entity for trainer message
class TrainerMessage {
  final String id;
  final String trainerId;
  final String trainerName;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const TrainerMessage({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory TrainerMessage.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;
    return TrainerMessage(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      trainerName: trainer?['full_name'] as String? ?? 'Your Trainer',
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Entity for upcoming scheduled session (from client_schedules table)
class UpcomingSession {
  final String id;
  final String trainerId;
  final String trainerName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String? notes;

  const UpcomingSession({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.notes,
  });

  factory UpcomingSession.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;
    return UpcomingSession(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      trainerName: trainer?['full_name'] as String? ?? 'Trainer',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  /// Display text for session type (based on duration or notes)
  String get sessionType {
    if (notes != null && notes!.isNotEmpty) {
      return notes!;
    }
    return 'PT Session';
  }
}

/// Provider for latest trainer message
final latestTrainerMessageProvider =
    FutureProvider.family<TrainerMessage?, String>((ref, clientId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('trainer_messages')
        .select('''
          *,
          trainer:trainer_id(full_name)
        ''')
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return TrainerMessage.fromJson(response);
  } catch (e) {
    // Table might not exist yet, return null
    return null;
  }
});

/// Provider for upcoming sessions from client_schedules table
final upcomingSessionsProvider =
    FutureProvider.family<List<UpcomingSession>, String>((ref, clientId) async {
  final supabase = Supabase.instance.client;

  try {
    final now = nowLocalIso8601();
    final response = await supabase
        .from('client_schedules')
        .select('''
          id,
          trainer_id,
          scheduled_at,
          duration_minutes,
          status,
          notes,
          trainer:trainer_id(full_name)
        ''')
        .eq('client_id', clientId)
        .eq('status', 'scheduled')
        .gte('scheduled_at', now)
        .order('scheduled_at', ascending: true)
        .limit(5);

    return (response as List)
        .map((json) => UpcomingSession.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // Table might not exist yet, return empty list
    return [];
  }
});

/// Provider for next upcoming session (convenience)
final nextSessionProvider =
    FutureProvider.family<UpcomingSession?, String>((ref, clientId) async {
  final sessions = await ref.watch(upcomingSessionsProvider(clientId).future);
  return sessions.isNotEmpty ? sessions.first : null;
});

/// Mark message as read
Future<void> markMessageAsRead(String messageId) async {
  final supabase = Supabase.instance.client;
  await supabase
      .from('trainer_messages')
      .update({'is_read': true})
      .eq('id', messageId);
}
