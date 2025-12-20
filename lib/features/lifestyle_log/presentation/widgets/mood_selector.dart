import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/mood_log_entity.dart';

/// Widget for selecting mood and energy levels
class MoodSelector extends StatelessWidget {
  final MoodLogEntity? mood;
  final VoidCallback onTap;
  final Function(MoodLevel)? onMoodChanged;
  final Function(EnergyLevel)? onEnergyChanged;

  const MoodSelector({
    this.mood,
    required this.onTap,
    this.onMoodChanged,
    this.onEnergyChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = mood != null && (mood!.mood != null || mood!.energy != null);

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
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        mood?.moodEmoji ?? '🙂',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mood & Energy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          hasData
                              ? '${mood!.moodName ?? ''} ${mood!.energyEmoji ?? ''}'
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
              if (onMoodChanged != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MoodLevelSelector(
                  selected: mood?.mood,
                  onChanged: onMoodChanged!,
                ),
              ],
              if (onEnergyChanged != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Energy level',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                EnergyLevelSelector(
                  selected: mood?.energy,
                  onChanged: onEnergyChanged!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mood level selector row
class MoodLevelSelector extends StatelessWidget {
  final MoodLevel? selected;
  final Function(MoodLevel) onChanged;

  const MoodLevelSelector({
    this.selected,
    required this.onChanged,
    super.key,
  });

  static const Map<MoodLevel, String> _emojis = {
    MoodLevel.veryLow: '😢',
    MoodLevel.low: '😕',
    MoodLevel.neutral: '😐',
    MoodLevel.good: '🙂',
    MoodLevel.excellent: '😄',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodLevel.values.map((level) {
        final isSelected = selected == level;
        return _EmojiButton(
          emoji: _emojis[level]!,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(level);
          },
        );
      }).toList(),
    );
  }
}

/// Energy level selector row
class EnergyLevelSelector extends StatelessWidget {
  final EnergyLevel? selected;
  final Function(EnergyLevel) onChanged;

  const EnergyLevelSelector({
    this.selected,
    required this.onChanged,
    super.key,
  });

  static const Map<EnergyLevel, String> _emojis = {
    EnergyLevel.exhausted: '🪫',
    EnergyLevel.tired: '😴',
    EnergyLevel.normal: '⚡',
    EnergyLevel.energetic: '💪',
    EnergyLevel.veryEnergetic: '🔥',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: EnergyLevel.values.map((level) {
        final isSelected = selected == level;
        return _EmojiButton(
          emoji: _emojis[level]!,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(level);
          },
        );
      }).toList(),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.secondary.withValues(alpha: 0.15)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: AppColors.secondary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: isSelected ? 28 : 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact mood display for home screen
class MoodSelectorCompact extends StatelessWidget {
  final MoodLogEntity? mood;
  final VoidCallback? onTap;

  const MoodSelectorCompact({
    this.mood,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = mood != null && mood!.mood != null;

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
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    mood?.moodEmoji ?? '🙂',
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
                      'Mood',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      hasData ? mood!.moodName ?? '--' : 'Not logged',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            hasData ? AppColors.secondary : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (mood?.energy != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mood!.energyEmoji ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mood!.energyName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
