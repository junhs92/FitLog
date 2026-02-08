import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/session_entity.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../../../client_sessions/presentation/providers/client_session_provider.dart';
import '../../../muscle_map/domain/entities/client_muscle_map_entity.dart';
import '../../../muscle_map/domain/entities/muscle_activity_entity.dart';
import '../../../muscle_map/domain/entities/muscle_group.dart';
import '../../../muscle_map/presentation/providers/muscle_activity_provider.dart';
import '../../../muscle_map/presentation/widgets/interactive_body_map.dart';
import '../../../muscle_map/presentation/widgets/muscle_activity_card.dart';
import '../../domain/entities/exercise_stats_entity.dart';
import '../providers/lifestyle_provider.dart';
import '../widgets/exercise_stats_card.dart';
import '../widgets/session_history_card.dart';
import 'exercise_detail_sheet.dart';

/// Client stats screen showing progress and trends
class ClientStatsScreen extends ConsumerStatefulWidget {
  final String clientId;

  /// Optional initial tab name: 'muscles', 'water', 'sleep', 'mood', 'weight', 'exercises', 'history'
  final String? initialTab;

  const ClientStatsScreen({
    required this.clientId,
    this.initialTab,
    super.key,
  });

  @override
  ConsumerState<ClientStatsScreen> createState() => _ClientStatsScreenState();
}

class _ClientStatsScreenState extends ConsumerState<ClientStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getTabIndex(widget.initialTab),
    );
  }

  int _getTabIndex(String? tabName) {
    switch (tabName?.toLowerCase()) {
      case 'muscles':
        return 0;
      case 'exercises':
        return 1;
      case 'history':
        return 2;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Muscles'),
            Tab(text: 'Exercises'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MuscleStatsTab(clientId: widget.clientId),
          _ExerciseStatsTab(clientId: widget.clientId),
          _HistoryTab(clientId: widget.clientId),
        ],
      ),
    );
  }
}

/// Muscle stats tab showing activity heat map
class _MuscleStatsTab extends ConsumerStatefulWidget {
  final String clientId;

  const _MuscleStatsTab({required this.clientId});

  @override
  ConsumerState<_MuscleStatsTab> createState() => _MuscleStatsTabState();
}

class _MuscleStatsTabState extends ConsumerState<_MuscleStatsTab> {
  int? _selectedDayRange; // null = all time (matches Exercise tab default)
  MuscleGroup? _selectedMuscle;

