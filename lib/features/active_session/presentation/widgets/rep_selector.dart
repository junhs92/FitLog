import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Zero-typing rep selector with quick-tap buttons
class RepSelector extends StatelessWidget {
  final int reps;
  final ValueChanged<int> onChanged;
  final int minReps;
  final int maxReps;
  final List<int>? quickSelectValues;
  final bool compact;

  const RepSelector({
    required this.reps,
    required this.onChanged,
    this.minReps = 1,
    this.maxReps = 30,
    this.quickSelectValues,
    this.compact = false,
    super.key,
  });

  static const List<int> _defaultQuickValues = [3, 5, 8, 12, 15, 20];
  static const List<int> _compactQuickValues = [3, 5, 8, 10, 12, 15, 20];

  List<int> get _quickValues =>
      quickSelectValues ?? (compact ? _compactQuickValues : _defaultQuickValues);

  void _selectReps(int value) {
    HapticFeedback.lightImpact();
    onChanged(value);
  }

  void _adjustReps(int delta) {
    HapticFeedback.selectionClick();
    final newReps = (reps + delta).clamp(minReps, maxReps);
    onChanged(newReps);
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          // Reps display with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.remove,
                onTap: () => _adjustReps(-1),
                color: AppColors.neutral700,
                compact: true,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    reps.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                ),
              ),
              _RoundButton(
                icon: Icons.add,
                onTap: () => _adjustReps(1),
                color: AppColors.primary,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Quick select buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickValues.map((value) {
              final isSelected = reps == value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _QuickRepButton(
                  value: value,
                  isSelected: isSelected,
                  onTap: () => _selectReps(value),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current reps display with +/- controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus button
            _RoundButton(
              icon: Icons.remove,
              onTap: () => _adjustReps(-1),
              color: AppColors.neutral700,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Reps display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
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
                    reps.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'reps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Plus button
            _RoundButton(
              icon: Icons.add,
              onTap: () => _adjustReps(1),
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Quick select buttons
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: _quickValues.map((value) {
            final isSelected = reps == value;
            return _QuickRepButton(
              value: value,
              isSelected: isSelected,
              onTap: () => _selectReps(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool compact;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 48.0;
    final iconSize = compact ? 18.0 : 24.0;

    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

class _QuickRepButton extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _QuickRepButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.neutral100,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: compact ? 32 : 56,
          height: compact ? 26 : 44,
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: compact ? 12 : 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.neutralWhite : AppColors.neutralBlack,
            ),
          ),
        ),
      ),
    );
  }
}
