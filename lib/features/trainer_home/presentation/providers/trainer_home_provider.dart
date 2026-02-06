import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/timestamp_utils.dart';
import '../../../client_management/domain/entities/client_entity.dart';
import '../../../client_management/presentation/providers/client_provider.dart';
import '../widgets/today_sessions_card.dart';

/// Provider for current trainer's account ID
final trainerIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    final accountResponse = await supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .single();
    return accountResponse['id'] as String?;
  } catch (_) {
    return null;
  }
});

/// Dashboard stats data
class DashboardStats {
  final int totalClients;
  final int activeClients;
  final int todaySessions;
  final int completedSessions;
  final int noShows;

  const DashboardStats({
    required this.totalClients,
    required this.activeClients,
    required this.todaySessions,
    required this.completedSessions,
    this.noShows = 0,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalClients: 0,
        activeClients: 0,
        todaySessions: 0,
        completedSessions: 0,
        noShows: 0,
      );

  int get remainingSessions => todaySessions - completedSessions - noShows;
}

/// Dashboard data provider
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return DashboardStats.empty();
  }

  // Get clients count from existing provider
  final clientsAsync = await ref.watch(clientsProvider.future);
  final totalClients = clientsAsync.length;

  // Get trainer's account id
  String? trainerId;
  try {
    final accountResponse = await supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .single();
    trainerId = accountResponse['id'] as String?;
  } catch (_) {
    return DashboardStats(
      totalClients: totalClients,
      activeClients: 0,
      todaySessions: 0,
      completedSessions: 0,
    );
  }

  if (trainerId == null) {
    return DashboardStats(
      totalClients: totalClients,
      activeClients: 0,
      todaySessions: 0,
      completedSessions: 0,
    );
  }

  // Query active clients (clients with remaining sessions in active packages)
  int activeClients = 0;
  try {
    final packagesResponse = await supabase
        .from('session_packages')
        .select('client_id, total_sessions, sessions_used')
        .eq('trainer_id', trainerId)
        .eq('is_active', true);

    final packages = packagesResponse as List;
    final activeClientIds = <String>{};
    for (final pkg in packages) {
      final total = pkg['total_sessions'] as int? ?? 0;
      final used = pkg['sessions_used'] as int? ?? 0;
      if (total > used) {
        activeClientIds.add(pkg['client_id'] as String);
      }
    }
    activeClients = activeClientIds.length;
  } catch (_) {
    // session_packages table might not exist yet
  }

  // Query schedule stats from client_schedules table (calendar appointments)
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  int todaySessions = 0;
  int completedToday = 0;

  try {
    // Today's scheduled appointments (exclude cancelled)
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayResponse = await supabase
        .from('client_schedules')
        .select('id')
        .eq('trainer_id', trainerId)
        .neq('status', 'cancelled')
        .gte('scheduled_at', toLocalIso8601(todayStart))
        .lt('scheduled_at', toLocalIso8601(todayEnd));
    todaySessions = (todayResponse as List).length;

    // Completed appointments today
    final completedTodayResponse = await supabase
        .from('client_schedules')
        .select('id')
        .eq('trainer_id', trainerId)
        .eq('status', 'completed')
        .gte('scheduled_at', toLocalIso8601(todayStart))
        .lt('scheduled_at', toLocalIso8601(todayEnd));
    completedToday = (completedTodayResponse as List).length;
  } catch (_) {
    // client_schedules table might not exist yet
  }

  return DashboardStats(
    totalClients: totalClients,
    activeClients: activeClients,
    todaySessions: todaySessions,
    completedSessions: completedToday,
  );
});

