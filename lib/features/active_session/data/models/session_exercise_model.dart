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
    super.programExerciseId,
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
        movementPattern: 'isolation',
      );
    }

    // Parse sets if available
    final sessionExerciseId = json['id'] as String;
    final setsData = json['sets'] ?? json['exercise_sets'] ?? <dynamic>[];
    final List<ExerciseSetEntity> sets = (setsData as List<dynamic>).map((s) {
      final setJson = Map<String, dynamic>.from(s as Map);
      // Inject session_exercise_id if not present
      setJson['session_exercise_id'] ??= sessionExerciseId;
      return ExerciseSetModel.fromJson(setJson);
    }).toList();

    // Parse target values from program_exercises join
    final programExercise = json['program_exercises'] as Map<String, dynamic>?;
    final String? programExerciseId = json['program_exercise_id'] as String?;

    int? targetSets;
    String? targetReps;
    double? targetWeight;
    int? targetRpe;
    int? restSeconds;

    if (programExercise != null) {
      targetSets = programExercise['target_sets'] as int?;
      targetReps = programExercise['target_reps'] as String?;
      targetWeight = (programExercise['target_weight'] as num?)?.toDouble();
      targetRpe = programExercise['target_rpe'] as int?;
      restSeconds = programExercise['rest_seconds'] as int?;
    }

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
      programExerciseId: programExerciseId,
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
      programExerciseId: entity.programExerciseId,
      targetSets: entity.targetSets,
      targetReps: entity.targetReps,
      targetWeight: entity.targetWeight,
      targetRpe: entity.targetRpe,
      restSeconds: entity.restSeconds,
    );
  }

  SessionExerciseEntity toEntity() => this;
}
