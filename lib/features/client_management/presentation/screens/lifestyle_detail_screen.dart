import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../lifestyle_log/domain/entities/meal_log_entity.dart';
import '../../../lifestyle_log/domain/entities/mood_log_entity.dart';
import '../../../lifestyle_log/domain/entities/sleep_log_entity.dart';
import '../../../lifestyle_log/domain/entities/water_log_entity.dart';
import '../../../lifestyle_log/presentation/providers/lifestyle_provider.dart';

/// Shows lifestyle detail as a modal bottom sheet
/// Call this function to display the popup
void showLifestyleDetailSheet(
  BuildContext context,
  String clientId,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LifestyleDetailSheet(clientId: clientId),
  );
}

/// Modal bottom sheet content for 7-day lifestyle details
class _LifestyleDetailSheet extends ConsumerWidget {
  final String clientId;

  const _LifestyleDetailSheet({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(client7DayLifestyleLogsProvider(clientId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    '7일 라이프스타일',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Flexible(
            child: logsAsync.when(
              data: (logs) => _buildContent(context, logs),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('데이터를 불러올 수 없습니다'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Client7DayLifestyleLogs logs) {
    final dateFormat = DateFormat('M/d');
    final dateRange =
        '${dateFormat.format(logs.fromDate)} - ${dateFormat.format(logs.toDate)}';

    if (!logs.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '기록된 라이프스타일 데이터가 없습니다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.neutral500,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Sleep section
          if (logs.sleepLogs.isNotEmpty) ...[
            _SleepSection(sleepLogs: logs.sleepLogs),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Mood section
          if (logs.moodLogs.isNotEmpty) ...[
            _MoodSection(moodLogs: logs.moodLogs),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Nutrition section
          if (logs.mealLogs.isNotEmpty || logs.waterLogs.isNotEmpty) ...[
            _NutritionSection(
              mealLogs: logs.mealLogs,
              waterLogs: logs.waterLogs,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Activity section
          if (logs.activityLogs.isNotEmpty) ...[
            _ActivitySection(activityLogs: logs.activityLogs),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

/// Sleep section with expandable daily records
class _SleepSection extends StatelessWidget {
  final List<SleepLogEntity> sleepLogs;

  const _SleepSection({required this.sleepLogs});

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sortedLogs = List<SleepLogEntity>.from(sleepLogs)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));

    return _ExpandableSection(
      icon: Icons.bedtime_outlined,
      title: '수면',
      color: AppColors.info,
      itemCount: sortedLogs.length,
      children: sortedLogs.map((log) => _SleepLogTile(log: log)).toList(),
    );
  }
}

class _SleepLogTile extends StatelessWidget {
  final SleepLogEntity log;

  const _SleepLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M/d (E)');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              dateFormat.format(log.logDate),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                if (log.durationDisplay != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.durationDisplay!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (log.bedtime != null && log.wakeTime != null)
                  Text(
                    '${timeFormat.format(log.bedtime!)} → ${timeFormat.format(log.wakeTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),
          if (log.qualityEmoji != null)
            Text(
              log.qualityEmoji!,
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}

/// Mood section with expandable daily records
class _MoodSection extends StatelessWidget {
  final List<MoodLogEntity> moodLogs;

  const _MoodSection({required this.moodLogs});

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sortedLogs = List<MoodLogEntity>.from(moodLogs)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));

    return _ExpandableSection(
      icon: Icons.sentiment_satisfied_outlined,
      title: '기분',
      color: AppColors.warning,
      itemCount: sortedLogs.length,
      children: sortedLogs.map((log) => _MoodLogTile(log: log)).toList(),
    );
  }
}

class _MoodLogTile extends StatelessWidget {
  final MoodLogEntity log;

  const _MoodLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M/d (E)');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              dateFormat.format(log.logDate),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (log.moodEmoji != null)
            Text(log.moodEmoji!, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              log.moodName ?? '-',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (log.energyEmoji != null) ...[
            Text(log.energyEmoji!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              log.energyName ?? '',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
              ),
            ),
          ],
          if (log.stressLevel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStressColor(log.stressLevel!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '스트레스 ${log.stressLevel}',
                style: TextStyle(
                  fontSize: 11,
                  color: _getStressColor(log.stressLevel!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStressColor(int stress) {
    if (stress <= 3) return AppColors.success;
    if (stress <= 6) return AppColors.warning;
    return AppColors.error;
  }
}

/// Nutrition section with meals and water
class _NutritionSection extends StatelessWidget {
  final List<MealLogEntity> mealLogs;
  final List<DailyWaterSummary> waterLogs;

  const _NutritionSection({
    required this.mealLogs,
    required this.waterLogs,
  });

  @override
  Widget build(BuildContext context) {
    // Group meals by date
    final mealsByDate = <DateTime, List<MealLogEntity>>{};
    for (final meal in mealLogs) {
      final dateKey = DateTime(meal.logDate.year, meal.logDate.month, meal.logDate.day);
      mealsByDate.putIfAbsent(dateKey, () => []).add(meal);
    }

    // Sort dates descending
    final sortedDates = mealsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return _ExpandableSection(
      icon: Icons.restaurant_outlined,
      title: '영양',
      color: AppColors.success,
      itemCount: sortedDates.length,
      children: sortedDates.map((date) {
        final meals = mealsByDate[date]!;
        final water = waterLogs.cast<DailyWaterSummary?>().firstWhere(
              (w) =>
                  w!.date.year == date.year &&
                  w.date.month == date.month &&
                  w.date.day == date.day,
              orElse: () => null,
            );
        return _DailyNutritionTile(
          date: date,
          meals: meals,
          water: water,
        );
      }).toList(),
    );
  }
}

class _DailyNutritionTile extends StatelessWidget {
  final DateTime date;
  final List<MealLogEntity> meals;
  final DailyWaterSummary? water;

  const _DailyNutritionTile({
    required this.date,
    required this.meals,
    this.water,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M/d (E)');

    // Calculate totals
    int totalCalories = 0;
    double totalProtein = 0;
    for (final meal in meals) {
      totalCalories += meal.calories ?? 0;
      totalProtein += meal.protein ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with totals
          Row(
            children: [
              Text(
                dateFormat.format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (totalCalories > 0)
                Text(
                  '$totalCalories kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              if (totalProtein > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'P ${totalProtein.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
              if (water != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.water_drop, size: 14, color: AppColors.info),
                Text(
                  water!.displayTotal,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Meals list
          ...meals.map((meal) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md, top: 2),
                child: Row(
                  children: [
                    Text(
                      meal.mealTypeIcon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        meal.description ?? meal.mealTypeName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meal.calories != null)
                      Text(
                        '${meal.calories} kcal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Activity section with daily records
class _ActivitySection extends StatelessWidget {
  final List<({DateTime date, int? steps, int? activeMinutes})> activityLogs;

  const _ActivitySection({required this.activityLogs});

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sortedLogs = List<({DateTime date, int? steps, int? activeMinutes})>.from(
      activityLogs,
    )..sort((a, b) => b.date.compareTo(a.date));

    return _ExpandableSection(
      icon: Icons.directions_walk_outlined,
      title: '활동',
      color: AppColors.secondary,
      itemCount: sortedLogs.length,
      children: sortedLogs.map((log) => _ActivityLogTile(log: log)).toList(),
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  final ({DateTime date, int? steps, int? activeMinutes}) log;

  const _ActivityLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M/d (E)');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              dateFormat.format(log.date),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (log.steps != null) ...[
            const Icon(Icons.directions_walk, size: 16, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(
              _formatSteps(log.steps!),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(' 걸음', style: TextStyle(fontSize: 12)),
          ],
          const Spacer(),
          if (log.activeMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${log.activeMinutes}분 활동',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 10000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// Reusable expandable section widget
class _ExpandableSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int itemCount;
  final List<Widget> children;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.itemCount,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: widget.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.itemCount}일',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  Divider(color: widget.color.withValues(alpha: 0.1)),
                  ...widget.children,
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
