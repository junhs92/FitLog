import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/rest_timer_service.dart';
import '../providers/rest_timer_provider.dart';

/// Compact rest timer widget for app bar
class RestTimerCompact extends ConsumerWidget {
  final VoidCallback? onTap;

  const RestTimerCompact({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning && !timerState.isPaused) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: timerState.remainingSeconds <= 10
              ? AppColors.warning.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: timerState.progress,
                strokeWidth: 2,
                backgroundColor: AppColors.neutral300,
                valueColor: AlwaysStoppedAnimation(
                  timerState.remainingSeconds <= 10
                      ? AppColors.warning
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timerState.formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: timerState.remainingSeconds <= 10
                    ? AppColors.warning
                    : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full rest timer widget with controls
class RestTimerWidget extends ConsumerWidget {
  final bool showControls;
  final bool showPresets;

  const RestTimerWidget({
    super.key,
    this.showControls = true,
    this.showPresets = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          _TimerDisplay(
            remainingSeconds: timerState.remainingSeconds,
            progress: timerState.progress,
            isRunning: timerState.isRunning,
          ),

          if (showControls) ...[
            const SizedBox(height: AppSpacing.md),
            // Control buttons: reset, start/pause, add, skip
            _TimerControls(
              isRunning: timerState.isRunning,
              isPaused: timerState.isPaused,
              onStart: () => notifier.startTimer(),
              onPause: notifier.pauseTimer,
              onResume: notifier.resumeTimer,
              onReset: notifier.resetTimer,
              onAddTime: () => notifier.addTime(30),
              onSkip: notifier.skipTimer,
            ),
          ],

          if (showPresets) ...[
            const SizedBox(height: AppSpacing.md),
            // Preset duration buttons (selection only, doesn't start timer)
            _PresetButtons(
              currentDuration: timerState.totalSeconds,
              onPresetSelected: (seconds) {
                // Only set the duration, don't start the timer
                notifier.setDefaultDuration(seconds);
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular timer display
class _TimerDisplay extends StatelessWidget {
  final int remainingSeconds;
  final double progress;
  final bool isRunning;

  const _TimerDisplay({
    required this.remainingSeconds,
    required this.progress,
    required this.isRunning,
  });

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = remainingSeconds <= 10 && remainingSeconds > 0;
    final isComplete = remainingSeconds == 0 && !isRunning;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation(Colors.transparent),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                isComplete
                    ? AppColors.success
                    : isWarning
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ),
          ),
          // Time text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isComplete
                      ? AppColors.success
                      : isWarning
                          ? AppColors.warning
                          : AppColors.neutralBlack,
                ),
              ),
              if (isComplete)
                Text(
                  'REST DONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Timer control buttons: reset, start/pause, add
class _TimerControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onAddTime;
  final VoidCallback? onSkip;

  const _TimerControls({
    required this.isRunning,
    required this.isPaused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onAddTime,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        IconButton(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.neutral100,
          ),
        ),

        const SizedBox(width: 16),

        // Play/Pause button (larger)
        if (isRunning)
          IconButton.filled(
            onPressed: onPause,
            icon: const Icon(Icons.pause, size: 28),
            tooltip: 'Pause',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.neutralWhite,
              minimumSize: const Size(56, 56),
            ),
          )
        else if (isPaused)
          IconButton.filled(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow, size: 28),
            tooltip: 'Resume',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.neutralWhite,
              minimumSize: const Size(56, 56),
            ),
          )
        else
          IconButton.filled(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow, size: 28),
            tooltip: 'Start',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.neutralWhite,
              minimumSize: const Size(56, 56),
            ),
          ),

        const SizedBox(width: 16),

        // Add 30s button with label
        Material(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onAddTime,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Text(
                '+30s',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
            ),
          ),
        ),

        // Skip button
        if (onSkip != null && (isRunning || isPaused)) ...[
          const SizedBox(width: 16),
          Material(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onSkip,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.skip_next, size: 18, color: AppColors.neutral700),
                    SizedBox(width: 4),
                    Text(
                      '건너뛰기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Preset duration buttons
class _PresetButtons extends StatelessWidget {
  final int currentDuration;
  final ValueChanged<int> onPresetSelected;

  const _PresetButtons({
    required this.currentDuration,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: RestTimerService.presetDurations.map((seconds) {
          final isSelected = currentDuration == seconds;
          final label = seconds >= 60
              ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
              : '${seconds}s';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onPresetSelected(seconds),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
              ),
              backgroundColor: AppColors.neutral100,
              selectedColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bottom sheet for expanded timer view
class RestTimerBottomSheet extends StatelessWidget {
  const RestTimerBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RestTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rest Timer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Timer widget
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: RestTimerWidget(
              showControls: true,
              showPresets: true,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}
