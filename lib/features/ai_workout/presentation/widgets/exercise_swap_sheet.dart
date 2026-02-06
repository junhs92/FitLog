import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/session_exercise_entity.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/session_feedback.dart';
import '../providers/ai_workout_provider.dart';

/// Bottom sheet for exercise swap with alternatives during a session
/// Uses session-level alternatives instead of deprecated program-level alternatives
class ExerciseSwapSheet extends ConsumerStatefulWidget {
  final SessionExerciseEntity sessionExercise;
  final String clientId;
  final TrainingGoal goal;
  final DifficultyFeedback? initialFeedback;
  final Function(String exerciseId, String? reason)? onSwap;

  const ExerciseSwapSheet({
    required this.sessionExercise,
    required this.clientId,
    required this.goal,
    this.initialFeedback,
    this.onSwap,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required SessionExerciseEntity sessionExercise,
    required String clientId,
    required TrainingGoal goal,
    DifficultyFeedback? initialFeedback,
    Function(String exerciseId, String? reason)? onSwap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSwapSheet(
        sessionExercise: sessionExercise,
        clientId: clientId,
        goal: goal,
        initialFeedback: initialFeedback,
        onSwap: onSwap,
      ),
    );
  }

  @override
  ConsumerState<ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}

class _ExerciseSwapSheetState extends ConsumerState<ExerciseSwapSheet> {
  String? _selectedAlternativeId;
  DifficultyFeedback? _selectedFeedback;

  @override
  void initState() {
    super.initState();
    _selectedFeedback = widget.initialFeedback;

    // If initial feedback is provided, load alternatives
    if (widget.initialFeedback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAlternatives(widget.initialFeedback!);
      });
    }
  }

  void _loadAlternatives(DifficultyFeedback feedback) {
    final exerciseId = widget.sessionExercise.exercise.id;
    ref.read(sessionFeedbackProvider(exerciseId).notifier).recordFeedback(
      sessionExerciseId: widget.sessionExercise.id,
      exerciseId: exerciseId,
      clientId: widget.clientId,
      feedback: feedback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseId = widget.sessionExercise.exercise.id;
    final feedbackState = ref.watch(sessionFeedbackProvider(exerciseId));
    final exerciseName = widget.sessionExercise.exercise.displayName;

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
                  // Difficulty Feedback Section
                  const Text(
                    '현재 난이도',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildFeedbackButtons(),
                  const SizedBox(height: AppSpacing.lg),

                  // Alternatives Section
                  if (_selectedFeedback != null &&
                      _selectedFeedback != DifficultyFeedback.justRight) ...[
                    const Text(
                      '대안 운동',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildAlternativesSection(feedbackState),
                  ] else if (_selectedFeedback == DifficultyFeedback.justRight) ...[
                    _buildJustRightMessage(),
                  ],
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

  Widget _buildFeedbackButtons() {
    return Row(
      children: DifficultyFeedback.values.map((feedback) {
        final isSelected = _selectedFeedback == feedback;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: feedback != DifficultyFeedback.values.last ? 8 : 0,
            ),
            child: Material(
              color: isSelected
                  ? _getFeedbackColor(feedback).withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFeedback = feedback;
                    _selectedAlternativeId = null;
                  });
                  _loadAlternatives(feedback);
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? _getFeedbackColor(feedback)
                          : AppColors.neutral200,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feedback.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? _getFeedbackColor(feedback)
                              : AppColors.neutral700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getFeedbackColor(DifficultyFeedback feedback) {
    switch (feedback) {
      case DifficultyFeedback.tooEasy:
        return AppColors.success;
      case DifficultyFeedback.justRight:
        return AppColors.primary;
      case DifficultyFeedback.struggling:
        return AppColors.warning;
    }
  }

  Widget _buildJustRightMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '현재 운동이 적절합니다. 계속 진행하세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesSection(SessionFeedbackState feedbackState) {
    if (feedbackState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (feedbackState.error != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          '대안을 불러올 수 없습니다: ${feedbackState.error}',
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    final alternatives = feedbackState.alternatives;
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
          .map((alt) => _SessionAlternativeCard(
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
  }

  void _handleSwap() {
    if (_selectedAlternativeId != null) {
      final reason = _selectedFeedback?.id;
      widget.onSwap?.call(_selectedAlternativeId!, reason);
      Navigator.pop(context);
    }
  }
}

class _SessionAlternativeCard extends StatelessWidget {
  final SessionAlternative alternative;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionAlternativeCard({
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alternative.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutralBlack,
                              ),
                            ),
                          ),
                          if (alternative.isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '추천',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AlternativeTypeBadge(type: alternative.type),
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

class _AlternativeTypeBadge extends StatelessWidget {
  final AlternativeType type;

  const _AlternativeTypeBadge({required this.type});

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
      case AlternativeType.equipmentBased:
        color = AppColors.info;
        break;
      case AlternativeType.injuryFriendly:
        color = AppColors.warning;
        break;
      case AlternativeType.samePattern:
        color = AppColors.primary;
        break;
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
