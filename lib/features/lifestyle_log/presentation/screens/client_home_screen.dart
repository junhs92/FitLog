import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../client_management/presentation/widgets/pending_request_banner.dart';
import '../providers/lifestyle_provider.dart';
import '../providers/client_home_provider.dart';
import '../widgets/water_tracker.dart';
import '../widgets/sleep_input.dart';
import '../widgets/mood_selector.dart';

/// Client home screen showing today's summary
class ClientHomeScreen extends ConsumerWidget {
  final String clientId;

  const ClientHomeScreen({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLogState = ref.watch(dailyLogProvider(clientId));
    final log = dailyLogState.log;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dailyLogProvider(clientId).notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pending trainer connection requests
                    const PendingRequestBanner(),
                    // Daily Progress Card
                    _DailyProgressCard(
                      completionScore: log?.completionScore ?? 0,
                      summaryText: log?.summaryText ?? 'Start logging your day!',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: WaterTrackerCompact(
                            summary: log?.waterSummary,
                            onTap: () => context.go('/client/record'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SleepInputCompact(
                            sleep: log?.sleep,
                            onTap: () => context.go('/client/record'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: MoodSelectorCompact(
                            mood: log?.mood,
                            onTap: () => context.go('/client/record'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Meals Summary
                    _MealsSummaryCard(
                      mealCount: log?.mealCount ?? 0,
                      totalCalories: log?.totalCalories,
                      onTap: () => context.go('/client/record'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Trainer Messages Section
                    _SectionHeader(
                      title: 'From Your Trainer',
                      icon: Icons.message,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _TrainerMessageSection(clientId: clientId),
                    const SizedBox(height: AppSpacing.lg),
                    // Upcoming Sessions
                    _SectionHeader(
                      title: 'Upcoming Sessions',
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _UpcomingSessionSection(clientId: clientId),
                    const SizedBox(height: AppSpacing.xl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralWhite,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDate(now),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.neutralWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _DailyProgressCard extends StatelessWidget {
  final int completionScore;
  final String summaryText;

  const _DailyProgressCard({
    required this.completionScore,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: completionScore / 100,
                  backgroundColor: AppColors.neutral200,
                  color: _getProgressColor(completionScore),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '$completionScore%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(completionScore),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summaryText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.neutral500;
  }
}

class _MealsSummaryCard extends StatelessWidget {
  final int mealCount;
  final int? totalCalories;
  final VoidCallback onTap;

  const _MealsSummaryCard({
    required this.mealCount,
    this.totalCalories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Center(
                  child: Text('🍽️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      mealCount == 0
                          ? 'No meals logged'
                          : '$mealCount meal${mealCount > 1 ? 's' : ''} logged',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mealCount > 0
                            ? const Color(0xFF81C784)
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalCalories != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCalories kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF81C784),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral700),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
      ],
    );
  }
}

class _TrainerMessageCard extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final String? trainerName;

  const _TrainerMessageCard({
    required this.message,
    required this.timestamp,
    this.trainerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  trainerName ?? 'Your Trainer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  final DateTime date;
  final String sessionType;

  const _UpcomingSessionCard({
    required this.date,
    required this.sessionType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                Text(
                  _formatSessionDate(date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.neutral400,
          ),
        ],
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Dynamic trainer message section using real data
class _TrainerMessageSection extends ConsumerWidget {
  final String clientId;

  const _TrainerMessageSection({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageAsync = ref.watch(latestTrainerMessageProvider(clientId));

    return messageAsync.when(
      data: (message) {
        if (message == null) {
          return _EmptyStateCard(
            icon: Icons.message_outlined,
            message: 'No messages from your trainer yet',
          );
        }
        return _TrainerMessageCard(
          message: message.message,
          timestamp: message.createdAt,
          trainerName: message.trainerName,
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => _EmptyStateCard(
        icon: Icons.message_outlined,
        message: 'No messages from your trainer yet',
      ),
    );
  }
}

/// Dynamic upcoming session section using real data
class _UpcomingSessionSection extends ConsumerWidget {
  final String clientId;

  const _UpcomingSessionSection({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(nextSessionProvider(clientId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return _EmptyStateCard(
            icon: Icons.calendar_today_outlined,
            message: 'No upcoming sessions scheduled',
          );
        }
        return _UpcomingSessionCard(
          date: session.scheduledAt,
          sessionType: session.sessionType,
        );
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => _EmptyStateCard(
        icon: Icons.calendar_today_outlined,
        message: 'No upcoming sessions scheduled',
      ),
    );
  }
}

/// Empty state card for when no data is available
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.neutral200,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.neutral400),
          const SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder card
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
