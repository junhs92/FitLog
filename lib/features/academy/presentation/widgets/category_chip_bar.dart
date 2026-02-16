import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/academy_category.dart';
import '../providers/academy_provider.dart';

class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(academyCategoryProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: AcademyCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = AcademyCategory.values[index];
          final isSelected = category == selected;

          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 16,
                  color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
                ),
                const SizedBox(width: 4),
                Text(category.displayName),
              ],
            ),
            onSelected: (_) {
              ref.read(academyCategoryProvider.notifier).state = category;
              // Clear playing video when switching categories
              ref.read(academyPlayingVideoProvider.notifier).state = null;
            },
            backgroundColor: AppColors.neutral100,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.neutralWhite : AppColors.neutral900,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            side: BorderSide.none,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          );
        },
      ),
    );
  }
}
