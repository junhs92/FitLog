import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/muscle_activity_entity.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import 'svg_body_map.dart';

/// Compact muscle map widget for dashboard cards and summaries
/// Uses SVG-style CustomPainter with partitioned muscle regions
class MiniMuscleMap extends StatelessWidget {
  /// Muscle activity data to visualize
  final ClientMuscleMapEntity muscleMap;

  /// Height of the widget (default 180)
  final double height;

  /// Callback when tapped (for navigation to full map)
  final VoidCallback? onTap;

  /// Whether to show the title
  final bool showTitle;

  /// Whether to show needs attention indicator
  final bool showNeedsAttention;

  const MiniMuscleMap({
    required this.muscleMap,
    this.height = 280,
    this.onTap,
    this.showTitle = true,
    this.showNeedsAttention = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final needsAttention = muscleMap.musclesNeedingAttention;

    // Build intensity map from activities
    final intensities = _buildIntensityMap();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Muscle Activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.neutral500,
                    ),
                ],
              ),
            if (showTitle) const SizedBox(height: AppSpacing.sm),
            // SVG-based body map
            Center(
              child: SvgBodyMap(
                intensities: intensities,
                height: height,
              ),
            ),
            if (showNeedsAttention && needsAttention.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _NeedsAttentionBadge(muscles: needsAttention),
            ],
          ],
        ),
      ),
    );
  }

  Map<MuscleGroup, double> _buildIntensityMap() {
    final intensities = <MuscleGroup, double>{};

    // Add front view activities
    for (final entry in muscleMap.frontViewActivities.entries) {
      intensities[entry.key] = entry.value.intensity;
    }

    // Add back view activities
    for (final entry in muscleMap.backViewActivities.entries) {
      intensities[entry.key] = entry.value.intensity;
    }

    return intensities;
  }
}

class _NeedsAttentionBadge extends StatelessWidget {
  final List<MuscleActivityEntity> muscles;

  const _NeedsAttentionBadge({required this.muscles});

  @override
  Widget build(BuildContext context) {
    final displayMuscles = muscles.take(3).toList();
    final remaining = muscles.length - 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              remaining > 0
                  ? '${displayMuscles.map((m) => m.muscleGroup.displayNameKo).join(', ')} +$remaining need work'
                  : '${displayMuscles.map((m) => m.muscleGroup.displayNameKo).join(', ')} need work',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warning,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