  /// Filter exercises by muscle group
  List<ExerciseStatsEntity> _filterExercisesByMuscle(
    List<ExerciseStatsEntity> allStats,
    MuscleGroup muscle,
  ) {
    return allStats.where((stat) =>
      stat.muscleGroup.toLowerCase() == muscle.name.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final muscleMapAsync = ref.watch(clientMuscleMapProvider((
      clientId: widget.clientId,
      dayRange: _selectedDayRange,
    )));

    final exerciseStatsAsync = ref.watch(exerciseStatsProvider((
      clientId: widget.clientId,
      dayRange: _selectedDayRange,
    )));

    return muscleMapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (muscleMap) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Row(
              children: [
                _DayRangeChip(
                  label: '7 days',
                  isSelected: _selectedDayRange == 7,
                  onTap: () => setState(() => _selectedDayRange = 7),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DayRangeChip(
                  label: '14 days',
                  isSelected: _selectedDayRange == 14,
                  onTap: () => setState(() => _selectedDayRange = 14),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DayRangeChip(
                  label: '30 days',
                  isSelected: _selectedDayRange == 30,
                  onTap: () => setState(() => _selectedDayRange = 30),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DayRangeChip(
                  label: 'All',
                  isSelected: _selectedDayRange == null,
                  onTap: () => setState(() => _selectedDayRange = null),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Interactive body map
            InteractiveBodyMap(
              muscleMap: muscleMap,
              selectedMuscle: _selectedMuscle,
              onMuscleTap: (group, activity) {
                setState(() {
                  if (_selectedMuscle == group) {
                    _selectedMuscle = null;
                  } else {
                    _selectedMuscle = group;
                  }
                });
              },
            ),
            // When muscle selected: show detail card + related exercises
            if (_selectedMuscle != null) ...[
              const SizedBox(height: AppSpacing.md),
              MuscleActivityCard(
                activity: muscleMap.getActivity(_selectedMuscle!) ??
                    MuscleActivityEntity.inactive(_selectedMuscle!),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRelatedExercises(exerciseStatsAsync, _selectedMuscle!),
            ],
            // When no muscle selected: show all muscles with percentages and exercises
            if (_selectedMuscle == null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildMuscleOverview(muscleMap, exerciseStatsAsync),
            ],
          ],
        ),
      ),
    );
  }

  /// Build muscle overview list for no selection state
  Widget _buildMuscleOverview(
    ClientMuscleMapEntity muscleMap,
    AsyncValue<List<ExerciseStatsEntity>> exerciseStatsAsync,
  ) {
    final sortedMuscles = muscleMap.sortedByIntensity;

    return exerciseStatsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (allStats) {
        // Calculate total volume for coverage percentage
        final totalVolume = muscleMap.activities.values
            .fold(0, (sum, activity) => sum + activity.totalVolume);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '근육별 운동 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...sortedMuscles.map((activity) {
              final exercises = _filterExercisesByMuscle(allStats, activity.muscleGroup);
              // Calculate coverage percentage (share of total workout volume)
              final percentage = totalVolume > 0
                  ? ((activity.totalVolume / totalVolume) * 100).round()
                  : 0;

              return _MuscleOverviewTile(
                clientId: widget.clientId,
                activity: activity,
                percentage: percentage,
                exerciseCount: exercises.length,
                exercises: exercises,
                onTap: () => setState(() => _selectedMuscle = activity.muscleGroup),
              );
            }),
          ],
        );
      },
    );
  }

  /// Build related exercises for selected muscle state
  Widget _buildRelatedExercises(
    AsyncValue<List<ExerciseStatsEntity>> exerciseStatsAsync,
    MuscleGroup selectedMuscle,
  ) {
    return exerciseStatsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allStats) {
        final filtered = _filterExercisesByMuscle(allStats, selectedMuscle);
        if (filtered.isEmpty) {
          return _EmptyExerciseMessage(muscle: selectedMuscle);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedMuscle.displayNameKo} 운동',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filtered.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExerciseStatsCard(
                stats: stat,
                onTap: () => showExerciseDetailSheet(
                  context,
                  clientId: widget.clientId,
                  stats: stat,
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

/// Tile showing muscle group with percentage and expandable exercises
class _MuscleOverviewTile extends StatefulWidget {
  final String clientId;
  final MuscleActivityEntity activity;
  final int percentage;
  final int exerciseCount;
  final List<ExerciseStatsEntity> exercises;
  final VoidCallback onTap;

  const _MuscleOverviewTile({
    required this.clientId,
    required this.activity,
    required this.percentage,
    required this.exerciseCount,
    required this.exercises,
    required this.onTap,
  });

  @override
  State<_MuscleOverviewTile> createState() => _MuscleOverviewTileState();
}

class _MuscleOverviewTileState extends State<_MuscleOverviewTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isInactive = widget.activity.intensity == 0;
    final hasExercises = widget.exercises.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isInactive ? AppColors.neutral200 : AppColors.neutral300,
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Muscle name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activity.muscleGroup.displayNameKo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isInactive
                                ? AppColors.neutral500
                                : AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          widget.activity.muscleGroup.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isInactive
                                ? AppColors.neutral400
                                : AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Exercise count
                  if (hasExercises) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.exerciseCount}개 운동',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // Percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPercentageColor(widget.percentage).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.percentage}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(widget.percentage),
                      ),
                    ),
                  ),
                  // Expand button
                  if (hasExercises) ...[
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Expanded exercises list
          if (_isExpanded && hasExercises) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: widget.exercises.take(5).map((stat) => _CompactExerciseRow(
                  clientId: widget.clientId,
                  stats: stat,
                )).toList(),
              ),
            ),
          ],
          // Show hint when no exercises but has activity
          if (!hasExercises && !isInactive)
            const Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.neutral400,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '운동 기록 없음',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 70) return AppColors.success;
    if (percentage >= 40) return AppColors.warning;
    if (percentage > 0) return AppColors.info;
    return AppColors.neutral400;
  }
}

/// Compact exercise row for expanded muscle tile
class _CompactExerciseRow extends StatelessWidget {
  final String clientId;
  final ExerciseStatsEntity stats;

