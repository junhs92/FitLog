import '../../../../shared/models/result.dart';
import '../entities/template_exercise_entity.dart';
import '../entities/workout_template_entity.dart';

/// Input for creating/updating template exercises
class TemplateExerciseInput {
  final String exerciseId;
  final int orderIndex;
  final int? targetSets;
  final String? targetReps;
  final double? targetWeight;
  final int? targetRpe;
  final int? restSeconds;
  final String? notes;

  const TemplateExerciseInput({
    required this.exerciseId,
    required this.orderIndex,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.targetRpe,
    this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        if (targetSets != null) 'target_sets': targetSets,
        if (targetReps != null) 'target_reps': targetReps,
        if (targetWeight != null) 'target_weight': targetWeight,
        if (targetRpe != null) 'target_rpe': targetRpe,
        if (restSeconds != null) 'rest_seconds': restSeconds,
        if (notes != null) 'notes': notes,
      };

  /// Create from TemplateExerciseEntity
  factory TemplateExerciseInput.fromEntity(TemplateExerciseEntity entity) {
    return TemplateExerciseInput(
      exerciseId: entity.exerciseId,
      orderIndex: entity.orderIndex,
      targetSets: entity.targetSets,
      targetReps: entity.targetReps,
      targetWeight: entity.targetWeight,
      targetRpe: entity.targetRpe,
      restSeconds: entity.restSeconds,
      notes: entity.notes,
    );
  }
}

/// Repository interface for workout template operations
abstract class WorkoutTemplateRepository {
  /// Get all templates for the current trainer
  Future<Result<List<WorkoutTemplateEntity>>> getTemplates({
    String? focusArea,
    int? limit,
  });

  /// Get a specific template by ID with exercises
  Future<Result<WorkoutTemplateEntity>> getTemplateById(String templateId);

  /// Create a new template
  Future<Result<WorkoutTemplateEntity>> createTemplate({
    required String name,
    String? nameKo,
    String? description,
    required List<TemplateExerciseInput> exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  });

  /// Update an existing template
  Future<Result<WorkoutTemplateEntity>> updateTemplate({
    required String templateId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseInput>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  });

  /// Delete a template
  Future<Result<void>> deleteTemplate(String templateId);

  /// Increment usage count when template is used to start a session
  Future<Result<void>> incrementUsage(String templateId);
}
