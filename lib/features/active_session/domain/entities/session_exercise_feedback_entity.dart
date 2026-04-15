enum ExerciseFeedbackType {
  tooEasy,
  justRight,
  challenging,
  struggling;

  String toDb() {
    switch (this) {
      case ExerciseFeedbackType.tooEasy:
        return 'too_easy';
      case ExerciseFeedbackType.justRight:
        return 'just_right';
      case ExerciseFeedbackType.challenging:
        return 'challenging';
      case ExerciseFeedbackType.struggling:
        return 'struggling';
    }
  }

  static ExerciseFeedbackType fromDb(String value) {
    switch (value) {
      case 'too_easy':
        return ExerciseFeedbackType.tooEasy;
      case 'just_right':
        return ExerciseFeedbackType.justRight;
      case 'challenging':
        return ExerciseFeedbackType.challenging;
      case 'struggling':
        return ExerciseFeedbackType.struggling;
      default:
        return ExerciseFeedbackType.justRight;
    }
  }
}

/// Domain entity for trainer feedback on a session exercise
class SessionExerciseFeedbackEntity {
  final String id;
  final String sessionExerciseId;
  final ExerciseFeedbackType feedbackType;
  final String trainerId;
  final String? notes;
  final DateTime createdAt;

  const SessionExerciseFeedbackEntity({
    required this.id,
    required this.sessionExerciseId,
    required this.feedbackType,
    required this.trainerId,
    this.notes,
    required this.createdAt,
  });

  SessionExerciseFeedbackEntity copyWith({
    String? id,
    String? sessionExerciseId,
    ExerciseFeedbackType? feedbackType,
    String? trainerId,
    String? notes,
    DateTime? createdAt,
  }) {
    return SessionExerciseFeedbackEntity(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      feedbackType: feedbackType ?? this.feedbackType,
      trainerId: trainerId ?? this.trainerId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExerciseFeedbackEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
