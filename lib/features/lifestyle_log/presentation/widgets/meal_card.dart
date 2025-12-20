import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/meal_log_entity.dart';

/// Card widget for displaying/adding a meal
class MealCard extends StatelessWidget {
  final MealType mealType;
  final MealLogEntity? meal;
  final VoidCallback onTap;
  final VoidCallback? onPhotoTap;

  const MealCard({
    required this.mealType,
    this.meal,
    required this.onTap,
    this.onPhotoTap,
    super.key,
  });

  String get _mealEmoji {
    switch (mealType) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }

  String get _mealName {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  Color get _mealColor {
    switch (mealType) {
      case MealType.breakfast:
        return const Color(0xFFFFB74D);
      case MealType.lunch:
        return const Color(0xFF81C784);
      case MealType.dinner:
        return const Color(0xFF7986CB);
      case MealType.snack:
        return const Color(0xFFE57373);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = meal?.photoUrl != null;
    final isLogged = meal != null;

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: isLogged
                ? Border.all(color: _mealColor.withValues(alpha: 0.5), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _mealColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        _mealEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mealName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          isLogged ? 'Logged' : 'Tap to log',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLogged
                                ? AppColors.success
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLogged)
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
              if (hasPhoto) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: onPhotoTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Image.network(
                      meal!.photoUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.neutral200,
                        child: const Center(
                          child: Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (meal?.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  meal!.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (meal?.hasNutrition ?? false) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (meal!.calories != null)
                      _NutritionChip(
                        label: '${meal!.calories} kcal',
                        color: _mealColor,
                      ),
                    if (meal!.protein != null)
                      _NutritionChip(
                        label: '${meal!.protein!.toStringAsFixed(0)}g P',
                        color: AppColors.primary,
                      ),
                    if (meal!.carbs != null)
                      _NutritionChip(
                        label: '${meal!.carbs!.toStringAsFixed(0)}g C',
                        color: AppColors.secondary,
                      ),
                    if (meal!.fat != null)
                      _NutritionChip(
                        label: '${meal!.fat!.toStringAsFixed(0)}g F',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final Color color;

  const _NutritionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Grid of meal cards for a day
class MealCardGrid extends StatelessWidget {
  final List<MealLogEntity> meals;
  final Function(MealType) onMealTap;

  const MealCardGrid({
    required this.meals,
    required this.onMealTap,
    super.key,
  });

  MealLogEntity? _getMealByType(MealType type) {
    try {
      return meals.firstWhere((m) => m.mealType == type);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MealCard(
                mealType: MealType.breakfast,
                meal: _getMealByType(MealType.breakfast),
                onTap: () => onMealTap(MealType.breakfast),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MealCard(
                mealType: MealType.lunch,
                meal: _getMealByType(MealType.lunch),
                onTap: () => onMealTap(MealType.lunch),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: MealCard(
                mealType: MealType.dinner,
                meal: _getMealByType(MealType.dinner),
                onTap: () => onMealTap(MealType.dinner),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MealCard(
                mealType: MealType.snack,
                meal: _getMealByType(MealType.snack),
                onTap: () => onMealTap(MealType.snack),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
