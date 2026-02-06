import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_stats_entity.dart';

/// Compact card showing exercise performance statistics
class ExerciseStatsCard extends StatelessWidget {
  final ExerciseStatsEntity stats;
  final VoidCallback? onTap;

  const ExerciseStatsCard({
    required this.stats,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name and muscle group
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _MuscleGroupChip(muscleGroup: stats.muscleGroup),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Stats row
            Row(
              children: [
                _StatItem(
                  label: '최고중량',
                  value: stats.maxWeightDisplay,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatItem(
                  label: '1RM',
                  value: stats.estimated1RMDisplay,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Bottom row: sessions and last performed
            Row(
              children: [
                Text(
                  '${stats.timesPerformed}회 수행',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral700,
                  ),
                ),
                const Spacer(),
                Text(
                  '마지막: ${stats.lastPerformedDisplay}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip showing muscle group
class _MuscleGroupChip extends StatelessWidget {
  final String muscleGroup;

  const _MuscleGroupChip({required this.muscleGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getColorForMuscleGroup(muscleGroup).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: _getColorForMuscleGroup(muscleGroup).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        _getMuscleGroupDisplayName(muscleGroup),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getColorForMuscleGroup(muscleGroup),
        ),
      ),
    );
  }

  Color _getColorForMuscleGroup(String group) {
    switch (group.toLowerCase()) {
      case 'chest':
        return const Color(0xFFE53935); // Red
      case 'back':
        return const Color(0xFF1E88E5); // Blue
      case 'shoulders':
        return const Color(0xFF7CB342); // Green
      case 'arms':
      case 'biceps':
      case 'triceps':
        return const Color(0xFFFB8C00); // Orange
      case 'legs':
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
        return const Color(0xFF8E24AA); // Purple
      case 'core':
      case 'abs':
        return const Color(0xFF00ACC1); // Cyan
      default:
        return AppColors.neutral600;
    }
  }

  String _getMuscleGroupDisplayName(String group) {
    switch (group.toLowerCase()) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'biceps':
        return '이두';
      case 'triceps':
        return '삼두';
      case 'legs':
        return '하체';
      case 'quadriceps':
        return '대퇴사두';
      case 'hamstrings':
        return '햄스트링';
      case 'glutes':
        return '둔근';
      case 'calves':
        return '종아리';
      case 'core':
      case 'abs':
        return '코어';
      default:
        return '기타';
    }
  }
}

/// Small stat display item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
