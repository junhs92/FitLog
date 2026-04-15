import '../../domain/entities/session_exercise_feedback_entity.dart';

/// Data model for session exercise feedback
class SessionExerciseFeedbackModel extends SessionExerciseFeedbackEntity {
  const SessionExerciseFeedbackModel({
    required super.id,
    required super.sessionExerciseId,
    required super.feedbackType,
    required super.trainerId,
    super.notes,
    required super.createdAt,
  });

  factory SessionExerciseFeedbackModel.fromJson(Map<String, dynamic> json) {
    return SessionExerciseFeedbackModel(
      id: json['id'] as String,
      sessionExerciseId: json['session_exercise_id'] as String,
      feedbackType: ExerciseFeedbackType.fromDb(
        json['feedback_type'] as String? ?? 'just_right',
      ),
      trainerId: json['trainer_id'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_exercise_id': sessionExerciseId,
      'feedback_type': feedbackType.toDb(),
      'trainer_id': trainerId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionExerciseFeedbackModel.fromEntity(
      SessionExerciseFeedbackEntity entity) {
    return SessionExerciseFeedbackModel(
      id: entity.id,
      sessionExerciseId: entity.sessionExerciseId,
      feedbackType: entity.feedbackType,
      trainerId: entity.trainerId,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
