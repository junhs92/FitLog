import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/active_session/domain/entities/exercise_entity.dart';
import 'exercise_picker_content.dart';

/// Dialog for selecting an exercise from the library
/// Groups exercises by movement pattern and shows smart recommendations
class ExercisePickerDialog extends ConsumerWidget {
  final String? clientId;

  const ExercisePickerDialog({
    super.key,
    this.clientId,
  });

  static Future<ExerciseEntity?> show({
    required BuildContext context,
    String? clientId,
  }) {
    return showModalBottomSheet<ExerciseEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExercisePickerDialog(clientId: clientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '운동 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.neutral500,
                ),
              ],
            ),
          ),
          // Content - using extracted widget
          Flexible(
            child: ExercisePickerContent(
              clientId: clientId,
              onExerciseSelected: (exercise) => Navigator.pop(context, exercise),
            ),
          ),
        ],
      ),
    );
  }
}
