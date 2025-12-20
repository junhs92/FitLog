import 'package:equatable/equatable.dart';

/// Comprehensive context for AI workout generation
/// Aggregates client profile, workout history, and session feedback
class GenerationContext extends Equatable {
  final ClientContext clientContext;
  final WorkoutHistory workoutHistory;
  final SessionFeedbackSummary sessionFeedback;

  const GenerationContext({
    required this.clientContext,
    required this.workoutHistory,
    required this.sessionFeedback,
  });

  /// Check if we have enough data for AI generation
  bool get hasMinimumData =>
      clientContext.fitnessGoals.isNotEmpty ||
      workoutHistory.recentSessions.isNotEmpty;

  /// Summary for display in UI
  String get contextSummary {
    final parts = <String>[];

    if (clientContext.experienceLevel.isNotEmpty) {
      parts.add('${clientContext.experienceLevel} level');
    }
    if (clientContext.fitnessGoals.isNotEmpty) {
      parts.add('Goals: ${clientContext.fitnessGoals.join(', ')}');
    }
    if (workoutHistory.recentSessions.isNotEmpty) {
      parts.add('${workoutHistory.recentSessions.length} recent sessions');
    }
    if (sessionFeedback.difficultyFeedback.isNotEmpty) {
      parts.add('${sessionFeedback.difficultyFeedback.length} feedback entries');
    }

    return parts.join(' | ');
  }

  @override
  List<Object?> get props => [clientContext, workoutHistory, sessionFeedback];
}

/// Static client profile information
class ClientContext extends Equatable {
  final List<String> fitnessGoals;
  final List<String> availableEquipment;
  final String experienceLevel;
  final List<InjuryRecord> injuryHistory;
  final List<String> limitations;
  final Map<String, dynamic> preferences;

  const ClientContext({
    this.fitnessGoals = const [],
    this.availableEquipment = const [],
    this.experienceLevel = 'intermediate',
    this.injuryHistory = const [],
    this.limitations = const [],
    this.preferences = const {},
  });

  /// Create empty context
  factory ClientContext.empty() => const ClientContext();

  @override
  List<Object?> get props => [
        fitnessGoals,
        availableEquipment,
        experienceLevel,
        injuryHistory,
        limitations,
        preferences,
      ];
}

/// Record of client injury
class InjuryRecord extends Equatable {
  final String area;
  final String severity;
  final String? notes;

  const InjuryRecord({
    required this.area,
    required this.severity,
    this.notes,
  });

  @override
  List<Object?> get props => [area, severity, notes];
}

/// Recent workout history for AI context
class WorkoutHistory extends Equatable {
  final List<SessionSummary> recentSessions;
  final List<PersonalRecord> personalRecords;
  final VolumeTrend volumeTrends;

  const WorkoutHistory({
    this.recentSessions = const [],
    this.personalRecords = const [],
    this.volumeTrends = const VolumeTrend(),
  });

  /// Create empty history
  factory WorkoutHistory.empty() => const WorkoutHistory();

  @override
  List<Object?> get props => [recentSessions, personalRecords, volumeTrends];
}

/// Summary of a completed session
class SessionSummary extends Equatable {
  final DateTime date;
  final List<ExerciseSummary> exercises;
  final int durationMinutes;

  const SessionSummary({
    required this.date,
    this.exercises = const [],
    this.durationMinutes = 0,
  });

  @override
  List<Object?> get props => [date, exercises, durationMinutes];
}

/// Summary of exercise performance in a session
class ExerciseSummary extends Equatable {
  final String name;
  final List<SetSummary> sets;

  const ExerciseSummary({
    required this.name,
    this.sets = const [],
  });

  /// Total volume for this exercise
  double get totalVolume =>
      sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));

  @override
  List<Object?> get props => [name, sets];
}

/// Summary of a single set
class SetSummary extends Equatable {
  final double weight;
  final int reps;
  final double? rpe;

  const SetSummary({
    required this.weight,
    required this.reps,
    this.rpe,
  });

  @override
  List<Object?> get props => [weight, reps, rpe];
}

/// Personal record for an exercise
class PersonalRecord extends Equatable {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  @override
  List<Object?> get props => [exerciseName, weight, reps, date];
}

/// Volume trend analysis
class VolumeTrend extends Equatable {
  final List<double> weeklyVolume;
  final TrendDirection trend;

  const VolumeTrend({
    this.weeklyVolume = const [],
    this.trend = TrendDirection.stable,
  });

  @override
  List<Object?> get props => [weeklyVolume, trend];
}

enum TrendDirection {
  increasing,
  stable,
  decreasing,
}

/// Aggregated session feedback
class SessionFeedbackSummary extends Equatable {
  final List<ExerciseFeedback> difficultyFeedback;
  final List<ExerciseSwap> swapHistory;
  final RpePattern rpePatterns;

  const SessionFeedbackSummary({
    this.difficultyFeedback = const [],
    this.swapHistory = const [],
    this.rpePatterns = const RpePattern(),
  });

  /// Create empty feedback
  factory SessionFeedbackSummary.empty() => const SessionFeedbackSummary();

  /// Get exercises that were too easy
  List<String> get tooEasyExercises =>
      difficultyFeedback
          .where((f) => f.feedback == DifficultyLevel.tooEasy)
          .map((f) => f.exerciseName)
          .toList();

  /// Get exercises that were challenging
  List<String> get strugglingExercises =>
      difficultyFeedback
          .where((f) => f.feedback == DifficultyLevel.struggling)
          .map((f) => f.exerciseName)
          .toList();

  @override
  List<Object?> get props => [difficultyFeedback, swapHistory, rpePatterns];
}

/// Feedback for a specific exercise
class ExerciseFeedback extends Equatable {
  final String exerciseName;
  final DifficultyLevel feedback;
  final int frequency;

  const ExerciseFeedback({
    required this.exerciseName,
    required this.feedback,
    this.frequency = 1,
  });

  @override
  List<Object?> get props => [exerciseName, feedback, frequency];
}

enum DifficultyLevel {
  tooEasy,
  justRight,
  challenging,
  struggling,
}

/// Record of exercise swap
class ExerciseSwap extends Equatable {
  final String originalExercise;
  final String replacementExercise;
  final String? reason;

  const ExerciseSwap({
    required this.originalExercise,
    required this.replacementExercise,
    this.reason,
  });

  @override
  List<Object?> get props => [originalExercise, replacementExercise, reason];
}

/// RPE pattern analysis
class RpePattern extends Equatable {
  final double averageRpe;
  final TrendDirection trend;

  const RpePattern({
    this.averageRpe = 7.0,
    this.trend = TrendDirection.stable,
  });

  @override
  List<Object?> get props => [averageRpe, trend];
}
