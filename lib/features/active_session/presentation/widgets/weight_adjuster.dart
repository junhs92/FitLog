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
  final bool compact;

  const WeightAdjuster({
    required this.weight,
    required this.onChanged,
    this.minWeight = 0,
    this.maxWeight = 500,
    this.compact = false,
    super.key,
  });

  static const List<double> _decrementValues = [-10, -5, -2.5];
  static const List<double> _incrementValues = [2.5, 5, 10];
  static const List<double> _compactDecrementValues = [-10, -5, -2.5, -1];
  static const List<double> _compactIncrementValues = [1, 2.5, 5, 10];

  void _adjustWeight(double delta) {
    HapticFeedback.lightImpact();
    final newWeight = (weight + delta).clamp(minWeight, maxWeight);
    onChanged(newWeight);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Weight display with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallAdjustButton(
                icon: Icons.remove,
                onTap: () => _adjustWeight(-0.5),
                isDecrement: true,
                compact: true,
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        weight % 1 == 0
                            ? weight.toInt().toString()
                            : weight.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SmallAdjustButton(
                icon: Icons.add,
                onTap: () => _adjustWeight(0.5),
                isDecrement: false,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Quick adjustment buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._compactDecrementValues.map((value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _WeightButton(
                      value: value,
                      onTap: () => _adjustWeight(value),
                      isDecrement: true,
                      compact: true,
                    ),
                  )),
              const SizedBox(width: 4),
              ..._compactIncrementValues.map((value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _WeightButton(
                      value: value,
                      onTap: () => _adjustWeight(value),
                      isDecrement: false,
                      compact: true,
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current weight display with +/- 0.5kg buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -0.5 button
            _SmallAdjustButton(
              icon: Icons.remove,
              onTap: () => _adjustWeight(-0.5),
              isDecrement: true,
            ),
            const SizedBox(width: AppSpacing.md),
            // Weight display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    weight % 1 == 0
                        ? weight.toInt().toString()
                        : weight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextPrimary,
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
            const SizedBox(width: AppSpacing.md),
            // +0.5 button
            _SmallAdjustButton(
              icon: Icons.add,
              onTap: () => _adjustWeight(0.5),
              isDecrement: false,
            ),
          ],
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

/// Small circular button for +/- 0.5kg adjustments
class _SmallAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDecrement;
  final bool compact;

  const _SmallAdjustButton({
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

/// Button for quick weight adjustments (-10, -5, etc.)
class _WeightButton extends StatelessWidget {
  final double value;
  final VoidCallback onTap;
  final bool isDecrement;
  final bool compact;

  const _WeightButton({
    required this.value,
    required this.onTap,
    required this.isDecrement,
    this.compact = false,
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
          width: compact ? 36 : 48,
          height: compact ? 28 : 44,
          alignment: Alignment.center,
          child: Text(
            '${isDecrement ? "-" : "+"}$displayText',
            style: TextStyle(
              fontSize: compact ? 11 : 14,
              fontWeight: FontWeight.bold,
              color: isDecrement ? AppColors.error : AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
