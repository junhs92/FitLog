import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_set_entity.dart';

/// Displays a logged set in a compact row format
class SetRow extends StatelessWidget {
  final ExerciseSetEntity set;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isEditable;

  const SetRow({
    required this.set,
    this.onTap,
    this.onDelete,
    this.isEditable = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: set.isWarmup
          ? AppColors.info.withOpacity(0.1)
          : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Set number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: set.isPR
                      ? const Color(0xFFFFD700)
                      : AppColors.neutral300,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  set.isWarmup ? 'W' : set.setNumber.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: set.isPR
                        ? AppColors.neutralBlack
                        : AppColors.neutral700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Weight
              Expanded(
                flex: 2,
                child: _SetValueDisplay(
                  value: set.weight != null
                      ? '${set.weight!.toStringAsFixed(set.weight! % 1 == 0 ? 0 : 1)} kg'
                      : '-',
                  label: 'Weight',
                ),
              ),
              // Reps
              Expanded(
                flex: 2,
                child: _SetValueDisplay(
                  value: set.reps?.toString() ?? '-',
                  label: 'Reps',
                ),
              ),
              // RPE
              Expanded(
                flex: 1,
                child: _SetValueDisplay(
                  value: set.rpeDisplay,
                  label: 'RPE',
                  color: _getRpeColor(set.rpe),
                ),
              ),
              // Tags
              if (set.tags.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ...set.tags.take(2).map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          tag.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              ],
              // Delete button
              if (isEditable && onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.neutral500,
                  onPressed: onDelete,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color? _getRpeColor(double? rpe) {
    if (rpe == null) return null;
    if (rpe <= 6) return AppColors.success;
    if (rpe <= 7) return AppColors.secondary;
    if (rpe <= 8) return AppColors.warning;
    return AppColors.error;
  }
}

class _SetValueDisplay extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _SetValueDisplay({
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.neutralBlack,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}
