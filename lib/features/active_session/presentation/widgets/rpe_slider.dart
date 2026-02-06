import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Visual RPE (Rate of Perceived Exertion) selector with +/- adjustment
class RpeSlider extends StatelessWidget {
  final double? rpe;
  final ValueChanged<double> onChanged;
  final double minRpe;
  final double maxRpe;
  final bool compact;

  const RpeSlider({
    this.rpe,
    required this.onChanged,
    this.minRpe = 4,
    this.maxRpe = 9,
    this.compact = false,
    super.key,
  });

  // Full range for +/- buttons
  static const double _buttonMinRpe = 1;
  static const double _buttonMaxRpe = 10;

  static const Map<int, String> _rpeDescriptions = {
    1: 'Very Light',
    2: 'Light',
    3: 'Light+',
    4: 'Fairly Light',
    5: 'Easy',
    6: 'Moderate',
    7: 'Challenging',
    8: 'Hard',
    9: 'Very Hard',
    10: 'Maximum',
  };

  static const Map<int, String> _rpeEmojis = {
    1: '😴',
    2: '😌',
    3: '🙂',
    4: '😊',
    5: '😊',
    6: '🙂',
    7: '😐',
    8: '😤',
    9: '😰',
    10: '💀',
  };

  Color _getRpeColor(double value) {
    if (value <= 4) return AppColors.success;
    if (value <= 6) return AppColors.success;
    if (value <= 7) return AppColors.secondary;
    if (value <= 8) return AppColors.warning;
    return AppColors.error;
  }

  void _selectRpe(double value) {
    HapticFeedback.lightImpact();
    onChanged(value);
  }

  void _adjustRpe(double delta) {
    HapticFeedback.lightImpact();
    final currentValue = rpe ?? 7; // Default to 7 if not set
    // Use full 1-10 range for +/- buttons
    final newValue = (currentValue + delta).clamp(_buttonMinRpe, _buttonMaxRpe);
    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    final currentRpe = rpe ?? 7;
    final rpeColor = _getRpeColor(currentRpe);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          // RPE display with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdjustButton(
                icon: Icons.remove,
                onTap: () => _adjustRpe(-1),
                isDecrement: true,
                compact: true,
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _rpeEmojis[currentRpe.round()] ?? '',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentRpe.toStringAsFixed(currentRpe % 1 == 0 ? 0 : 1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: rpeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _AdjustButton(
                icon: Icons.add,
                onTap: () => _adjustRpe(1),
                isDecrement: false,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Quick RPE buttons (6-9 for compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [6, 7, 8, 9].map((value) {
              final isSelected = rpe == value.toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _RpeButton(
                  value: value.toDouble(),
                  isSelected: isSelected,
                  color: _getRpeColor(value.toDouble()),
                  onTap: () => _selectRpe(value.toDouble()),
                  compact: true,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    final currentRpe = rpe ?? 7;
    final rpeColor = _getRpeColor(currentRpe);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current RPE display with +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrement button
            _AdjustButton(
              icon: Icons.remove,
              onTap: () => _adjustRpe(-1),
              isDecrement: true,
            ),
            const SizedBox(width: AppSpacing.md),
            // RPE display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: rpeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: rpeColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rpeEmojis[currentRpe.round()] ?? '',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RPE ${currentRpe.toStringAsFixed(currentRpe % 1 == 0 ? 0 : 1)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: rpeColor,
                        ),
                      ),
                      Text(
                        _rpeDescriptions[currentRpe.round()] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Increment button
            _AdjustButton(
              icon: Icons.add,
              onTap: () => _adjustRpe(1),
              isDecrement: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // RPE selector buttons (5-10 range)
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

class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDecrement;
  final bool compact;

  const _AdjustButton({
    required this.icon,
    required this.onTap,
    required this.isDecrement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 48.0;
    final iconSize = compact ? 18.0 : 24.0;

    return Material(
      color: isDecrement
          ? AppColors.error.withOpacity(0.1)
          : AppColors.success.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: iconSize,
            color: isDecrement ? AppColors.error : AppColors.success,
          ),
        ),
      ),
    );
  }
}

class _RpeButton extends StatelessWidget {
  final double value;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _RpeButton({
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 44.0;
    final fontSize = compact ? 12.0 : 16.0;

    return Material(
      color: isSelected ? color : color.withOpacity(0.15),
      shape: const CircleBorder(),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.neutralWhite : color,
            ),
          ),
        ),
      ),
    );
  }
}
