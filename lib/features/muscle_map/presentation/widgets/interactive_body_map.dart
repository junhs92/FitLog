import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/muscle_activity_entity.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import 'heat_map_colors.dart';
import 'svg_body_map.dart';

/// Interactive body map with heat visualization based on muscle activity
/// Uses SVG-style CustomPainter with partitioned muscle regions
class InteractiveBodyMap extends StatefulWidget {
  /// Muscle activity data to visualize
  final ClientMuscleMapEntity muscleMap;

  /// Callback when a muscle is tapped
  final void Function(MuscleGroup group, MuscleActivityEntity? activity)? onMuscleTap;

  /// Currently selected muscle (highlighted with border)
  final MuscleGroup? selectedMuscle;

  /// Height of the widget
  final double height;

  /// Whether to show legend
  final bool showLegend;

  /// Whether to show muscle labels
  final bool showLabels;

  const InteractiveBodyMap({
    required this.muscleMap,
    this.onMuscleTap,
    this.selectedMuscle,
    this.height = 550,
    this.showLegend = true,
    this.showLabels = false,
    super.key,
  });

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap> {
  @override
  Widget build(BuildContext context) {
    // Convert activity data to intensity map
    final intensities = _buildIntensityMap();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muscle Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SvgBodyMap(
              intensities: intensities,
              height: widget.height,
              selectedMuscle: widget.selectedMuscle,
              showLabels: widget.showLabels,
              onMuscleTap: widget.onMuscleTap != null
                  ? (group) {
                      final activity = widget.muscleMap.frontViewActivities[group] ??
                          widget.muscleMap.backViewActivities[group];
                      widget.onMuscleTap!(group, activity);
                    }
                  : null,
            ),
          ),
          if (widget.showLegend) ...[
            const SizedBox(height: AppSpacing.lg),
            const _HeatMapLegend(),
          ],
        ],
      ),
    );
  }

  Map<MuscleGroup, double> _buildIntensityMap() {
    final intensities = <MuscleGroup, double>{};

    // Add front view activities
    for (final entry in widget.muscleMap.frontViewActivities.entries) {
      intensities[entry.key] = entry.value.intensity;
    }

    // Add back view activities
    for (final entry in widget.muscleMap.backViewActivities.entries) {
      intensities[entry.key] = entry.value.intensity;
    }

    return intensities;
  }
}

class _HeatMapLegend extends StatelessWidget {
  const _HeatMapLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Level',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: HeatMapColors.gradientStops,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: HeatMapColors.gradientLabels
              .map((label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.neutral500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
