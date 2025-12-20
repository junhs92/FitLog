import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../widgets/client_activity_feed.dart';

/// Summary of a client's lifestyle data for monitoring
class ClientLifestyleSummary {
  final String clientId;
  final String clientName;
  final String? photoUrl;
  final DateTime date;
  final int? waterMl;
  final int? waterGoal;
  final double? sleepHours;
  final int? mealCount;
  final String? mood;
  final int? steps;
  final bool hasAlert;
  final String? alertMessage;

  const ClientLifestyleSummary({
    required this.clientId,
    required this.clientName,
    this.photoUrl,
    required this.date,
    this.waterMl,
    this.waterGoal,
    this.sleepHours,
    this.mealCount,
    this.mood,
    this.steps,
    this.hasAlert = false,
    this.alertMessage,
  });

  double get waterProgress =>
      (waterMl != null && waterGoal != null && waterGoal! > 0)
          ? (waterMl! / waterGoal!).clamp(0.0, 1.0)
          : 0.0;
}

/// Provider for client lifestyle summaries
final clientLifestyleSummariesProvider = FutureProvider.family<
    List<ClientLifestyleSummary>, String>((ref, trainerId) async {
  final client = Supabase.instance.client;
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  // Get trainer's clients
  final clientsResponse = await client
      .from('trainer_clients')
      .select('client_id, profiles!trainer_clients_client_id_fkey(id, name, photo_url)')
      .eq('trainer_id', trainerId)
      .eq('status', 'active');

  final summaries = <ClientLifestyleSummary>[];

  for (final clientData in clientsResponse as List) {
    final clientId = clientData['client_id'] as String;
    final profile = clientData['profiles'] as Map<String, dynamic>?;

    // Get today's lifestyle data for this client
    final dailyLog = await client
        .from('daily_logs')
        .select()
        .eq('client_id', clientId)
        .eq('date', dateStr)
        .maybeSingle();

    // Determine if there's an alert
    bool hasAlert = false;
    String? alertMessage;

    if (dailyLog != null) {
      // Check for alerts (e.g., poor sleep, low water)
      final sleepHours = (dailyLog['sleep_hours'] as num?)?.toDouble();
      final waterMl = dailyLog['water_ml'] as int?;
      final mealCount = dailyLog['meal_count'] as int?;

      if (sleepHours != null && sleepHours < 6) {
        hasAlert = true;
        alertMessage = '수면 부족 (${sleepHours.toStringAsFixed(1)}시간)';
      } else if (waterMl != null && waterMl < 500 && today.hour > 14) {
        hasAlert = true;
        alertMessage = '수분 섭취 부족';
      } else if (mealCount == 0 && today.hour > 12) {
        hasAlert = true;
        alertMessage = '아직 식사 기록 없음';
      }
    } else if (today.hour > 10) {
      // No log for today
      hasAlert = true;
      alertMessage = '오늘 기록 없음';
    }

    summaries.add(ClientLifestyleSummary(
      clientId: clientId,
      clientName: profile?['name'] as String? ?? 'Client',
      photoUrl: profile?['photo_url'] as String?,
      date: today,
      waterMl: dailyLog?['water_ml'] as int?,
      waterGoal: dailyLog?['water_goal'] as int? ?? 2000,
      sleepHours: (dailyLog?['sleep_hours'] as num?)?.toDouble(),
      mealCount: dailyLog?['meal_count'] as int?,
      mood: dailyLog?['mood'] as String?,
      steps: dailyLog?['steps'] as int?,
      hasAlert: hasAlert,
      alertMessage: alertMessage,
    ));
  }

  // Sort: alerts first, then by name
  summaries.sort((a, b) {
    if (a.hasAlert != b.hasAlert) {
      return a.hasAlert ? -1 : 1;
    }
    return a.clientName.compareTo(b.clientName);
  });

  return summaries;
});

