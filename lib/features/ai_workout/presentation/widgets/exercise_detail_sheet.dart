import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../domain/entities/workout_program.dart';
import '../providers/ai_workout_provider.dart';

/// Bottom sheet for viewing exercise details and swapping with alternatives
/// Used in AIExerciseReviewScreen before session starts
class ExerciseDetailSheet extends ConsumerStatefulWidget {
  final GeneratedProgramExercise exercise;
  final void Function(GeneratedProgramExercise newExercise)? onSwap;

  const ExerciseDetailSheet({
    required this.exercise,
    this.onSwap,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required GeneratedProgramExercise exercise,
    void Function(GeneratedProgramExercise newExercise)? onSwap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(
        exercise: exercise,
        onSwap: onSwap,
      ),
    );
  }

  @override
  ConsumerState<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet> {
  ExerciseEntity? _selectedAlternative;

  @override
  Widget build(BuildContext context) {
    final similarExercises = ref.watch(similarExercisesProvider(widget.exercise.exerciseId));
    final exerciseName = widget.exercise.nameKo ?? widget.exercise.name;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '운동 상세',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exerciseName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Details Section
                  _buildExerciseDetails(),
                  const SizedBox(height: AppSpacing.lg),

                  // AI Reasoning Section
                  if (widget.exercise.aiReasoningKo != null ||
                      widget.exercise.aiReasoning != null) ...[
                    _buildAIReasoningSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Similar Exercises Section
                  const Text(
                    '비슷한 운동',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '동일한 움직임 패턴의 대체 운동을 선택하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  similarExercises.when(
                    data: (exercises) => _buildAlternativesGrid(exercises),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        '대안을 불러올 수 없습니다',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom action
          if (_selectedAlternative != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _handleSwap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '운동 변경하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralWhite,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Text(
            widget.exercise.nameKo ?? widget.exercise.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          if (widget.exercise.nameKo != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.exercise.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Sets x Reps | Rest time
          Row(
            children: [
              _InfoChip(
                icon: Icons.repeat,
                label: '${widget.exercise.targetSets}세트 x ${widget.exercise.targetReps}회',
              ),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                icon: Icons.timer,
                label: '휴식 ${widget.exercise.restSeconds}초',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIReasoningSection() {
    final reasoning = widget.exercise.aiReasoningKo ?? widget.exercise.aiReasoning ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              const Text(
                'AI 추천 이유',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reasoning,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesGrid(List<ExerciseEntity> exercises) {
    if (exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: Text(
            '비슷한 운동이 없습니다',
            style: TextStyle(color: AppColors.neutral500),
          ),
        ),
      );
    }

    return Column(
      children: exercises.map((exercise) {
        final isSelected = _selectedAlternative?.id == exercise.id;
        return _AlternativeExerciseCard(
          exercise: exercise,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedAlternative = isSelected ? null : exercise;
            });
          },
        );
      }).toList(),
    );
  }

  void _handleSwap() {
    if (_selectedAlternative != null) {
      // Create a new GeneratedProgramExercise with the alternative exercise data
      final newExercise = GeneratedProgramExercise(
        exerciseId: _selectedAlternative!.id,
        name: _selectedAlternative!.name,
        nameKo: _selectedAlternative!.nameKo,
        orderIndex: widget.exercise.orderIndex,
        targetSets: widget.exercise.targetSets,
        targetReps: widget.exercise.targetReps,
        restSeconds: widget.exercise.restSeconds,
        aiReasoning: '트레이너가 대체 운동으로 선택함',
        aiReasoningKo: '트레이너가 대체 운동으로 선택함',
      );

      widget.onSwap?.call(newExercise);
      Navigator.pop(context);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral600),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeExerciseCard extends StatelessWidget {
  final ExerciseEntity exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlternativeExerciseCard({
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.neutral300,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.neutralWhite,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (exercise.muscleGroup != null)
                            _ExerciseBadge(
                              label: _getMuscleGroupKo(exercise.muscleGroup!),
                              color: AppColors.primary,
                            ),
                          if (exercise.equipment != null)
                            _ExerciseBadge(
                              label: _getEquipmentKo(exercise.equipment!),
                              color: AppColors.info,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMuscleGroupKo(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'legs':
        return '하체';
      case 'core':
        return '코어';
      case 'biceps':
        return '이두';
      case 'triceps':
        return '삼두';
      case 'glutes':
        return '둔근';
      case 'hamstrings':
        return '햄스트링';
      case 'quadriceps':
        return '대퇴사두';
      case 'calves':
        return '종아리';
      case 'forearms':
        return '전완';
      case 'abs':
        return '복근';
      default:
        return muscleGroup;
    }
  }

  String _getEquipmentKo(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return '바벨';
      case 'dumbbell':
        return '덤벨';
      case 'cable':
        return '케이블';
      case 'machine':
        return '머신';
      case 'bodyweight':
        return '맨몸';
      case 'kettlebell':
        return '케틀벨';
      case 'resistance_band':
        return '밴드';
      case 'smith_machine':
        return '스미스머신';
      default:
        return equipment;
    }
  }
}

class _ExerciseBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ExerciseBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
