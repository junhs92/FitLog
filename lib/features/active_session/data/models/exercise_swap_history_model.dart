import '../../domain/entities/exercise_swap_history_entity.dart';

/// Data model for exercise swap history
class ExerciseSwapHistoryModel extends ExerciseSwapHistoryEntity {
  const ExerciseSwapHistoryModel({
    required super.id,
    required super.sessionExerciseId,
    required super.originalExerciseId,
    required super.newExerciseId,
    super.reason,
    required super.swapOrder,
    required super.clientId,
    required super.trainerId,
    required super.createdAt,
  });

  factory ExerciseSwapHistoryModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSwapHistoryModel(
      id: json['id'] as String,
      sessionExerciseId: json['session_exercise_id'] as String,
      originalExerciseId: json['original_exercise_id'] as String,
      newExerciseId: json['new_exercise_id'] as String,
      reason: json['reason'] as String?,
      swapOrder: json['swap_order'] as int? ?? 0,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_exercise_id': sessionExerciseId,
      'original_exercise_id': originalExerciseId,
      'new_exercise_id': newExerciseId,
      'reason': reason,
      'swap_order': swapOrder,
      'client_id': clientId,
      'trainer_id': trainerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExerciseSwapHistoryModel.fromEntity(ExerciseSwapHistoryEntity entity) {
    return ExerciseSwapHistoryModel(
      id: entity.id,
      sessionExerciseId: entity.sessionExerciseId,
      originalExerciseId: entity.originalExerciseId,
      newExerciseId: entity.newExerciseId,
      reason: entity.reason,
      swapOrder: entity.swapOrder,
      clientId: entity.clientId,
      trainerId: entity.trainerId,
      createdAt: entity.createdAt,
    );
  }
}