/// Screen for monitoring all clients' lifestyle data
class ClientMonitoringScreen extends ConsumerWidget {
  final String trainerId;

  const ClientMonitoringScreen({
    required this.trainerId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(clientLifestyleSummariesProvider(trainerId));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('클라이언트 모니터링'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientLifestyleSummariesProvider(trainerId));
        },
        child: CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: _SummaryHeader(trainerId: trainerId),
            ),
            // Alert section
            SliverToBoxAdapter(
              child: summariesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summaries) {
                  final alerts = summaries.where((s) => s.hasAlert).toList();
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  return _AlertSection(alerts: alerts);
                },
              ),
            ),
            // Client cards
            summariesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
              data: (summaries) {
                if (summaries.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _ClientLifestyleCard(
                          summary: summaries[index],
                          onTap: () => context.push(
                            '/trainer/clients/${summaries[index].clientId}',
                          ),
                        );
                      },
                      childCount: summaries.length,
                    ),
                  ),
                );
              },
            ),
            // Activity feed section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: ClientActivityFeed(
                  trainerId: trainerId,
                  maxItems: 5,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.neutral400),
            SizedBox(height: AppSpacing.md),
            Text(
              '클라이언트가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends ConsumerWidget {
  final String trainerId;

  const _SummaryHeader({required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(clientLifestyleSummariesProvider(trainerId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: summariesAsync.when(
        loading: () => const SizedBox(height: 80),
        error: (_, __) => const SizedBox(height: 80),
        data: (summaries) {
          final totalClients = summaries.length;
          final alertCount = summaries.where((s) => s.hasAlert).length;
          final activeToday =
              summaries.where((s) => s.mealCount != null || s.waterMl != null).length;

          return Row(
            children: [
              _SummaryItem(
                icon: Icons.people,
                value: totalClients.toString(),
                label: '전체 클라이언트',
              ),
              _SummaryItem(
                icon: Icons.check_circle,
                value: activeToday.toString(),
                label: '오늘 활동',
              ),
              _SummaryItem(
                icon: Icons.warning,
                value: alertCount.toString(),
                label: '주의 필요',
                highlight: alertCount > 0,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: highlight ? AppColors.warning : AppColors.neutralWhite,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.warning : AppColors.neutralWhite,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutralWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final List<ClientLifestyleSummary> alerts;

  const _AlertSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                '주의가 필요한 클라이언트 (${alerts.length}명)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...alerts.take(3).map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.warning)),
                    Text(
                      '${alert.clientName}: ${alert.alertMessage}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )),
          if (alerts.length > 3)
            Text(
              '외 ${alerts.length - 3}명',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientLifestyleCard extends StatelessWidget {
  final ClientLifestyleSummary summary;
  final VoidCallback onTap;

  const _ClientLifestyleCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: summary.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                summary.photoUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              summary.clientName[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                summary.clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (summary.hasAlert) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '주의',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (summary.alertMessage != null)
                            Text(
                              summary.alertMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.neutral400),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Stats row
                Row(
                  children: [
                    _StatItem(
                      emoji: '💧',
                      value: summary.waterMl != null
                          ? '${summary.waterMl}ml'
                          : '-',
                      progress: summary.waterProgress,
                    ),
                    _StatItem(
                      emoji: '😴',
                      value: summary.sleepHours != null
                          ? '${summary.sleepHours!.toStringAsFixed(1)}h'
                          : '-',
                    ),
                    _StatItem(
                      emoji: '🍽️',
                      value: summary.mealCount != null
                          ? '${summary.mealCount}끼'
                          : '-',
                    ),
                    _StatItem(
                      emoji: '😊',
                      value: summary.mood ?? '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final double? progress;

  const _StatItem({
    required this.emoji,
    required this.value,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!,
                backgroundColor: AppColors.neutral200,
                color: progress! >= 0.8 ? AppColors.success : AppColors.primary,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
