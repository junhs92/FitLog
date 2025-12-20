import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/water_log_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/mood_log_entity.dart';
import '../providers/lifestyle_provider.dart';

/// Client stats screen showing progress and trends
class ClientStatsScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientStatsScreen({
    required this.clientId,
    super.key,
  });

  @override
  ConsumerState<ClientStatsScreen> createState() => _ClientStatsScreenState();
}

class _ClientStatsScreenState extends ConsumerState<ClientStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateRange = 7; // Last 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _fromDate =>
      DateTime.now().subtract(Duration(days: _dateRange - 1));
  DateTime get _toDate => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Water'),
            Tab(text: 'Sleep'),
            Tab(text: 'Mood'),
            Tab(text: 'Weight'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WaterStatsTab(
            clientId: widget.clientId,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
          _SleepStatsTab(
            clientId: widget.clientId,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
          _MoodStatsTab(
            clientId: widget.clientId,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
          _WeightStatsTab(
            clientId: widget.clientId,
            fromDate: _fromDate,
            toDate: _toDate,
          ),
        ],
      ),
    );
  }
}

/// Water stats tab
class _WaterStatsTab extends ConsumerWidget {
  final String clientId;
  final DateTime fromDate;
  final DateTime toDate;

  const _WaterStatsTab({
    required this.clientId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterHistoryAsync = ref.watch(waterHistoryProvider((
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    )));

    return waterHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) => _buildWaterStats(history),
    );
  }

  Widget _buildWaterStats(List<DailyWaterSummary> history) {
    final totalDays = history.length;
    final daysGoalMet = history.where((h) => h.goalReached).length;
    final avgIntake = totalDays > 0
        ? history.fold(0, (sum, h) => sum + h.totalMl) / totalDays
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatSummaryCard(
                  title: 'Avg. Daily',
                  value: '${(avgIntake / 1000).toStringAsFixed(1)} L',
                  icon: Icons.water_drop,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: 'Goals Met',
                  value: '$daysGoalMet / $totalDays',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Weekly chart
          const Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SimpleBarChart(
            data: history.map((h) => h.totalMl / 1000).toList(),
            labels: history.map((h) => _weekdayLabel(h.date)).toList(),
            maxValue: 3.0,
            color: AppColors.info,
            unit: 'L',
          ),
          const SizedBox(height: AppSpacing.lg),
          // Daily breakdown
          const Text(
            'Daily Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...history.reversed.map((h) => _DailyWaterRow(summary: h)),
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

/// Sleep stats tab
class _SleepStatsTab extends ConsumerWidget {
  final String clientId;
  final DateTime fromDate;
  final DateTime toDate;

  const _SleepStatsTab({
    required this.clientId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepHistoryAsync = ref.watch(sleepHistoryProvider((
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    )));

    return sleepHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) => _buildSleepStats(history),
    );
  }

  Widget _buildSleepStats(List<SleepLogEntity> history) {
    final logsWithDuration = history.where((h) => h.duration != null).toList();
    final totalDays = logsWithDuration.length;
    final avgHours = totalDays > 0
        ? logsWithDuration.fold(
                0.0, (sum, h) => sum + (h.durationHours ?? 0)) /
            totalDays
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatSummaryCard(
                  title: 'Avg. Sleep',
                  value: '${avgHours.toStringAsFixed(1)} hrs',
                  icon: Icons.bedtime,
                  color: const Color(0xFF7C4DFF),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: 'Days Logged',
                  value: '$totalDays',
                  icon: Icons.calendar_today,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Weekly chart
          const Text(
            'Sleep Duration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SimpleBarChart(
            data: logsWithDuration.map((h) => h.durationHours ?? 0).toList(),
            labels: logsWithDuration.map((h) => _weekdayLabel(h.logDate)).toList(),
            maxValue: 10.0,
            color: const Color(0xFF7C4DFF),
            unit: 'hrs',
          ),
          const SizedBox(height: AppSpacing.lg),
          // Quality breakdown
          if (history.any((h) => h.quality != null)) ...[
            const Text(
              'Sleep Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SleepQualityBreakdown(history: history),
          ],
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

/// Mood stats tab
class _MoodStatsTab extends ConsumerWidget {
  final String clientId;
  final DateTime fromDate;
  final DateTime toDate;

  const _MoodStatsTab({
    required this.clientId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodHistoryAsync = ref.watch(moodHistoryProvider((
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    )));

    return moodHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) => _buildMoodStats(history),
    );
  }

  Widget _buildMoodStats(List<MoodLogEntity> history) {
    final logsWithMood = history.where((h) => h.mood != null).toList();
    final avgMood = logsWithMood.isNotEmpty
        ? logsWithMood.fold(0.0, (sum, h) => sum + (h.moodValue ?? 0)) /
            logsWithMood.length
        : 0.0;
    final logsWithEnergy = history.where((h) => h.energy != null).toList();
    final avgEnergy = logsWithEnergy.isNotEmpty
        ? logsWithEnergy.fold(0.0, (sum, h) => sum + (h.energyValue ?? 0)) /
            logsWithEnergy.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatSummaryCard(
                  title: 'Avg. Mood',
                  value: avgMood.toStringAsFixed(1),
                  subtitle: _getMoodLabel(avgMood),
                  icon: Icons.mood,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: 'Avg. Energy',
                  value: avgEnergy.toStringAsFixed(1),
                  subtitle: _getEnergyLabel(avgEnergy),
                  icon: Icons.bolt,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Mood trend
          const Text(
            'Mood Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MoodTrendChart(history: logsWithMood),
          const SizedBox(height: AppSpacing.lg),
          // Energy trend
          const Text(
            'Energy Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _EnergyTrendChart(history: logsWithEnergy),
        ],
      ),
    );
  }

  String _getMoodLabel(double value) {
    if (value >= 4.5) return 'Excellent';
    if (value >= 3.5) return 'Good';
    if (value >= 2.5) return 'Neutral';
    if (value >= 1.5) return 'Low';
    return 'Very Low';
  }

  String _getEnergyLabel(double value) {
    if (value >= 4.5) return 'Very High';
    if (value >= 3.5) return 'Energetic';
    if (value >= 2.5) return 'Normal';
    if (value >= 1.5) return 'Tired';
    return 'Exhausted';
  }
}

/// Weight stats tab
class _WeightStatsTab extends ConsumerWidget {
  final String clientId;
  final DateTime fromDate;
  final DateTime toDate;

  const _WeightStatsTab({
    required this.clientId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extend range for weight to show more history
    final extendedFromDate = DateTime.now().subtract(const Duration(days: 30));

    final weightHistoryAsync = ref.watch(weightHistoryProvider((
      clientId: clientId,
      fromDate: extendedFromDate,
      toDate: toDate,
    )));

    return weightHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) => _buildWeightStats(history),
    );
  }

  Widget _buildWeightStats(List<({DateTime date, double weight})> history) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No weight data yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Start logging your weight to see trends',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    final latestWeight = history.last.weight;
    final firstWeight = history.first.weight;
    final change = latestWeight - firstWeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weight card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${latestWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                if (history.length > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: change < 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : change > 0
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.neutral200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change < 0
                              ? Icons.trending_down
                              : change > 0
                                  ? Icons.trending_up
                                  : Icons.trending_flat,
                          size: 16,
                          color: change < 0
                              ? AppColors.success
                              : change > 0
                                  ? AppColors.error
                                  : AppColors.neutral700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: change < 0
                                ? AppColors.success
                                : change > 0
                                    ? AppColors.error
                                    : AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Weight history
          const Text(
            'Weight History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...history.reversed.take(10).map((entry) => _WeightHistoryRow(
                date: entry.date,
                weight: entry.weight,
              )),
        ],
      ),
    );
  }
}

// =============== Helper Widgets ===============

class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatSummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final Color color;
  final String unit;

  const _SimpleBarChart({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final value = data[index];
          final height = (value / maxValue).clamp(0.0, 1.0) * 80;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DailyWaterRow extends StatelessWidget {
  final DailyWaterSummary summary;

  const _DailyWaterRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Text(
            _formatDate(summary.date),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
            ),
          ),
          const Spacer(),
          Text(
            summary.displayTotal,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            summary.goalReached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: summary.goalReached ? AppColors.success : AppColors.neutral400,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _SleepQualityBreakdown extends StatelessWidget {
  final List<SleepLogEntity> history;

  const _SleepQualityBreakdown({required this.history});

  @override
  Widget build(BuildContext context) {
    final qualityCounts = <SleepQuality, int>{};
    for (final log in history) {
      if (log.quality != null) {
        qualityCounts[log.quality!] = (qualityCounts[log.quality!] ?? 0) + 1;
      }
    }

    final total = qualityCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: SleepQuality.values.map((quality) {
          final count = qualityCounts[quality] ?? 0;
          final percentage = count / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    quality.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.neutral200,
                    color: Color(_getQualityColor(quality)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getQualityColor(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 0xFFE53935;
      case SleepQuality.fair:
        return 0xFFFFA726;
      case SleepQuality.good:
        return 0xFF66BB6A;
      case SleepQuality.excellent:
        return 0xFF42A5F5;
    }
  }
}

class _MoodTrendChart extends StatelessWidget {
  final List<MoodLogEntity> history;

  const _MoodTrendChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(child: Text('No mood data')),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: history.take(7).map((log) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                log.moodEmoji ?? '❓',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                _weekdayLabel(log.logDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

class _EnergyTrendChart extends StatelessWidget {
  final List<MoodLogEntity> history;

  const _EnergyTrendChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(child: Text('No energy data')),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: history.take(7).map((log) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                log.energyEmoji ?? '❓',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                _weekdayLabel(log.logDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

class _WeightHistoryRow extends StatelessWidget {
  final DateTime date;
  final double weight;

  const _WeightHistoryRow({
    required this.date,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
            ),
          ),
          const Spacer(),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
