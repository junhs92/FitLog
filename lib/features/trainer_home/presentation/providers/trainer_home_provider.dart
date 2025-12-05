import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../client_management/domain/entities/client_entity.dart';
import '../../../client_management/presentation/providers/client_provider.dart';
import '../widgets/today_sessions_card.dart';

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
  // Get clients count from existing provider
  final clientsAsync = await ref.watch(clientsProvider.future);
  final totalClients = clientsAsync.length;

  // TODO: Replace with real session data when active_session feature is built
  // For now, return mock stats based on client count
  return DashboardStats(
    totalClients: totalClients,
    todaySessions: 0, // Will be populated from sessions
    completedSessions: 0,
    weeklySessionsCount: 0,
  );
});

/// Today's sessions provider (mock for now)
final todaySessionsProvider = FutureProvider.autoDispose<List<SessionPreview>>((ref) async {
  // TODO: Replace with real session data when active_session feature is built
  // For now, return empty list
  return [];
});

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

  const DashboardData({
    required this.stats,
    required this.todaySessions,
    required this.recentClients,
  });
}

/// Combined dashboard provider
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final stats = await ref.watch(dashboardStatsProvider.future);
  final sessions = await ref.watch(todaySessionsProvider.future);
  final clients = await ref.watch(recentClientsProvider.future);

  return DashboardData(
    stats: stats,
    todaySessions: sessions,
    recentClients: clients,
  );
});
