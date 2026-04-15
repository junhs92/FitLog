import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/trainer_home_provider.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(
              child: Text(
                DateFormat('MMM d, EEE').format(DateTime.now().toLocal()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
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

            // Today's progress
            _buildTodayProgress(context, data.stats),
            const SizedBox(height: AppSpacing.lg),

            // Today's schedule
            TodaySessionsCard(
              sessions: data.todaySessions,
              onViewAll: () {
                context.go(Routes.trainerCalendar);
              },
              onSessionTap: (session) {
                context.push('/trainer/clients/${session.clientId}');
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
      height: 120,
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
              title: 'Active Clients',
              value: stats.activeClients.toString(),
              icon: Icons.person_pin_circle,
              iconColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(BuildContext context, DashboardStats stats) {
    final completed = stats.completedSessions;
    final total = stats.todaySessions;
    final remaining = stats.remainingSessions;
    final noShows = stats.noShows;
    // No-shows also count as deducted sessions (they consume client package sessions)
    final deducted = completed + noShows;
    final progress = total > 0 ? deducted / total : 0.0;

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
                  "Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    '$deducted / $total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  deducted == total && total > 0
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Completed: $completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral700,
                          ),
                    ),
                  ],
                ),
                if (noShows > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'No-show: $noShows',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Remaining: $remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().toLocal().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
