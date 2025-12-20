import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../active_session/presentation/widgets/program_selection_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../client_management/domain/entities/client_entity.dart';
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
              onGenerateProgram: () {
                // Show client selection dialog for program generation
                _showClientSelectionForProgram(context, ref, data.recentClients);
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
            const SizedBox(height: AppSpacing.lg),

            // Recent completed sessions for reports
            if (data.completedSessions.isNotEmpty)
              _buildRecentSessionsCard(context, data.completedSessions),
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
    List<ClientEntity> recentClients,
  ) {
    if (recentClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a client first to start a session'),
        ),
      );
      return;
    }

    final trainerIdAsync = ref.read(trainerIdProvider);
    final trainerId = trainerIdAsync.valueOrNull ?? '';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '클라이언트 선택',
              style: Theme.of(ctx).textTheme.titleLarge,
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    // Show program selection sheet
                    ProgramSelectionSheet.show(
                      context: context,
                      clientId: client.id,
                      clientName: client.name,
                      trainerId: trainerId,
                    );
                  },
                )),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/trainer/clients');
              },
              child: const Text('전체 클라이언트 보기'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientSelectionForProgram(
    BuildContext context,
    WidgetRef ref,
    List<ClientEntity> recentClients,
  ) {
    if (recentClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a client first to generate a program'),
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
              'Generate AI Program for',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ...recentClients.map((client) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info.withValues(alpha: 0.1),
                    child: Text(
                      client.initials,
                      style: const TextStyle(color: AppColors.info),
                    ),
                  ),
                  title: Text(client.name),
                  subtitle: client.goals.isNotEmpty
                      ? Text(client.goalsText)
                      : null,
                  trailing: const Icon(Icons.auto_awesome, color: AppColors.info),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/trainer/program/generate/${client.id}?name=${Uri.encodeComponent(client.name)}');
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

  Widget _buildRecentSessionsCard(
    BuildContext context,
    List<CompletedSession> sessions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(Icons.history, color: AppColors.neutral700, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...sessions.take(3).map((session) => _buildSessionTile(context, session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, CompletedSession session) {
    final timeAgo = _getTimeAgo(session.completedAt);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.success.withValues(alpha: 0.1),
        child: Text(
          session.clientInitials,
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        session.clientName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(
          color: AppColors.neutral700,
          fontSize: 12,
        ),
      ),
      trailing: TextButton.icon(
        onPressed: () {
          context.push('/trainer/report/${session.id}');
        },
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: const Text('Report'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.info,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
