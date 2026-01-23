import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/alternative_exercise.dart';
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
      onAlternativeSelected: onAlternativeSelected,
    );
  }
}

/// Button to open alternative exercise bottom sheet
class AlternativeExerciseButton extends ConsumerWidget {
  final String exerciseId;
  final Function(SessionAlternative)? onAlternativeSelected;

  const AlternativeExerciseButton({
    required this.exerciseId,
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
        onAlternativeSelected: (alt) {
          Navigator.pop(ctx);
          onAlternativeSelected?.call(alt);
        },
      ),
    );
  }
}

/// Bottom sheet showing alternative exercises grouped by type
class AlternativeExerciseBottomSheet extends ConsumerWidget {
  final String exerciseId;
  final Function(SessionAlternative)? onAlternativeSelected;

  const AlternativeExerciseBottomSheet({
    required this.exerciseId,
    this.onAlternativeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alternativesAsync = ref.watch(alternativeExercisesProvider(exerciseId));

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
                      // Equipment alternatives section
                      if (result.equipmentAlternatives.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.build_outlined,
                          title: '다른 장비로',
                          subtitle: '같은 움직임, 다른 장비',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...result.equipmentAlternatives.map((group) =>
                            _buildEquipmentGroup(group)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Pattern alternatives section
                      if (result.patternAlternatives.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.repeat,
                          title: '같은 패턴',
                          subtitle: '같은 장비, 비슷한 운동',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...result.patternAlternatives.map((alt) =>
                            _AlternativeExerciseItem(
                              alternative: alt,
                              onSelect: () => onAlternativeSelected?.call(alt),
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

  Widget _buildEquipmentGroup(EquipmentGroup group) {
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
          ...group.exercises.map((alt) => _AlternativeExerciseItem(
                alternative: alt,
                onSelect: () => onAlternativeSelected?.call(alt),
                showEquipmentBadge: false,
              )),
        ],
      ),
    );
  }
}

/// Individual alternative exercise item
class _AlternativeExerciseItem extends StatelessWidget {
  final SessionAlternative alternative;
  final VoidCallback onSelect;
  final bool showEquipmentBadge;

  const _AlternativeExerciseItem({
    required this.alternative,
    required this.onSelect,
    this.showEquipmentBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
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
          child: Row(
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
              Icon(
                Icons.chevron_right,
                color: AppColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
