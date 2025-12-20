import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_entity.dart';

/// Exercise card for quick selection
class ExerciseCard extends StatelessWidget {
  final ExerciseEntity exercise;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showHistory;
  final String? lastPerformed;

  const ExerciseCard({
    required this.exercise,
    required this.onTap,
    this.isSelected = false,
    this.showHistory = false,
    this.lastPerformed,
    super.key,
  });

  IconData _getMovementPatternIcon() {
    switch (exercise.movementPattern) {
      case MovementPattern.squat:
        return Icons.accessibility_new;
      case MovementPattern.hinge:
        return Icons.fitness_center;
      case MovementPattern.horizontalPush:
        return Icons.arrow_forward;
      case MovementPattern.horizontalPull:
        return Icons.arrow_back;
      case MovementPattern.verticalPush:
        return Icons.arrow_upward;
      case MovementPattern.verticalPull:
        return Icons.arrow_downward;
      case MovementPattern.carry:
        return Icons.shopping_bag;
      case MovementPattern.rotation:
        return Icons.rotate_right;
      case MovementPattern.cardio:
        return Icons.directions_run;
      default:
        return Icons.sports_gymnastics;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.neutral300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  _getMovementPatternIcon(),
                  color: isSelected ? AppColors.neutralWhite : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          MovementPattern.getDisplayName(exercise.movementPattern),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral700,
                          ),
                        ),
                        if (exercise.equipment != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                          Text(
                            exercise.equipment!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showHistory && lastPerformed != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last: $lastPerformed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact exercise card for grid view
class ExerciseCardCompact extends StatelessWidget {
  final ExerciseEntity exercise;
  final VoidCallback onTap;

  const ExerciseCardCompact({
    required this.exercise,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                exercise.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
