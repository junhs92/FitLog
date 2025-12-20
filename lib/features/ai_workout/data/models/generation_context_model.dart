import '../../domain/entities/generation_context.dart';

/// Data model for GenerationContext with JSON serialization
class GenerationContextModel extends GenerationContext {
  const GenerationContextModel({
    required super.clientContext,
    required super.workoutHistory,
    required super.sessionFeedback,
  });

  /// Create from domain entity
  factory GenerationContextModel.fromEntity(GenerationContext entity) {
    return GenerationContextModel(
      clientContext: entity.clientContext,
      workoutHistory: entity.workoutHistory,
      sessionFeedback: entity.sessionFeedback,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'clientContext': ClientContextModel.fromEntity(clientContext).toJson(),
      'workoutHistory': WorkoutHistoryModel.fromEntity(workoutHistory).toJson(),
      'sessionFeedback':
          SessionFeedbackSummaryModel.fromEntity(sessionFeedback).toJson(),
    };
  }
}

/// Data model for ClientContext
class ClientContextModel extends ClientContext {
  const ClientContextModel({
    super.fitnessGoals,
    super.availableEquipment,
    super.experienceLevel,
    super.injuryHistory,
    super.limitations,
    super.preferences,
  });

  factory ClientContextModel.fromEntity(ClientContext entity) {
    return ClientContextModel(
      fitnessGoals: entity.fitnessGoals,
      availableEquipment: entity.availableEquipment,
      experienceLevel: entity.experienceLevel,
      injuryHistory: entity.injuryHistory,
      limitations: entity.limitations,
      preferences: entity.preferences,
    );
  }

