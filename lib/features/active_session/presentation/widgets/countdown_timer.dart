import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Countdown timer widget for isometric exercises
/// Timer logic is managed in the provider for background execution
class CountdownTimer extends StatelessWidget {
  final Duration duration;
  final Duration remaining;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<Duration> onDurationChanged;

  /// Quick preset durations in seconds
  static const List<int> presets = [15, 30, 45, 60, 90, 120];

  const CountdownTimer({
    required this.duration,
    required this.remaining,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onDurationChanged,
    super.key,
  });

  String _formatTime(Duration dur) {
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds.remainder(60);
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(double progress) {
    if (progress > 0.5) return AppColors.success;
    if (progress > 0.25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inSeconds > 0
        ? remaining.inSeconds / duration.inSeconds
        : 0.0;
    final timerColor = _getTimerColor(progress);

    return Column(
      children: [
        // Quick preset buttons
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: CountdownTimer.presets.map((seconds) {
            final isSelected = duration.inSeconds == seconds;
            return _PresetButton(
              seconds: seconds,
              isSelected: isSelected,
              onTap: () => onDurationChanged(Duration(seconds: seconds)),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Circular countdown display
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 8,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              ),
            ),
            // Time display
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(remaining),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'of ${_formatTime(duration)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start/Pause button
            _ControlButton(
              icon: isRunning ? Icons.pause : Icons.play_arrow,
              label: isRunning ? 'Pause' : 'Start',
              isPrimary: true,
              onTap: () {
                HapticFeedback.lightImpact();
                if (isRunning) {
                  onPause();
                } else {
                  onStart();
                }
              },
            ),
            const SizedBox(width: AppSpacing.md),
            // Reset button
            _ControlButton(
              icon: Icons.refresh,
              label: 'Reset',
              isPrimary: false,
              onTap: () {
                HapticFeedback.lightImpact();
                onReset();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final int seconds;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.seconds,
    required this.isSelected,
    required this.onTap,
  });

  String _formatPreset() {
    if (seconds >= 60) {
      return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.darkSurfaceCard,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            _formatPreset(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.darkSurfaceCard,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isPrimary ? Colors.white : AppColors.neutral700,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
