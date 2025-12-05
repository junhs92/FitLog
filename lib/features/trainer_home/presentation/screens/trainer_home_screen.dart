import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/trainer_home_provider.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/recent_clients_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/today_sessions_card.dart';

/// Trainer dashboard home screen
class TrainerHomeScreen extends ConsumerWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final authState = ref.watch(authStateProvider);

    final userName = authState.valueOrNull?.displayName ?? 'Trainer';
    final firstName = userName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
            Text(
              firstName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => _buildDashboard(context, ref, data),
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardData data,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            _buildStatsRow(context, data.stats),
            const SizedBox(height: AppSpacing.lg),

            // Quick actions
            QuickActionsCard(
              onStartSession: () {
                // Show client selection dialog for session
                _showClientSelectionForSession(context, ref, data.recentClients);
              },
              onAddClient: () {
                context.push('/trainer/clients/add');
              },
              onViewClients: () {
                context.go('/trainer/clients');
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today's sessions
            TodaySessionsCard(
              sessions: data.todaySessions,
              onViewAll: () {
                // TODO: Navigate to session history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session history coming soon')),
                );
              },
              onSessionTap: (session) {
                // TODO: Navigate to session detail
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent clients
            RecentClientsCard(
              clients: data.recentClients,
              onViewAll: () {
                context.go('/trainer/clients');
              },
              onClientTap: (client) {
                context.push('/trainer/clients/${client.id}');
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, DashboardStats stats) {
    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total Clients',
              value: stats.totalClients.toString(),
              icon: Icons.people,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: 'Today',
              value: '${stats.completedSessions}/${stats.todaySessions}',
              icon: Icons.today,
              iconColor: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: 'This Week',
              value: stats.weeklySessionsCount.toString(),
              icon: Icons.calendar_month,
              iconColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientSelectionForSession(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> recentClients,
  ) {
    if (recentClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a client first to start a session'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Client for Session',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ...recentClients.map((client) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      client.initials,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(client.name),
                  subtitle: client.goals.isNotEmpty
                      ? Text(client.goalsText)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/trainer/session/${client.id}');
                  },
                )),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/trainer/clients');
              },
              child: const Text('View All Clients'),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
