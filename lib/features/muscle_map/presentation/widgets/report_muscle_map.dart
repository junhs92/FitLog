import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import 'heat_map_colors.dart';
import 'svg_body_map.dart';

/// Compact, non-interactive muscle map for AI report cards
/// Uses SVG-style CustomPainter with partitioned muscle regions
class ReportMuscleMap extends StatelessWidget {
  /// Muscle activity for the session
  final SessionMuscleActivity sessionActivity;

  /// Whether to show volume details
  final bool showVolume;

  const ReportMuscleMap({
    required this.sessionActivity,
    this.showVolume = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionActivity.musclesWorked.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max volume for intensity normalization
    final maxVolume = sessionActivity.muscleVolumes.values
        .fold(0, (a, b) => a > b ? a : b);

    // Build muscle intensity map
    final muscleIntensities = <MuscleGroup, double>{};
    for (final group in sessionActivity.musclesWorked) {
      final volume = sessionActivity.muscleVolumes[group] ?? 0;
      muscleIntensities[group] = maxVolume > 0 ? volume / maxVolume : 0.0;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.accessibility_new,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Muscles Worked',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralBlack,
                ),
              ),
              const Spacer(),
              Text(
                '${sessionActivity.musclesWorked.length} groups',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // SVG-based body map
          Center(
            child: SvgBodyMap(
              intensities: muscleIntensities,
              height: 240,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Muscle chips with volume
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: sessionActivity.musclesWorked.map((group) {
              final volume = sessionActivity.muscleVolumes[group] ?? 0;
              final sets = sessionActivity.muscleSets[group] ?? 0;
              final intensity = maxVolume > 0 ? volume / maxVolume : 0.0;

              return _MuscleVolumeChip(
                group: group,
                volume: volume,
                sets: sets,
                intensity: intensity,
                showVolume: showVolume,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MuscleVolumeChip extends StatelessWidget {
  final MuscleGroup group;
  final int volume;
  final int sets;
  final double intensity;
  final bool showVolume;

  const _MuscleVolumeChip({
    required this.group,
    required this.volume,
    required this.sets,
    required this.intensity,
    required this.showVolume,
  });

  @override
  Widget build(BuildContext context) {
    final color = HeatMapColors.intensityToColor(intensity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            group.displayNameKo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (showVolume) ...[
            const SizedBox(width: 4),
            Text(
              '${sets}s',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
