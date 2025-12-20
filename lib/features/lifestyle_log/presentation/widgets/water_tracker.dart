import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/water_log_entity.dart';

/// Widget for tracking daily water intake
class WaterTracker extends StatelessWidget {
  final DailyWaterSummary? summary;
  final Function(int amountMl) onAddWater;
  final VoidCallback? onTap;

  const WaterTracker({
    this.summary,
    required this.onAddWater,
    this.onTap,
    super.key,
  });

  static const List<int> _quickAddOptions = [250, 500, 750];

  @override
  Widget build(BuildContext context) {
    final currentMl = summary?.totalMl ?? 0;
    final goalMl = summary?.goalMl ?? 2500;
    final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

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
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Center(
                      child: Text('💧', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Water',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          '${summary?.displayTotal ?? '0 ml'} / ${summary?.displayGoal ?? '2.5 L'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary?.goalReached ?? false)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Goal!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info.withValues(alpha: 0.7),
                            AppColors.info,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Quick add buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickAddOptions.map((ml) {
                  return _QuickAddButton(
                    amountMl: ml,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onAddWater(ml);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final int amountMl;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.amountMl,
    required this.onTap,
  });

  String get _displayAmount {
    if (amountMl >= 1000) {
      return '${(amountMl / 1000).toStringAsFixed(1)}L';
    }
    return '${amountMl}ml';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.info.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 4),
              Text(
                _displayAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact water display for home screen
class WaterTrackerCompact extends StatelessWidget {
  final DailyWaterSummary? summary;
  final VoidCallback? onTap;

  const WaterTrackerCompact({
    this.summary,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentMl = summary?.totalMl ?? 0;
    final goalMl = summary?.goalMl ?? 2500;
    final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

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
              // Water glass icon with progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.info.withValues(alpha: 0.15),
                      color: AppColors.info,
                      strokeWidth: 4,
                    ),
                  ),
                  const Text('💧', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      summary?.displayTotal ?? '0 ml',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: summary?.goalReached ?? false
                      ? AppColors.success
                      : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
