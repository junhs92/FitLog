import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/alternative_exercise.dart';
import '../../../active_session/domain/entities/exercise_set_entity.dart';
import '../../../active_session/presentation/providers/exercise_picker_provider.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../providers/ai_workout_provider.dart';

/// Widget for real-time difficulty feedback during sessions
/// Now replaced with alternative exercise button that opens a bottom sheet
class DifficultyFeedbackWidget extends ConsumerWidget {
  final String sessionExerciseId;
  final String exerciseId;
  final String clientId;
  final Function(SessionAlternative)? onAlternativeSelected;

  const DifficultyFeedbackWidget({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.clientId,
    this.onAlternativeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlternativeExerciseButton(
      exerciseId: exerciseId,
      clientId: clientId,
      onAlternativeSelected: onAlternativeSelected,
    );
  }
}

/// Button to open alternative exercise bottom sheet
class AlternativeExerciseButton extends ConsumerWidget {
  final String exerciseId;
  final String? clientId;
  final Function(SessionAlternative)? onAlternativeSelected;

  const AlternativeExerciseButton({
    required this.exerciseId,
    this.clientId,
    this.onAlternativeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAlternativesSheet(context, ref),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '대체 운동',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlternativesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlternativeExerciseBottomSheet(
        exerciseId: exerciseId,
        clientId: clientId,
        onAlternativeSelected: (alt) {
          Navigator.pop(ctx);
          onAlternativeSelected?.call(alt);
        },
      ),
    );
  }
}

/// Bottom sheet showing alternative exercises grouped by type
class AlternativeExerciseBottomSheet extends ConsumerStatefulWidget {
  final String exerciseId;
  final String? clientId;
  final Function(SessionAlternative)? onAlternativeSelected;

  const AlternativeExerciseBottomSheet({
    required this.exerciseId,
    this.clientId,
    this.onAlternativeSelected,
    super.key,
  });

