import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Zero-typing weight adjustment widget with quick increment/decrement buttons
class WeightAdjuster extends StatelessWidget {
  final double weight;
  final ValueChanged<double> onChanged;
  final double minWeight;
  final double maxWeight;

  const WeightAdjuster({
    required this.weight,
    required this.onChanged,
    this.minWeight = 0,
    this.maxWeight = 500,
    super.key,
  });

  static const List<double> _decrementValues = [-10, -5, -2.5];
  static const List<double> _incrementValues = [2.5, 5, 10];

  void _adjustWeight(double delta) {
    HapticFeedback.lightImpact();
    final newWeight = (weight + delta).clamp(minWeight, maxWeight);
    onChanged(newWeight);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current weight display
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                'kg',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Weight adjustment buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement buttons
              ..._decrementValues.map((value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WeightButton(
                      value: value,
                      onTap: () => _adjustWeight(value),
                      isDecrement: true,
                    ),
                  )),
              const SizedBox(width: AppSpacing.sm),
              // Increment buttons
              ..._incrementValues.map((value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WeightButton(
                      value: value,
                      onTap: () => _adjustWeight(value),
                      isDecrement: false,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightButton extends StatelessWidget {
  final double value;
  final VoidCallback onTap;
  final bool isDecrement;

  const _WeightButton({
    required this.value,
    required this.onTap,
    required this.isDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.abs();
    final displayText = displayValue % 1 == 0
        ? displayValue.toInt().toString()
        : displayValue.toStringAsFixed(1);

    return Material(
      color: isDecrement
          ? AppColors.error.withOpacity(0.1)
          : AppColors.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          child: Text(
            '${isDecrement ? "-" : "+"}$displayText',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDecrement ? AppColors.error : AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
