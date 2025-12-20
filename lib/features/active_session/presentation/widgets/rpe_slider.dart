import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Visual RPE (Rate of Perceived Exertion) slider for quick input
class RpeSlider extends StatelessWidget {
  final double? rpe;
  final ValueChanged<double> onChanged;
  final double minRpe;
  final double maxRpe;

  const RpeSlider({
    this.rpe,
    required this.onChanged,
    this.minRpe = 5,
    this.maxRpe = 10,
    super.key,
  });

  static const Map<int, String> _rpeDescriptions = {
    5: 'Easy',
    6: 'Moderate',
    7: 'Challenging',
    8: 'Hard',
    9: 'Very Hard',
    10: 'Maximum',
  };

  static const Map<int, String> _rpeEmojis = {
    5: '😊',
    6: '🙂',
    7: '😐',
    8: '😤',
    9: '😰',
    10: '💀',
  };

  Color _getRpeColor(double value) {
    if (value <= 6) return AppColors.success;
    if (value <= 7) return AppColors.secondary;
    if (value <= 8) return AppColors.warning;
    return AppColors.error;
  }

  void _selectRpe(double value) {
    HapticFeedback.lightImpact();
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current RPE display
        if (rpe != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _rpeEmojis[rpe!.round()] ?? '',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RPE ${rpe!.toStringAsFixed(rpe! % 1 == 0 ? 0 : 1)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRpeColor(rpe!),
                    ),
                  ),
                  Text(
                    _rpeDescriptions[rpe!.round()] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        // RPE buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            (maxRpe - minRpe).toInt() + 1,
            (index) {
              final value = minRpe + index;
              final isSelected = rpe == value;
              return _RpeButton(
                value: value,
                isSelected: isSelected,
                color: _getRpeColor(value),
                onTap: () => _selectRpe(value),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Easy',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral700,
              ),
            ),
            Text(
              'Max',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RpeButton extends StatelessWidget {
  final double value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RpeButton({
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : color.withOpacity(0.15),
      shape: const CircleBorder(),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.neutralWhite : color,
            ),
          ),
        ),
      ),
    );
  }
}
