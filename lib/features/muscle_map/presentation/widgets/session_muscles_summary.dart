import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import 'heat_map_colors.dart';

/// Widget displaying muscles worked in a session (for post-session summary)
class SessionMusclesSummary extends StatelessWidget {
  /// Muscle activity for the session
  final SessionMuscleActivity sessionActivity;

  /// Whether to show detailed stats
  final bool showDetails;

  /// Callback when tapped
  final VoidCallback? onTap;

  const SessionMusclesSummary({
    required this.sessionActivity,
    this.showDetails = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionActivity.musclesWorked.isEmpty) {
      return const SizedBox.shrink();
    }

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Muscles Worked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                Text(
                  '${sessionActivity.musclesWorked.length} groups',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Muscle chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: sessionActivity.musclesWorked.map((group) {
                final volume = sessionActivity.muscleVolumes[group] ?? 0;
                final sets = sessionActivity.muscleSets[group] ?? 0;
                final maxVolume = sessionActivity.muscleVolumes.values
                    .fold(0, (a, b) => a > b ? a : b);
                final intensity = maxVolume > 0 ? volume / maxVolume : 0.0;
                final color = HeatMapColors.intensityToColor(intensity);

                return _MuscleChip(
                  group: group,
                  volume: volume,
                  sets: sets,
                  color: color,
                  showDetails: showDetails,
                );
              }).toList(),
            ),
            if (showDetails) ...[
              const SizedBox(height: AppSpacing.md),
              // Summary stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStat(
                    label: 'Total Volume',
                    value: _formatVolume(sessionActivity.totalVolume),
                    icon: Icons.fitness_center,
                  ),
                  _SummaryStat(
                    label: 'Total Sets',
                    value: sessionActivity.totalSets.toString(),
                    icon: Icons.repeat,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K kg';
    }
    return '$volume kg';
  }
}

class _MuscleChip extends StatelessWidget {
  final MuscleGroup group;
  final int volume;
  final int sets;
  final Color color;
  final bool showDetails;

  const _MuscleChip({
    required this.group,
    required this.volume,
    required this.sets,
    required this.color,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: showDetails ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                group.displayNameKo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 2),
            Text(
              '$sets sets',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

/// Simple inline display of muscles worked (for compact views)
class SessionMusclesInline extends StatelessWidget {
  final SessionMuscleActivity sessionActivity;
  final int maxDisplay;

  const SessionMusclesInline({
    required this.sessionActivity,
    this.maxDisplay = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionActivity.musclesWorked.isEmpty) {
      return const SizedBox.shrink();
    }

    final muscles = sessionActivity.musclesWorked.take(maxDisplay).toList();
    final remaining = sessionActivity.musclesWorked.length - maxDisplay;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...muscles.map((group) => _SmallMuscleChip(group: group)),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.neutral600,
              ),
            ),
          ),
      ],
    );
  }
}

class _SmallMuscleChip extends StatelessWidget {
  final MuscleGroup group;

  const _SmallMuscleChip({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        group.displayNameKo,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
