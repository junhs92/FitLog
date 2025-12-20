import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/exercise_difficulty.dart';
import '../providers/ai_workout_provider.dart';

/// Bottom sheet for exercise swap with alternatives
class ExerciseSwapSheet extends ConsumerStatefulWidget {
  final ProgramExerciseEntity exercise;
  final String clientId;
  final TrainingGoal goal;
  final Function(String exerciseId, String? reason)? onSwap;

  const ExerciseSwapSheet({
    required this.exercise,
    required this.clientId,
    required this.goal,
    this.onSwap,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required ProgramExerciseEntity exercise,
    required String clientId,
    required TrainingGoal goal,
    Function(String exerciseId, String? reason)? onSwap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSwapSheet(
        exercise: exercise,
        clientId: clientId,
        goal: goal,
        onSwap: onSwap,
      ),
    );
  }

  @override
  ConsumerState<ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}

class _ExerciseSwapSheetState extends ConsumerState<ExerciseSwapSheet> {
  String? _selectedAlternativeId;

  @override
  Widget build(BuildContext context) {
    final alternativesAsync = ref.watch(exerciseAlternativesProvider((
      exerciseId: widget.exercise.exerciseId,
      clientId: widget.clientId,
      feedback: null,
    )));

    // Use the already-loaded reasoning from the exercise entity
    // instead of fetching from provider (which queries wrong table)
    final reasoning = widget.exercise.aiReasoning;

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
                        '운동 변경',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.displayName,
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
                  // AI Reasoning Section
                  const Text(
                    'AI 선택 이유',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildReasoningSection(reasoning),
                  const SizedBox(height: AppSpacing.lg),
                  // Alternatives Section
                  const Text(
                    '대안 운동',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAlternativesSection(alternativesAsync),
                ],
              ),
            ),
          ),
          // Bottom action
          if (_selectedAlternativeId != null)
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

  Widget _buildReasoningSection(AIExerciseReasoning? reasoning) {
    if (reasoning == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Text(
          'AI 분석 정보가 없습니다',
          style: TextStyle(color: AppColors.neutral500),
        ),
      );
    }

    final topReasons = reasoning.getTopReasons(3);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: topReasons.map((reason) => _ReasonRow(reason: reason)).toList(),
      ),
    );
  }

  Widget _buildAlternativesSection(AsyncValue<List<ExerciseAlternative>> alternativesAsync) {
    return alternativesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const Text('대안을 불러올 수 없습니다'),
      data: (alternatives) {
        if (alternatives.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Text(
              '대안 운동이 없습니다',
              style: TextStyle(color: AppColors.neutral500),
            ),
          );
        }

        return Column(
          children: alternatives
              .map((alt) => _AlternativeCard(
                    alternative: alt,
                    isSelected: _selectedAlternativeId == alt.exerciseId,
                    onTap: () {
                      setState(() {
                        _selectedAlternativeId = alt.exerciseId;
                      });
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  void _handleSwap() {
    if (_selectedAlternativeId != null) {
      widget.onSwap?.call(_selectedAlternativeId!, null);
      Navigator.pop(context);
    }
  }
}

class _ReasonRow extends StatelessWidget {
  final AIReasoningPoint reason;

  const _ReasonRow({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getCategoryIcon(reason.category),
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.category.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
                Text(
                  reason.displayExplanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ],
            ),
          ),
          _ConfidenceBadge(confidence: reason.confidence),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ReasoningCategory category) {
    switch (category) {
      case ReasoningCategory.goalAlignment:
        return Icons.flag;
      case ReasoningCategory.historyBased:
        return Icons.history;
      case ReasoningCategory.safety:
        return Icons.shield;
      case ReasoningCategory.formReadiness:
        return Icons.accessibility_new;
      case ReasoningCategory.progressiveOverload:
        return Icons.trending_up;
      case ReasoningCategory.recovery:
        return Icons.favorite;
      case ReasoningCategory.equipment:
        return Icons.fitness_center;
      case ReasoningCategory.timeEfficiency:
        return Icons.timer;
    }
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$percentage%',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  final ExerciseAlternative alternative;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlternativeCard({
    required this.alternative,
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
                        alternative.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeBadge(type: alternative.type),
                          const SizedBox(width: 8),
                          _DifficultyBadge(difficulty: alternative.difficulty),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alternative.displayReason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral700,
                        ),
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
}

class _TypeBadge extends StatelessWidget {
  final AlternativeType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case AlternativeType.easier:
        color = AppColors.success;
        break;
      case AlternativeType.harder:
        color = AppColors.error;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final ExerciseDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty.displayName,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral700,
        ),
      ),
    );
  }
}
