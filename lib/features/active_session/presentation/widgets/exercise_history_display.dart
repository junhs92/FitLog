import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_set_entity.dart';

/// Widget displaying exercise PR and last session sets
class ExerciseHistoryDisplay extends StatelessWidget {
  final ExerciseSetEntity? pr;
  final List<ExerciseSetEntity> lastSessionSets;

  const ExerciseHistoryDisplay({
    required this.pr,
    required this.lastSessionSets,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory = pr != null || lastSessionSets.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: AppColors.neutral700,
              ),
              const SizedBox(width: 6),
              const Text(
                '기록',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (!hasHistory) ...[
            // No history message
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: const Center(
                child: Text(
                  '기록 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // PR section
            if (pr != null) ...[
              _PRSection(pr: pr!),
              if (lastSessionSets.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
            ],

            // Last session section
            if (lastSessionSets.isNotEmpty)
              _LastSessionSection(sets: lastSessionSets),
          ],
        ],
      ),
    );
  }
}

class _PRSection extends StatelessWidget {
  final ExerciseSetEntity pr;

  const _PRSection({required this.pr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          const Text(
            'PR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          const Spacer(),
          Text(
            _formatSet(pr),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralBlack,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSet(ExerciseSetEntity set) {
    final weight = set.weight?.toStringAsFixed(
        set.weight! % 1 == 0 ? 0 : 1);
    final reps = set.reps;
    if (weight != null && reps != null) {
      return '${weight}kg x $reps회';
    } else if (weight != null) {
      return '${weight}kg';
    } else if (reps != null) {
      return '$reps회';
    }
    return '-';
  }
}

class _LastSessionSection extends StatelessWidget {
  final List<ExerciseSetEntity> sets;

  const _LastSessionSection({required this.sets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.neutral600,
            ),
            const SizedBox(width: 6),
            const Text(
              '지난 세션',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: sets.take(5).map((set) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatSet(set),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatSet(ExerciseSetEntity set) {
    final weight = set.weight?.toStringAsFixed(
        set.weight! % 1 == 0 ? 0 : 1);
    final reps = set.reps;
    if (weight != null && reps != null) {
      return '${weight}kg x $reps';
    } else if (weight != null) {
      return '${weight}kg';
    } else if (reps != null) {
      return '$reps회';
    }
    return '-';
  }
}
