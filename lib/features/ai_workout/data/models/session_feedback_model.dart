import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';

/// Data model for session exercise feedback
class SessionExerciseFeedbackModel extends SessionExerciseFeedback {
  const SessionExerciseFeedbackModel({
    required super.sessionExerciseId,
    required super.exerciseId,
    required super.feedback,
    required super.timestamp,
    super.suggestedAlternatives,
  });

  factory SessionExerciseFeedbackModel.fromJson(Map<String, dynamic> json) {
    return SessionExerciseFeedbackModel(
      sessionExerciseId: json['session_exercise_id'] as String,
      exerciseId: json['exercise_id'] as String,
      feedback: DifficultyFeedback.fromString(json['feedback'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestedAlternatives: (json['suggested_alternatives'] as List<dynamic>?)
              ?.map((e) => SessionAlternativeModel.fromJson(
                  e as Map<String, dynamic>).toEntity())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_exercise_id': sessionExerciseId,
      'exercise_id': exerciseId,
      'feedback': feedback.id,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Data model for session alternative
class SessionAlternativeModel {
  final String exerciseId;
  final String exerciseName;
  final String? exerciseNameKo;
  final String type;
  final String reason;
  final String? reasonKo;
  final bool isRecommended;

  const SessionAlternativeModel({
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseNameKo,
    required this.type,
    required this.reason,
    this.reasonKo,
    this.isRecommended = false,
  });

  factory SessionAlternativeModel.fromJson(Map<String, dynamic> json) {
    return SessionAlternativeModel(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseNameKo: json['exercise_name_ko'] as String?,
      type: json['type'] as String,
      reason: json['reason'] as String,
      reasonKo: json['reason_ko'] as String?,
      isRecommended: json['is_recommended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'exercise_name_ko': exerciseNameKo,
      'type': type,
      'reason': reason,
      'reason_ko': reasonKo,
      'is_recommended': isRecommended,
    };
  }

  SessionAlternative toEntity() {
    return SessionAlternative(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseNameKo: exerciseNameKo,
      type: AlternativeType.values.firstWhere(
        (t) => t.id == type,
        orElse: () => AlternativeType.samePattern,
      ),
      reason: reason,
      reasonKo: reasonKo,
      isRecommended: isRecommended,
    );
  }
}

/// Data model for exercise swap history
class ExerciseSwapHistoryModel extends ExerciseSwapHistory {
  const ExerciseSwapHistoryModel({
    required super.id,
    required super.clientId,
    required super.trainerId,
    required super.originalExerciseId,
    required super.replacementExerciseId,
    super.feedbackReason,
    super.customReason,
    required super.swappedAt,
    super.sessionId,
  });

  factory ExerciseSwapHistoryModel.fromJson(Map<String, dynamic> json) {
    return ExerciseSwapHistoryModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      originalExerciseId: json['original_exercise_id'] as String,
      replacementExerciseId: json['replacement_exercise_id'] as String,
      feedbackReason: json['feedback_reason'] != null
          ? DifficultyFeedback.fromString(json['feedback_reason'] as String)
          : null,
      customReason: json['custom_reason'] as String?,
      swappedAt: DateTime.parse(json['swapped_at'] as String),
      sessionId: json['session_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'original_exercise_id': originalExerciseId,
      'replacement_exercise_id': replacementExerciseId,
      'feedback_reason': feedbackReason?.id,
      'custom_reason': customReason,
      'swapped_at': swappedAt.toIso8601String(),
      'session_id': sessionId,
    };
  }
}
