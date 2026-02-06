import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/muscle_activity_entity.dart';
import 'heat_map_colors.dart';

/// Card displaying detailed information about a muscle's activity
class MuscleActivityCard extends StatelessWidget {
  /// The muscle activity to display
  final MuscleActivityEntity activity;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  const MuscleActivityCard({
    required this.activity,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = HeatMapColors.intensityToColor(activity.intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Muscle name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.muscleGroup.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      Text(
                        activity.muscleGroup.displayNameKo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(activity).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(activity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Stats row
            Row(
              children: [
                _StatItem(
                  icon: Icons.fitness_center,
                  label: 'Volume',
                  value: _formatVolume(activity.totalVolume),
                ),
                const SizedBox(width: AppSpacing.lg),
                _StatItem(
                  icon: Icons.repeat,
                  label: 'Sets',
                  value: activity.totalSets.toString(),
                ),
                const SizedBox(width: AppSpacing.lg),
                _StatItem(
                  icon: Icons.calendar_today,
                  label: 'Sessions',
                  value: activity.sessionCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Last worked
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _getLastWorkedText(activity),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
            // Intensity bar
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: activity.intensity,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(MuscleActivityEntity activity) {
    if (activity.needsAttention) {
      return AppColors.warning;
    } else if (activity.isRecent) {
      return AppColors.success;
    } else if (activity.daysSinceWorked == null) {
      return AppColors.neutral500;
    } else {
      return AppColors.info;
    }
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M kg';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K kg';
    }
    return '$volume kg';
  }

  String _getLastWorkedText(MuscleActivityEntity activity) {
    if (activity.daysSinceWorked == null) {
      return 'Never worked';
    } else if (activity.daysSinceWorked == 0) {
      return 'Last worked today';
    } else if (activity.daysSinceWorked == 1) {
      return 'Last worked yesterday';
    } else {
      return 'Last worked ${activity.daysSinceWorked} days ago';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.neutral500),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutralBlack,
          ),
        ),
      ],
    );
  }
}

/// Compact version of muscle activity card for lists
class MuscleActivityListTile extends StatelessWidget {
  final MuscleActivityEntity activity;
  final VoidCallback? onTap;

  const MuscleActivityListTile({
    required this.activity,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = HeatMapColors.intensityToColor(activity.intensity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.muscleGroup.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  Text(
                    '${activity.totalSets} sets • ${activity.sessionCount} sessions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              activity.statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.neutral400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
