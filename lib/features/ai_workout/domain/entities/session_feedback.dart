import 'ai_reasoning.dart';

/// Difficulty feedback during a session
enum DifficultyFeedback {
  tooEasy('too_easy', 'Too Easy', '너무 쉬움', '👍'),
  justRight('just_right', 'Just Right', '적당함', '👌'),
  struggling('struggling', 'Struggling', '힘듦', '👎');

  final String id;
  final String name;
  final String nameKo;
  final String emoji;

  const DifficultyFeedback(this.id, this.name, this.nameKo, this.emoji);

  String get displayName => nameKo;

  static DifficultyFeedback fromString(String value) {
    return DifficultyFeedback.values.firstWhere(
      (f) => f.id == value,
      orElse: () => DifficultyFeedback.justRight,
    );
  }
}

/// Real-time feedback for an exercise during session
class SessionExerciseFeedback {
  final String sessionExerciseId;
  final String exerciseId;
  final DifficultyFeedback feedback;
  final DateTime timestamp;
  final List<SessionAlternative> suggestedAlternatives;

  const SessionExerciseFeedback({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.feedback,
    required this.timestamp,
    this.suggestedAlternatives = const [],
  });

  SessionExerciseFeedback copyWith({
    String? sessionExerciseId,
    String? exerciseId,
    DifficultyFeedback? feedback,
    DateTime? timestamp,
    List<SessionAlternative>? suggestedAlternatives,
  }) {
    return SessionExerciseFeedback(
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      feedback: feedback ?? this.feedback,
      timestamp: timestamp ?? this.timestamp,
      suggestedAlternatives:
          suggestedAlternatives ?? this.suggestedAlternatives,
    );
  }
}

/// Alternative suggested during a live session
class SessionAlternative {
  final String exerciseId;
  final String exerciseName;
  final String? exerciseNameKo;
  final AlternativeType type;
  final String reason;
  final String? reasonKo;
  final bool isRecommended; // AI's top recommendation

  const SessionAlternative({
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseNameKo,
    required this.type,
    required this.reason,
    this.reasonKo,
    this.isRecommended = false,
  });

  String get displayName => exerciseNameKo ?? exerciseName;
  String get displayReason => reasonKo ?? reason;
}

/// History of exercise swaps for learning
class ExerciseSwapHistory {
  final String id;
  final String clientId;
  final String trainerId;
  final String originalExerciseId;
  final String replacementExerciseId;
  final DifficultyFeedback? feedbackReason;
  final String? customReason;
  final DateTime swappedAt;
  final String? sessionId;

  const ExerciseSwapHistory({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.originalExerciseId,
    required this.replacementExerciseId,
    this.feedbackReason,
    this.customReason,
    required this.swappedAt,
    this.sessionId,
  });
}
