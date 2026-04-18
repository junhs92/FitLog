import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../models/exercise_type.dart';
import '../widgets/exercise_animation.dart';

class ExerciseDemoScreen extends StatelessWidget {
  const ExerciseDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dumbbell Bench Press')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const ExerciseAnimationWidget(
                      exerciseType: ExerciseType.dumbbellBenchPress,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('How to perform', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lie flat on the bench with a dumbbell in each hand at chest '
              'level. Press both dumbbells straight up until your arms are '
              'fully extended, then lower them back down with control.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