  const _CompactExerciseRow({
    required this.clientId,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showExerciseDetailSheet(
        context,
        clientId: clientId,
        stats: stats,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 14,
            color: AppColors.neutral500,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              stats.displayName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutralBlack,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (stats.maxWeight != null) ...[
            Text(
              stats.maxWeightDisplay,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '${stats.totalSets}세트',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Empty state message when no exercises for a muscle
class _EmptyExerciseMessage extends StatelessWidget {
  final MuscleGroup muscle;

  const _EmptyExerciseMessage({required this.muscle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 40,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${muscle.displayNameKo} 운동 기록이 없습니다',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayRangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.neutralWhite : AppColors.neutral600,
          ),
        ),
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

/// Exercise stats tab showing performance statistics for each exercise
class _ExerciseStatsTab extends ConsumerStatefulWidget {
  final String clientId;

  const _ExerciseStatsTab({required this.clientId});

  @override
  ConsumerState<_ExerciseStatsTab> createState() => _ExerciseStatsTabState();
}

class _ExerciseStatsTabState extends ConsumerState<_ExerciseStatsTab> {
  int? _selectedDayRange; // null = all time

  @override
  Widget build(BuildContext context) {
    final exerciseStatsAsync = ref.watch(exerciseStatsProvider((
      clientId: widget.clientId,
      dayRange: _selectedDayRange,
    )));

    return exerciseStatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) => _buildExerciseStats(stats),
    );
  }

  Widget _buildExerciseStats(List<ExerciseStatsEntity> stats) {
    // Calculate summary stats
    final totalExercises = stats.length;
    final totalSets = stats.fold(0, (sum, s) => sum + s.totalSets);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day range selector
          Row(
            children: [
              _DayRangeChip(
                label: '7 days',
                isSelected: _selectedDayRange == 7,
                onTap: () => setState(() => _selectedDayRange = 7),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DayRangeChip(
                label: '14 days',
                isSelected: _selectedDayRange == 14,
                onTap: () => setState(() => _selectedDayRange = 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DayRangeChip(
                label: '30 days',
                isSelected: _selectedDayRange == 30,
                onTap: () => setState(() => _selectedDayRange = 30),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DayRangeChip(
                label: 'All',
                isSelected: _selectedDayRange == null,
                onTap: () => setState(() => _selectedDayRange = null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatSummaryCard(
                  title: 'Exercises',
                  value: '$totalExercises',
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: 'Total Sets',
                  value: '$totalSets',
                  icon: Icons.repeat,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Exercise list
          if (stats.isEmpty)
            _buildEmptyState()
          else ...[
            const Text(
              '운동별 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...stats.map((stat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ExerciseStatsCard(
                    stats: stat,
                    onTap: () => showExerciseDetailSheet(
                      context,
                      clientId: widget.clientId,
                      stats: stat,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '운동 기록이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '세션을 완료하면 운동 통계가 여기에 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Session history tab showing all completed sessions
class _HistoryTab extends ConsumerWidget {
  final String clientId;

  const _HistoryTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionHistoryAsync = ref.watch(clientSessionHistoryProvider(clientId));

    return sessionHistoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) => _buildSessionHistory(context, ref, sessions),
    );
  }

  Widget _buildSessionHistory(BuildContext context, WidgetRef ref, List<SessionEntity> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate summary stats
    final totalSessions = sessions.length;
    final totalVolume = sessions.fold<double>(
      0,
      (sum, s) => sum + (s.savedTotalVolume ?? s.totalVolume),
    );
    final totalPRs = sessions.fold<int>(0, (sum, s) => sum + s.prCount);

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
                  title: '총 세션',
                  value: '$totalSessions',
                  icon: Icons.calendar_today,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: '총 볼륨',
                  value: _formatVolume(totalVolume),
                  icon: Icons.monitor_weight_outlined,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatSummaryCard(
                  title: 'PRs',
                  value: '$totalPRs',
                  icon: Icons.emoji_events,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Session history header
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 20,
                color: AppColors.neutral700,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                '세션 기록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length}개 세션',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Session list
          ...sessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SessionHistoryCard(
                  session: session,
                  onTap: () => _navigateToReport(context, ref, session),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              '세션 기록이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '세션을 완료하면 여기에 기록이 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReport(BuildContext context, WidgetRef ref, SessionEntity session) {
    // Get report for this session
    final reportAsync = ref.read(sessionReportProvider(session.id));
    final report = reportAsync.valueOrNull;

    if (report != null) {
      context.push('/client/report/${report.id}');
    } else {
      // Show message that report is not available yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report not available yet'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M kg';
    }
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }
}