/// Today's scheduled appointments provider (from client_schedules table)
/// This shows trainer's planned appointments for the day from the calendar
final todaySessionsProvider = FutureProvider.autoDispose<List<SessionPreview>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  try {
    // Get trainer's account id
    final accountResponse = await supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .single();
    final trainerId = accountResponse['id'] as String?;

    if (trainerId == null) return [];

    // Get today's date range
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Query today's scheduled appointments with client info (exclude cancelled)
    final response = await supabase
        .from('client_schedules')
        .select('''
          id, client_id, scheduled_at, status,
          accounts!client_schedules_client_id_fkey(full_name, avatar_url)
        ''')
        .eq('trainer_id', trainerId)
        .neq('status', 'cancelled')
        .gte('scheduled_at', toLocalIso8601(todayStart))
        .lt('scheduled_at', toLocalIso8601(todayEnd))
        .order('scheduled_at', ascending: true);

    return (response as List).map((json) {
      final client = json['accounts'] as Map<String, dynamic>?;
      final clientId = json['client_id'] as String;
      final clientName = client?['full_name'] as String? ?? 'Unknown Client';
      final initials = _getInitials(clientName);
      final status = json['status'] as String?;

      return SessionPreview(
        clientId: clientId,
        clientName: clientName,
        clientInitials: initials,
        profilePhotoUrl: client?['avatar_url'] as String?,
        scheduledTime: DateTime.parse(json['scheduled_at'] as String),
        isCompleted: status == 'completed',
        isNoShow: status == 'no_show',
      );
    }).toList();
  } catch (_) {
    // client_schedules table might not exist yet
    return [];
  }
});

/// Helper to get initials from name
String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return '${parts[0].substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

/// Recent clients provider
final recentClientsProvider = FutureProvider.autoDispose<List<ClientEntity>>((ref) async {
  final clients = await ref.watch(clientsProvider.future);

  // Sort by most recently created and take top 5
  final sorted = List<ClientEntity>.from(clients)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return sorted.take(5).toList();
});

/// Combined dashboard data for single loading state
class DashboardData {
  final DashboardStats stats;
  final List<SessionPreview> todaySessions;

  const DashboardData({
    required this.stats,
    required this.todaySessions,
  });
}

/// Recent completed session for reports
class CompletedSession {
  final String id;
  final String clientName;
  final String clientInitials;
  final DateTime completedAt;
  final int exerciseCount;
  final int duration; // in minutes

  const CompletedSession({
    required this.id,
    required this.clientName,
    required this.clientInitials,
    required this.completedAt,
    required this.exerciseCount,
    required this.duration,
  });
}

/// Recent completed sessions provider
final recentCompletedSessionsProvider = FutureProvider.autoDispose<List<CompletedSession>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  try {
    // Get trainer's account id
    final accountResponse = await supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .single();
    final trainerId = accountResponse['id'] as String?;

    if (trainerId == null) return [];

    // Get recent completed sessions (last 5)
    final response = await supabase
        .from('sessions')
        .select('''
          id,
          completed_at,
          duration_seconds,
          client:client_id(full_name)
        ''')
        .eq('trainer_id', trainerId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .limit(5);

    return (response as List).map((json) {
      final client = json['client'] as Map<String, dynamic>?;
      final clientName = client?['full_name'] as String? ?? 'Unknown Client';
      final initials = _getInitials(clientName);
      final durationSeconds = json['duration_seconds'] as int? ?? 0;

      return CompletedSession(
        id: json['id'] as String,
        clientName: clientName,
        clientInitials: initials,
        completedAt: DateTime.parse(json['completed_at'] as String),
        exerciseCount: 0, // Could be fetched separately if needed
        duration: (durationSeconds / 60).round(), // Convert seconds to minutes
      );
    }).toList();
  } catch (_) {
    // Sessions table might not exist yet
    return [];
  }
});

/// Combined dashboard provider
/// Derives today's session stats from todaySessionsProvider for consistency
/// This ensures "Today's Progress" matches "Today's Schedule" exactly
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final stats = await ref.watch(dashboardStatsProvider.future);
  final sessions = await ref.watch(todaySessionsProvider.future);

  // Override today session stats with actual session list data for consistency
  final todayTotal = sessions.length;
  final todayCompleted = sessions.where((s) => s.isCompleted).length;
  final todayNoShows = sessions.where((s) => s.isNoShow).length;

  final correctedStats = DashboardStats(
    totalClients: stats.totalClients,
    activeClients: stats.activeClients,
    todaySessions: todayTotal,
    completedSessions: todayCompleted,
    noShows: todayNoShows,
  );

  return DashboardData(
    stats: correctedStats,
    todaySessions: sessions,
  );
});
