import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../lifestyle_log/domain/entities/lifestyle_summary_entity.dart';
import '../../../lifestyle_log/domain/entities/mood_log_entity.dart';
import '../../../lifestyle_log/domain/entities/sleep_log_entity.dart';
import '../../../lifestyle_log/presentation/providers/lifestyle_provider.dart';
import '../screens/lifestyle_detail_screen.dart';

/// Widget displaying 7-day lifestyle summary for a client
/// Used in Flow 0 (Pre-Session) on ClientDetailScreen
/// Tap to show detailed lifestyle records in a popup
class LifestyleSummaryCard extends ConsumerWidget {
  final String clientId;

  const LifestyleSummaryCard({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(clientLifestyleSummaryProvider(clientId));

    return summaryAsync.when(
      data: (summary) {
        if (summary == null || !summary.hasData) {
          return _buildEmptyState(context);
        }
        return _buildSummaryCard(context, summary);
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyState(context),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 0,
      color: AppColors.darkSurfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('최근 7일 라이프스타일'),
            const SizedBox(height: AppSpacing.md),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.darkSurfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('최근 7일 라이프스타일'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: AppColors.neutral500, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '기록된 라이프스타일 데이터가 없습니다',
                    style: TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, LifestyleSummaryEntity summary) {
    return Card(
      elevation: 0,
      color: AppColors.darkSurfaceElevated,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showLifestyleDetailSheet(context, clientId),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('최근 7일 라이프스타일', showChevron: true),
              const SizedBox(height: AppSpacing.md),

              // Vertical list of metrics with week indicators
              if (summary.sleep.daysLogged > 0) ...[
                _MetricSection(
                  icon: Icons.bedtime_outlined,
                  label: '수면',
                  value: summary.sleep.avgHours != null
                      ? '${summary.sleep.avgHours!.toStringAsFixed(1)}시간'
                      : '-',
                  subValue: _getSleepQualityText(summary.sleep.avgQuality),
                  color: AppColors.info,
                  fromDate: summary.fromDate,
                  loggedDates: summary.sleep.loggedDates,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (summary.mood.daysLogged > 0) ...[
                _MetricSection(
                  icon: _getMoodIcon(summary.mood.avgMood),
                  label: '기분',
                  value: _getMoodText(summary.mood.avgMood),
                  subValue: _getEnergyText(summary.mood.avgEnergy),
                  color: AppColors.warning,
                  fromDate: summary.fromDate,
                  loggedDates: summary.mood.loggedDates,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (summary.nutrition.daysLogged > 0) ...[
                _MetricSection(
                  icon: Icons.restaurant_outlined,
                  label: '영양',
                  value: summary.nutrition.avgCalories != null
                      ? '${summary.nutrition.avgCalories}kcal'
                      : '-',
                  subValue: summary.nutrition.avgWaterFormatted != null
                      ? '물 ${summary.nutrition.avgWaterFormatted}'
                      : null,
                  color: AppColors.success,
                  fromDate: summary.fromDate,
                  loggedDates: summary.nutrition.mealLoggedDates,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (summary.weight.daysLogged > 0) ...[
                _MetricSection(
                  icon: Icons.monitor_weight_outlined,
                  label: '체중',
                  value: summary.weight.currentWeight != null
                      ? '${summary.weight.currentWeight!.toStringAsFixed(1)}kg'
                      : '-',
                  subValue: summary.weight.changeFormatted,
                  subValueColor: summary.weight.isLoss
                      ? AppColors.success
                      : summary.weight.isGain
                          ? AppColors.warning
                          : null,
                  color: AppColors.primary,
                  fromDate: summary.fromDate,
                  loggedDates: summary.weight.loggedDates,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (summary.activity.daysLogged > 0)
                _MetricSection(
                  icon: Icons.directions_walk_outlined,
                  label: '활동',
                  value: summary.activity.avgStepsFormatted != null
                      ? '${summary.activity.avgStepsFormatted} 걸음'
                      : '-',
                  subValue: summary.activity.avgActiveMinutes != null
                      ? '${summary.activity.avgActiveMinutes}분 활동'
                      : null,
                  color: AppColors.secondary,
                  fromDate: summary.fromDate,
                  loggedDates: summary.activity.loggedDates,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showChevron = false}) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: AppColors.neutral600,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTextPrimary,
            ),
          ),
        ),
        if (showChevron)
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.neutral500,
          ),
      ],
    );
  }

  String? _getSleepQualityText(SleepQuality? quality) {
    if (quality == null) return null;
    switch (quality) {
      case SleepQuality.poor:
        return '나쁨';
      case SleepQuality.fair:
        return '보통';
      case SleepQuality.good:
        return '좋음';
      case SleepQuality.excellent:
        return '매우 좋음';
    }
  }

  IconData _getMoodIcon(MoodLevel? mood) {
    if (mood == null) return Icons.sentiment_neutral;
    switch (mood) {
      case MoodLevel.veryLow:
        return Icons.sentiment_very_dissatisfied;
      case MoodLevel.low:
        return Icons.sentiment_dissatisfied;
      case MoodLevel.neutral:
        return Icons.sentiment_neutral;
      case MoodLevel.good:
        return Icons.sentiment_satisfied;
      case MoodLevel.excellent:
        return Icons.sentiment_very_satisfied;
    }
  }

  String _getMoodText(MoodLevel? mood) {
    if (mood == null) return '-';
    switch (mood) {
      case MoodLevel.veryLow:
        return '매우 낮음';
      case MoodLevel.low:
        return '낮음';
      case MoodLevel.neutral:
        return '보통';
      case MoodLevel.good:
        return '좋음';
      case MoodLevel.excellent:
        return '매우 좋음';
    }
  }

  String? _getEnergyText(EnergyLevel? energy) {
    if (energy == null) return null;
    switch (energy) {
      case EnergyLevel.exhausted:
        return '지침';
      case EnergyLevel.tired:
        return '피곤';
      case EnergyLevel.normal:
        return '보통';
      case EnergyLevel.energetic:
        return '활력';
      case EnergyLevel.veryEnergetic:
        return '매우 활력';
    }
  }
}

/// Individual metric section with week indicator
class _MetricSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? subValueColor;
  final Color color;
  final DateTime fromDate;
  final List<DateTime> loggedDates;

  const _MetricSection({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.subValueColor,
    required this.color,
    required this.fromDate,
    required this.loggedDates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, label, and value
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: TextStyle(
                    fontSize: 12,
                    color: subValueColor ?? AppColors.neutral600,
                    fontWeight: subValueColor != null ? FontWeight.w600 : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Week indicator
          _WeekDayIndicator(
            fromDate: fromDate,
            loggedDates: loggedDates,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Widget showing 7-day week with filled/empty circles for logged days
class _WeekDayIndicator extends StatelessWidget {
  final DateTime fromDate;
  final List<DateTime> loggedDates;
  final Color color;

  const _WeekDayIndicator({
    required this.fromDate,
    required this.loggedDates,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Korean weekday names
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    // Generate 7 days from fromDate
    final days = List.generate(7, (i) => fromDate.add(Duration(days: i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((date) {
        final isLogged = _isDateLogged(date);
        final weekDayIndex = (date.weekday - 1) % 7; // Monday = 0

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekDays[weekDayIndex],
              style: TextStyle(
                fontSize: 10,
                color: isLogged ? color : AppColors.neutral400,
                fontWeight: isLogged ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLogged ? color : Colors.transparent,
                border: Border.all(
                  color: isLogged ? color : AppColors.darkBorder,
                  width: 1.5,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isDateLogged(DateTime date) {
    // Normalize to date-only comparison
    final dateOnly = DateTime(date.year, date.month, date.day);
    return loggedDates.any((logged) {
      final loggedDateOnly = DateTime(logged.year, logged.month, logged.day);
      return loggedDateOnly.isAtSameMomentAs(dateOnly);
    });
  }
}
