import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/session_feedback.dart';
import '../providers/ai_workout_provider.dart';

/// Widget for real-time difficulty feedback during sessions
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
    final feedbackState = ref.watch(sessionFeedbackProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Feedback buttons
        _FeedbackButtons(
          currentFeedback: feedbackState.currentFeedback,
          onFeedback: (feedback) => _handleFeedback(ref, feedback),
        ),
        // Alternatives (shown when struggling or too easy)
        if (feedbackState.alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _AlternativesSection(
            alternatives: feedbackState.alternatives,
            isLoading: feedbackState.isLoading,
            onSelect: onAlternativeSelected,
          ),
        ],
      ],
    );
  }

  void _handleFeedback(WidgetRef ref, DifficultyFeedback feedback) {
    ref.read(sessionFeedbackProvider.notifier).recordFeedback(
          sessionExerciseId: sessionExerciseId,
          exerciseId: exerciseId,
          clientId: clientId,
          feedback: feedback,
        );
  }
}

class _FeedbackButtons extends StatelessWidget {
  final DifficultyFeedback? currentFeedback;
  final Function(DifficultyFeedback) onFeedback;

  const _FeedbackButtons({
    required this.currentFeedback,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeedbackButton(
            feedback: DifficultyFeedback.struggling,
            isSelected: currentFeedback == DifficultyFeedback.struggling,
            onTap: () => onFeedback(DifficultyFeedback.struggling),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FeedbackButton(
            feedback: DifficultyFeedback.justRight,
            isSelected: currentFeedback == DifficultyFeedback.justRight,
            onTap: () => onFeedback(DifficultyFeedback.justRight),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FeedbackButton(
            feedback: DifficultyFeedback.tooEasy,
            isSelected: currentFeedback == DifficultyFeedback.tooEasy,
            onTap: () => onFeedback(DifficultyFeedback.tooEasy),
          ),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final DifficultyFeedback feedback;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.feedback,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    switch (feedback) {
      case DifficultyFeedback.struggling:
        bgColor = isSelected ? AppColors.error : AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
        break;
      case DifficultyFeedback.justRight:
        bgColor = isSelected ? AppColors.success : AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success;
        break;
      case DifficultyFeedback.tooEasy:
        bgColor = isSelected ? AppColors.warning : AppColors.warning.withValues(alpha: 0.1);
        borderColor = AppColors.warning;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
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
                  color: isSelected ? AppColors.neutralWhite : borderColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativesSection extends StatelessWidget {
  final List<SessionAlternative> alternatives;
  final bool isLoading;
  final Function(SessionAlternative)? onSelect;

  const _AlternativesSection({
    required this.alternatives,
    required this.isLoading,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                '대안 운동 추천',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...alternatives.map((alt) => _AlternativeItem(
                alternative: alt,
                onSelect: () => onSelect?.call(alt),
              )),
        ],
      ),
    );
  }
}

class _AlternativeItem extends StatelessWidget {
  final SessionAlternative alternative;
  final VoidCallback onSelect;

  const _AlternativeItem({
    required this.alternative,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: alternative.isRecommended
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: alternative.isRecommended
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alternative.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        if (alternative.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
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
                      ],
                    ),
                    const SizedBox(height: 2),
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact difficulty feedback for inline use
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: DifficultyFeedback.values.map((feedback) {
        final isSelected = currentFeedback == feedback;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onFeedback(feedback),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getFeedbackColor(feedback)
                    : _getFeedbackColor(feedback).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feedback.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    feedback.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.neutralWhite
                          : _getFeedbackColor(feedback),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getFeedbackColor(DifficultyFeedback feedback) {
    switch (feedback) {
      case DifficultyFeedback.struggling:
        return AppColors.error;
      case DifficultyFeedback.justRight:
        return AppColors.success;
      case DifficultyFeedback.tooEasy:
        return AppColors.warning;
    }
  }
}
