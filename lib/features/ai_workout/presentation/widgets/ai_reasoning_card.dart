import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/ai_reasoning.dart';

/// Card displaying AI reasoning for exercise selection
class AIReasoningCard extends StatelessWidget {
  final AIExerciseReasoning reasoning;
  final VoidCallback? onTap;

  const AIReasoningCard({
    required this.reasoning,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final topReasons = reasoning.getTopReasons(3);

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'AI 선택 이유',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                  ),
                  _ScoreIndicator(score: reasoning.overallScore),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...topReasons.map((reason) => _ReasoningItem(reason: reason)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  final double score;

  const _ScoreIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = score >= 0.8
        ? AppColors.success
        : score >= 0.6
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _ReasoningItem extends StatelessWidget {
  final AIReasoningPoint reason;

  const _ReasoningItem({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getCategoryIcon(reason.category),
            size: 16,
            color: AppColors.primary,
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
                    color: AppColors.neutral700,
                  ),
                ),
                Text(
                  reason.displayExplanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
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

/// Compact version for inline display
class AIReasoningCompact extends StatelessWidget {
  final AIExerciseReasoning reasoning;

  const AIReasoningCompact({
    required this.reasoning,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final topReason = reasoning.getTopReasons(1).firstOrNull;
    if (topReason == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.psychology,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              topReason.displayExplanation,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
