import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final int todaySessions;
  final int completedSessions;
  final int weeklySessionsCount;

  const DashboardStats({
    required this.totalClients,
    required this.todaySessions,
    required this.completedSessions,
    required this.weeklySessionsCount,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalClients: 0,
        todaySessions: 0,
        completedSessions: 0,
        weeklySessionsCount: 0,
      );
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
      todaySessions: 0,
      completedSessions: 0,
      weeklySessionsCount: 0,
    );
  }

  if (trainerId == null) {
    return DashboardStats(
      totalClients: totalClients,
      todaySessions: 0,
      completedSessions: 0,
      weeklySessionsCount: 0,
    );
  }

  // Query session stats
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(const Duration(days: 7));

  int todaySessions = 0;
  int completedToday = 0;
  int weeklyCompleted = 0;

  try {
    // Today's scheduled sessions
    final todayResponse = await supabase
        .from('sessions')
        .select('id')
        .eq('trainer_id', trainerId)
        .gte('scheduled_at', todayStart.toIso8601String())
        .lt('scheduled_at', todayStart.add(const Duration(days: 1)).toIso8601String());
    todaySessions = (todayResponse as List).length;

    // Completed today
    final completedTodayResponse = await supabase
        .from('sessions')
        .select('id')
        .eq('trainer_id', trainerId)
        .eq('status', 'completed')
        .gte('completed_at', todayStart.toIso8601String());
    completedToday = (completedTodayResponse as List).length;

    // Weekly completed
    final weeklyResponse = await supabase
        .from('sessions')
        .select('id')
        .eq('trainer_id', trainerId)
        .eq('status', 'completed')
        .gte('completed_at', weekStart.toIso8601String());
    weeklyCompleted = (weeklyResponse as List).length;
  } catch (_) {
    // Sessions table might not exist yet
  }

  return DashboardStats(
    totalClients: totalClients,
    todaySessions: todaySessions,
    completedSessions: completedToday,
    weeklySessionsCount: weeklyCompleted,
  );
});

/// Today's sessions provider with real data
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

    // Query today's sessions with client info
    final response = await supabase
        .from('sessions')
        .select('''
          *,
          client:client_id(full_name, avatar_url)
        ''')
        .eq('trainer_id', trainerId)
        .gte('scheduled_at', todayStart.toIso8601String())
        .lt('scheduled_at', todayEnd.toIso8601String())
        .order('scheduled_at', ascending: true);

    return (response as List).map((json) {
      final client = json['client'] as Map<String, dynamic>?;
      final clientName = client?['full_name'] as String? ?? 'Unknown Client';
      final initials = _getInitials(clientName);

      return SessionPreview(
        clientName: clientName,
        clientInitials: initials,
        profilePhotoUrl: client?['avatar_url'] as String?,
        scheduledTime: DateTime.parse(json['scheduled_at'] as String),
        isCompleted: json['status'] == 'completed',
      );
    }).toList();
  } catch (_) {
    // Sessions table might not exist yet
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
  final List<ClientEntity> recentClients;
  final List<CompletedSession> completedSessions;

  const DashboardData({
    required this.stats,
    required this.todaySessions,
    required this.recentClients,
    this.completedSessions = const [],
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
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final stats = await ref.watch(dashboardStatsProvider.future);
  final sessions = await ref.watch(todaySessionsProvider.future);
  final clients = await ref.watch(recentClientsProvider.future);
  final completedSessions = await ref.watch(recentCompletedSessionsProvider.future);

  return DashboardData(
    stats: stats,
    todaySessions: sessions,
    recentClients: clients,
    completedSessions: completedSessions,
  );
});
