import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';
import 'exercise_model.dart';
import 'exercise_set_model.dart';

/// Data model for SessionExercise
class SessionExerciseModel extends SessionExerciseEntity {
  const SessionExerciseModel({
    required super.id,
    required super.sessionId,
    required super.exercise,
    required super.order,
    super.sets,
    super.notes,
    super.startedAt,
    super.completedAt,
    super.targetSets,
    super.targetReps,
    super.targetWeight,
    super.targetRpe,
    super.restSeconds,
  });

  factory SessionExerciseModel.fromJson(Map<String, dynamic> json) {
    // Handle nested exercise data
    final exerciseData = json['exercise'] ?? json['exercises'];
    final ExerciseEntity exercise;

    if (exerciseData is Map<String, dynamic>) {
      exercise = ExerciseModel.fromJson(exerciseData);
    } else {
      // Fallback if exercise data is not nested
      exercise = ExerciseModel(
        id: json['exercise_id'] as String,
        name: json['exercise_name'] as String? ?? 'Unknown',
        category: 'compound',
        movementGroup: 'other',
      );
    }

    // Parse sets from set_records table (joined) or legacy JSONB
    final sessionExerciseId = json['id'] as String;
    final setsData = json['set_records'] ?? json['sets'] ?? json['exercise_sets'] ?? <dynamic>[];
    // Explicitly create List<ExerciseSetEntity> to avoid runtime type issues
    final List<ExerciseSetEntity> sets = <ExerciseSetEntity>[
      for (final s in setsData as List<dynamic>)
        ExerciseSetModel.fromJson(
          Map<String, dynamic>.from(s as Map)
            ..['session_exercise_id'] ??= sessionExerciseId,
        ),
    ];

    // Parse target values (from AI recommendations stored directly)
    final int? targetSets = json['target_sets'] as int?;
    final String? targetReps = json['target_reps'] as String?;
    final double? targetWeight = (json['target_weight'] as num?)?.toDouble();
    final int? targetRpe = json['target_rpe'] as int?;
    final int? restSeconds = json['rest_seconds'] as int?;

    return SessionExerciseModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      exercise: exercise,
      order: json['order_index'] as int? ?? json['order'] as int? ?? 0,
      sets: sets,
      notes: json['notes'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      targetRpe: targetRpe,
      restSeconds: restSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'exercise_id': exercise.id,
      'order': order,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'exercise_id': exercise.id,
      'order': order,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
    };
  }

  factory SessionExerciseModel.fromEntity(SessionExerciseEntity entity) {
    return SessionExerciseModel(
      id: entity.id,
      sessionId: entity.sessionId,
      exercise: entity.exercise,
      order: entity.order,
      sets: entity.sets,
      notes: entity.notes,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      targetSets: entity.targetSets,
      targetReps: entity.targetReps,
      targetWeight: entity.targetWeight,
      targetRpe: entity.targetRpe,
      restSeconds: entity.restSeconds,
    );
  }

  SessionExerciseEntity toEntity() => this;
}
