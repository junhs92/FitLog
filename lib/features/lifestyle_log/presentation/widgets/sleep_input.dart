import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/sleep_log_entity.dart';

/// Widget for logging sleep data
class SleepInput extends StatelessWidget {
  final SleepLogEntity? sleep;
  final VoidCallback onTap;
  final Function(SleepQuality)? onQualityChanged;

  const SleepInput({
    this.sleep,
    required this.onTap,
    this.onQualityChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = sleep != null && sleep!.duration != null;

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Center(
                      child: Text('😴', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sleep',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          hasData
                              ? sleep!.durationDisplay ?? 'No duration'
                              : 'Tap to log',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasData
                                ? AppColors.success
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasData)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.neutral400,
                      size: 24,
                    ),
                ],
              ),
              if (hasData) ...[
                const SizedBox(height: AppSpacing.md),
                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TimeDisplay(
                      label: 'Bedtime',
                      time: sleep!.bedtime,
                      icon: Icons.bedtime,
                    ),
                    Container(
                      width: 40,
                      height: 2,
                      color: AppColors.neutral300,
                    ),
                    _TimeDisplay(
                      label: 'Wake up',
                      time: sleep!.wakeTime,
                      icon: Icons.wb_sunny,
                    ),
                  ],
                ),
                if (onQualityChanged != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'How did you sleep?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SleepQualitySelector(
                    selected: sleep?.quality,
                    onChanged: onQualityChanged!,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final String label;
  final DateTime? time;
  final IconData icon;

  const _TimeDisplay({
    required this.label,
    this.time,
    required this.icon,
  });

  String get _formattedTime {
    if (time == null) return '--:--';
    final hour = time!.hour.toString().padLeft(2, '0');
    final minute = time!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral500),
        const SizedBox(height: 4),
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

/// Sleep quality selector with emojis
class SleepQualitySelector extends StatelessWidget {
  final SleepQuality? selected;
  final Function(SleepQuality) onChanged;

  const SleepQualitySelector({
    this.selected,
    required this.onChanged,
    super.key,
  });

  static const Map<SleepQuality, String> _emojis = {
    SleepQuality.poor: '😫',
    SleepQuality.fair: '😐',
    SleepQuality.good: '😊',
    SleepQuality.excellent: '😴',
  };

  static const Map<SleepQuality, String> _labels = {
    SleepQuality.poor: 'Poor',
    SleepQuality.fair: 'Fair',
    SleepQuality.good: 'Good',
    SleepQuality.excellent: 'Great',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: SleepQuality.values.map((quality) {
        final isSelected = selected == quality;
        return _QualityButton(
          emoji: _emojis[quality]!,
          label: _labels[quality]!,
          isSelected: isSelected,
          color: Color(getSleepQualityColorValue(quality)),
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(quality);
          },
        );
      }).toList(),
    );
  }

  static int getSleepQualityColorValue(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 0xFFE53935;
      case SleepQuality.fair:
        return 0xFFFFA726;
      case SleepQuality.good:
        return 0xFF66BB6A;
      case SleepQuality.excellent:
        return 0xFF42A5F5;
    }
  }
}

class _QualityButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _QualityButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact sleep display for home screen
class SleepInputCompact extends StatelessWidget {
  final SleepLogEntity? sleep;
  final VoidCallback? onTap;

  const SleepInputCompact({
    this.sleep,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = sleep != null && sleep!.duration != null;

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    sleep?.qualityEmoji ?? '😴',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sleep',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      hasData ? sleep!.durationDisplay ?? '--' : 'Not logged',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasData
                            ? const Color(0xFF7C4DFF)
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (sleep?.qualityName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(sleep!.qualityColorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sleep!.qualityName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(sleep!.qualityColorValue),
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