  @override
  ConsumerState<AlternativeExerciseBottomSheet> createState() =>
      _AlternativeExerciseBottomSheetState();
}

class _AlternativeExerciseBottomSheetState
    extends ConsumerState<AlternativeExerciseBottomSheet> {
  String? _expandedExerciseId;

  void _toggleExpanded(String exerciseId) {
    setState(() {
      if (_expandedExerciseId == exerciseId) {
        _expandedExerciseId = null;
      } else {
        _expandedExerciseId = exerciseId;
      }
    });
  }

  List<SessionAlternative> _sortByHistory(
      List<SessionAlternative> alts, Set<String> recentIds) {
    if (recentIds.isEmpty) return alts;
    final sorted = List<SessionAlternative>.from(alts);
    sorted.sort((a, b) {
      final aDone = recentIds.contains(a.exerciseId) ? 0 : 1;
      final bDone = recentIds.contains(b.exerciseId) ? 0 : 1;
      return aDone.compareTo(bDone);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final alternativesAsync = ref.watch(alternativeExercisesProvider(widget.exerciseId));
    final recentIds = widget.clientId != null
        ? (ref.watch(recentExercisesProvider(widget.clientId!)).valueOrNull
            ?.map((e) => e.id).toSet() ?? <String>{})
        : <String>{};

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_horiz,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '대체 운동 추천',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: alternativesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '대체 운동을 불러오는데 실패했습니다',
                        style: TextStyle(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (result) {
                if (result.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: AppColors.neutral400,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '대체 운동이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '같은 패턴의 운동을 찾을 수 없습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Pattern alternatives (같은 장비, 비슷한 운동) - FIRST
                      if (result.patternAlternatives.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.repeat,
                          title: '같은 장비, 비슷한 운동',
                          subtitle: '동일 장비로 다른 변형',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._sortByHistory(result.patternAlternatives, recentIds).map((alt) =>
                            _AlternativeExerciseItem(
                              alternative: alt,
                              clientId: widget.clientId,
                              isExpanded: _expandedExerciseId == alt.exerciseId,
                              onToggle: () => _toggleExpanded(alt.exerciseId),
                              onSelect: () => widget.onAlternativeSelected?.call(alt),
                            )),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Section 2: Equipment alternatives (비슷한 운동 다른 장비)
                      if (result.equipmentAlternatives.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.build_outlined,
                          title: '비슷한 운동 다른 장비',
                          subtitle: '같은 움직임, 다른 장비',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...result.equipmentAlternatives.map((group) =>
                            _buildEquipmentGroup(group, recentIds)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Section 3: Accessory exercises (악세서리 운동) - NEW
                      if (result.accessoryExercises.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.sports_gymnastics,
                          title: '악세서리 운동',
                          subtitle: '같은 패턴 고립 운동',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._sortByHistory(result.accessoryExercises, recentIds).map((alt) =>
                            _AlternativeExerciseItem(
                              alternative: alt,
                              clientId: widget.clientId,
                              isExpanded: _expandedExerciseId == alt.exerciseId,
                              onToggle: () => _toggleExpanded(alt.exerciseId),
                              onSelect: () => widget.onAlternativeSelected?.call(alt),
                            )),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentGroup(EquipmentGroup group, Set<String> recentIds) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    group.equipmentLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.exercises.length}개',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          // Exercises in this equipment group
          ..._sortByHistory(group.exercises, recentIds).map((alt) => _AlternativeExerciseItem(
                alternative: alt,
                clientId: widget.clientId,
                isExpanded: _expandedExerciseId == alt.exerciseId,
                onToggle: () => _toggleExpanded(alt.exerciseId),
                onSelect: () => widget.onAlternativeSelected?.call(alt),
                showEquipmentBadge: false,
              )),
        ],
      ),
    );
  }
}

/// Individual alternative exercise item with expandable history
class _AlternativeExerciseItem extends StatelessWidget {
  final SessionAlternative alternative;
  final String? clientId;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback onSelect;
  final bool showEquipmentBadge;

  const _AlternativeExerciseItem({
    required this.alternative,
    this.clientId,
    this.isExpanded = false,
    this.onToggle,
    required this.onSelect,
    this.showEquipmentBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: clientId != null ? onToggle : onSelect,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.neutral100,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alternative.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutralBlack,
                                ),
                              ),
                            ),
                            if (alternative.isRecommended)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '추천',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutralWhite,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alternative.displayReason,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onSelect,
                  ),
                ],
              ),
              // Inline history
              if (clientId != null)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Consumer(builder: (context, ref, _) {
                      final historyAsync = ref.watch(
                        exercisePickerHistoryProvider((
                          clientId: clientId!,
                          exerciseId: alternative.exerciseId,
                        )),
                      );
                      return historyAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('기록을 불러올 수 없습니다',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.neutral500)),
                        ),
                        data: (data) => _AlternativeHistoryContent(data: data),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact history display for alternative exercise items
class _AlternativeHistoryContent extends StatelessWidget {
  final ExercisePickerHistoryData data;

  const _AlternativeHistoryContent({required this.data});

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 15, color: AppColors.neutral400),
            const SizedBox(width: 6),
            const Text(
              '이 운동의 기록이 없습니다',
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.pr != null) _buildPrBanner(data.pr!),
        if (data.recentSessions.isNotEmpty) ...[
          if (data.pr != null) const SizedBox(height: 8),
          for (int i = 0; i < data.recentSessions.length; i++)
            _buildSessionBlock(data.recentSessions[i], i),
        ],
      ],
    );
  }

  Widget _buildPrBanner(ExerciseSetEntity pr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.emoji_events,
                size: 15, color: AppColors.warning),
          ),
          const SizedBox(width: 8),
          const Text('PR',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning)),
          const Spacer(),
          _buildWeightReps(pr, large: true),
        ],
      ),
    );
  }

  static const _sessionAccentOpacities = [1.0, 0.55, 0.3];

  Widget _buildSessionBlock(SessionSetsGroup session, int index) {
    final accent = _sessionAccentOpacities[index.clamp(0, 2)];
    final now = DateTime.now();
    final diff = now.difference(session.date).inDays;
    final dateStr = diff == 0
        ? '오늘'
        : diff == 1
            ? '어제'
            : diff < 7
                ? '$diff일 전'
                : '${session.date.month}/${session.date.day}';

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 2 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: accent),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: accent),
                          letterSpacing: 0.2,
                        )),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children:
                          session.sets.take(6).map(_buildSetChip).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetChip(ExerciseSetEntity set) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _buildWeightReps(set, large: false),
    );
  }

  Widget _buildWeightReps(ExerciseSetEntity set, {required bool large}) {
    final weight =
        set.weight?.toStringAsFixed(set.weight! % 1 == 0 ? 0 : 1);
    final reps = set.reps;

    if (weight != null && reps != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(weight,
              style: TextStyle(
                  fontSize: large ? 16 : 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack)),
          Text('kg',
              style: TextStyle(
                  fontSize: large ? 11 : 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral600)),
          Text(large ? ' x $reps회' : ' x$reps',
              style: TextStyle(
                  fontSize: large ? 14 : 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700)),
        ],
      );
    }
    if (weight != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(weight,
              style: TextStyle(
                  fontSize: large ? 16 : 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutralBlack)),
          Text('kg',
              style: TextStyle(
                  fontSize: large ? 11 : 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral600)),
        ],
      );
    }
    if (reps != null) {
      return Text('$reps회',
          style: TextStyle(
              fontSize: large ? 16 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.neutralBlack));
    }
    return Text('-',
        style: TextStyle(
            fontSize: large ? 16 : 12, color: AppColors.neutral500));
  }
}

/// Compact difficulty feedback for inline use
/// Now replaced with compact alternative exercise button
class DifficultyFeedbackCompact extends StatelessWidget {
  final DifficultyFeedback? currentFeedback;
  final Function(DifficultyFeedback) onFeedback;

  const DifficultyFeedbackCompact({
    this.currentFeedback,
    required this.onFeedback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty container - this widget is deprecated
    // Use AlternativeExerciseButton instead
    return const SizedBox.shrink();
  }
}
