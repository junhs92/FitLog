import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Quick log widget for fast set logging
/// Enables 1-tap "Repeat Last Set" and quick presets
class QuickLogWidget extends StatelessWidget {
  /// Last logged set data (weight, reps)
  final double? lastWeight;
  final int? lastReps;

  /// Callback when "Repeat Last Set" is tapped
  final VoidCallback? onRepeatLastSet;

  /// Callback when a preset is tapped
  final void Function(double weight, int reps)? onPresetTap;

  /// Recent presets from this exercise
  final List<SetPreset> recentPresets;

  /// Whether the repeat button is enabled
  final bool canRepeat;

  const QuickLogWidget({
    super.key,
    this.lastWeight,
    this.lastReps,
    this.onRepeatLastSet,
    this.onPresetTap,
    this.recentPresets = const [],
    this.canRepeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Repeat Last Set button (most prominent)
        if (canRepeat && lastWeight != null && lastReps != null)
          _RepeatLastSetButton(
            weight: lastWeight!,
            reps: lastReps!,
            onTap: onRepeatLastSet,
          ),

        // Recent presets
        if (recentPresets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quick presets',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentPresets
                .take(4)
                .map((preset) => _PresetChip(
                      weight: preset.weight,
                      reps: preset.reps,
                      onTap: () => onPresetTap?.call(preset.weight, preset.reps),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// "Repeat Last Set" button - the most prominent action
class _RepeatLastSetButton extends StatelessWidget {
  final double weight;
  final int reps;
  final VoidCallback? onTap;

  const _RepeatLastSetButton({
    required this.weight,
    required this.reps,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.repeat,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat Last Set',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)}kg × $reps reps',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '1 TAP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preset chip for quick selection
class _PresetChip extends StatelessWidget {
  final double weight;
  final int reps;
  final VoidCallback? onTap;

  const _PresetChip({
    required this.weight,
    required this.reps,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weightStr = weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1);

    return ActionChip(
      label: Text('${weightStr}kg × $reps'),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      backgroundColor: AppColors.darkSurfaceCard,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.neutral700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.darkBorder),
      ),
    );
  }
}

/// Quick adjustment buttons for weight
class WeightQuickAdjust extends StatelessWidget {
  final double currentWeight;
  final ValueChanged<double> onChanged;
  final double increment;

  const WeightQuickAdjust({
    super.key,
    required this.currentWeight,
    required this.onChanged,
    this.increment = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease button
        _QuickAdjustButton(
          icon: Icons.remove,
          label: '-${increment.toStringAsFixed(increment.truncateToDouble() == increment ? 0 : 1)}',
          onTap: () {
            final newWeight = (currentWeight - increment).clamp(0.0, 500.0);
            onChanged(newWeight);
          },
        ),
        const SizedBox(width: 16),
        // Current weight display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            '${currentWeight.toStringAsFixed(currentWeight.truncateToDouble() == currentWeight ? 0 : 1)} kg',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Increase button
        _QuickAdjustButton(
          icon: Icons.add,
          label: '+${increment.toStringAsFixed(increment.truncateToDouble() == increment ? 0 : 1)}',
          onTap: () {
            final newWeight = (currentWeight + increment).clamp(0.0, 500.0);
            onChanged(newWeight);
          },
        ),
      ],
    );
  }
}

/// Quick adjustment buttons for reps
class RepsQuickAdjust extends StatelessWidget {
  final int currentReps;
  final ValueChanged<int> onChanged;
  final int increment;

  const RepsQuickAdjust({
    super.key,
    required this.currentReps,
    required this.onChanged,
    this.increment = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease button
        _QuickAdjustButton(
          icon: Icons.remove,
          label: '-$increment',
          onTap: () {
            final newReps = (currentReps - increment).clamp(0, 100);
            onChanged(newReps);
          },
        ),
        const SizedBox(width: 16),
        // Current reps display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            '$currentReps reps',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Increase button
        _QuickAdjustButton(
          icon: Icons.add,
          label: '+$increment',
          onTap: () {
            final newReps = (currentReps + increment).clamp(0, 100);
            onChanged(newReps);
          },
        ),
      ],
    );
  }
}

/// Reusable quick adjust button
class _QuickAdjustButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAdjustButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurfaceCard,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.neutral700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for set presets
class SetPreset {
  final double weight;
  final int reps;
  final DateTime? loggedAt;

  const SetPreset({
    required this.weight,
    required this.reps,
    this.loggedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetPreset && other.weight == weight && other.reps == reps;
  }

  @override
  int get hashCode => weight.hashCode ^ reps.hashCode;
}