  factory ClientContextModel.fromJson(Map<String, dynamic> json) {
    return ClientContextModel(
      fitnessGoals: (json['fitness_goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      availableEquipment: (json['available_equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      experienceLevel: json['experience_level'] as String? ?? 'intermediate',
      injuryHistory: (json['injury_history'] as List<dynamic>?)
              ?.map((e) => InjuryRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      limitations: (json['limitations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fitnessGoals': fitnessGoals,
      'availableEquipment': availableEquipment,
      'experienceLevel': experienceLevel,
      'injuryHistory':
          injuryHistory.map((e) => InjuryRecordModel.fromEntity(e).toJson()).toList(),
      'limitations': limitations,
      'preferences': preferences,
    };
  }
}

/// Data model for InjuryRecord
class InjuryRecordModel extends InjuryRecord {
  const InjuryRecordModel({
    required super.area,
    required super.severity,
    super.notes,
  });

  factory InjuryRecordModel.fromEntity(InjuryRecord entity) {
    return InjuryRecordModel(
      area: entity.area,
      severity: entity.severity,
      notes: entity.notes,
    );
  }

  factory InjuryRecordModel.fromJson(Map<String, dynamic> json) {
    return InjuryRecordModel(
      area: json['area'] as String? ?? '',
      severity: json['severity'] as String? ?? 'mild',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'severity': severity,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Data model for WorkoutHistory
class WorkoutHistoryModel extends WorkoutHistory {
  const WorkoutHistoryModel({
    super.recentSessions,
    super.personalRecords,
    super.volumeTrends,
  });

  factory WorkoutHistoryModel.fromEntity(WorkoutHistory entity) {
    return WorkoutHistoryModel(
      recentSessions: entity.recentSessions,
      personalRecords: entity.personalRecords,
      volumeTrends: entity.volumeTrends,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recentSessions': recentSessions
          .map((s) => SessionSummaryModel.fromEntity(s).toJson())
          .toList(),
      'personalRecords': personalRecords
          .map((r) => PersonalRecordModel.fromEntity(r).toJson())
          .toList(),
      'volumeTrends': VolumeTrendModel.fromEntity(volumeTrends).toJson(),
    };
  }
}

/// Data model for SessionSummary
class SessionSummaryModel extends SessionSummary {
  const SessionSummaryModel({
    required super.date,
    super.exercises,
    super.durationMinutes,
  });

  factory SessionSummaryModel.fromEntity(SessionSummary entity) {
    return SessionSummaryModel(
      date: entity.date,
      exercises: entity.exercises,
      durationMinutes: entity.durationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'exercises': exercises
          .map((e) => ExerciseSummaryModel.fromEntity(e).toJson())
          .toList(),
      'durationMinutes': durationMinutes,
    };
  }
}

/// Data model for ExerciseSummary
class ExerciseSummaryModel extends ExerciseSummary {
  const ExerciseSummaryModel({
    required super.name,
    super.sets,
  });

  factory ExerciseSummaryModel.fromEntity(ExerciseSummary entity) {
    return ExerciseSummaryModel(
      name: entity.name,
      sets: entity.sets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets.map((s) => SetSummaryModel.fromEntity(s).toJson()).toList(),
    };
  }
}

/// Data model for SetSummary
class SetSummaryModel extends SetSummary {
  const SetSummaryModel({
    required super.weight,
    required super.reps,
    super.rpe,
  });

  factory SetSummaryModel.fromEntity(SetSummary entity) {
    return SetSummaryModel(
      weight: entity.weight,
      reps: entity.reps,
      rpe: entity.rpe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
      if (rpe != null) 'rpe': rpe,
    };
  }
}

/// Data model for PersonalRecord
class PersonalRecordModel extends PersonalRecord {
  const PersonalRecordModel({
    required super.exerciseName,
    required super.weight,
    required super.reps,
    required super.date,
  });

  factory PersonalRecordModel.fromEntity(PersonalRecord entity) {
    return PersonalRecordModel(
      exerciseName: entity.exerciseName,
      weight: entity.weight,
      reps: entity.reps,
      date: entity.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'weight': weight,
      'reps': reps,
      'date': date.toIso8601String(),
    };
  }
}

/// Data model for VolumeTrend
class VolumeTrendModel extends VolumeTrend {
  const VolumeTrendModel({
    super.weeklyVolume,
    super.trend,
  });

  factory VolumeTrendModel.fromEntity(VolumeTrend entity) {
    return VolumeTrendModel(
      weeklyVolume: entity.weeklyVolume,
      trend: entity.trend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklyVolume': weeklyVolume,
      'trend': trend.name,
    };
  }
}

/// Data model for SessionFeedbackSummary
class SessionFeedbackSummaryModel extends SessionFeedbackSummary {
  const SessionFeedbackSummaryModel({
    super.difficultyFeedback,
    super.swapHistory,
    super.rpePatterns,
  });

  factory SessionFeedbackSummaryModel.fromEntity(SessionFeedbackSummary entity) {
    return SessionFeedbackSummaryModel(
      difficultyFeedback: entity.difficultyFeedback,
      swapHistory: entity.swapHistory,
      rpePatterns: entity.rpePatterns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'difficultyFeedback': difficultyFeedback
          .map((f) => ExerciseFeedbackModel.fromEntity(f).toJson())
          .toList(),
      'swapHistory':
          swapHistory.map((s) => ExerciseSwapModel.fromEntity(s).toJson()).toList(),
      'rpePatterns': RpePatternModel.fromEntity(rpePatterns).toJson(),
    };
  }
}

/// Data model for ExerciseFeedback
class ExerciseFeedbackModel extends ExerciseFeedback {
  const ExerciseFeedbackModel({
    required super.exerciseName,
    required super.feedback,
    super.frequency,
  });

  factory ExerciseFeedbackModel.fromEntity(ExerciseFeedback entity) {
    return ExerciseFeedbackModel(
      exerciseName: entity.exerciseName,
      feedback: entity.feedback,
      frequency: entity.frequency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'feedback': feedback.name,
      'frequency': frequency,
    };
  }
}

/// Data model for ExerciseSwap
class ExerciseSwapModel extends ExerciseSwap {
  const ExerciseSwapModel({
    required super.originalExercise,
    required super.replacementExercise,
    super.reason,
  });

  factory ExerciseSwapModel.fromEntity(ExerciseSwap entity) {
    return ExerciseSwapModel(
      originalExercise: entity.originalExercise,
      replacementExercise: entity.replacementExercise,
      reason: entity.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalExercise': originalExercise,
      'replacementExercise': replacementExercise,
      if (reason != null) 'reason': reason,
    };
  }
}

/// Data model for RpePattern
class RpePatternModel extends RpePattern {
  const RpePatternModel({
    super.averageRpe,
    super.trend,
  });

  factory RpePatternModel.fromEntity(RpePattern entity) {
    return RpePatternModel(
      averageRpe: entity.averageRpe,
      trend: entity.trend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRpe': averageRpe,
      'trend': trend.name,
    };
  }
}
