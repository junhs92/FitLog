import '../../../active_session/data/models/exercise_model.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../domain/entities/template_exercise_entity.dart';

/// Data model for Template Exercise
class TemplateExerciseModel extends TemplateExerciseEntity {
  const TemplateExerciseModel({
    required super.id,
    required super.templateId,
    required super.exerciseId,
    super.exercise,
    required super.orderIndex,
    super.targetSets,
    super.targetReps,
    super.targetWeight,
    super.targetRpe,
    super.restSeconds,
    super.notes,
    required super.createdAt,
  });

  factory TemplateExerciseModel.fromJson(Map<String, dynamic> json) {
    ExerciseEntity? exercise;
    if (json['exercises'] != null) {
      exercise = ExerciseModel.fromJson(json['exercises'] as Map<String, dynamic>);
    }

    return TemplateExerciseModel(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exercise: exercise,
      orderIndex: json['order_index'] as int? ?? 0,
      targetSets: json['target_sets'] as int?,
      targetReps: json['target_reps'] as String?,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      targetRpe: json['target_rpe'] as int?,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to insert JSON (without id and created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'template_id': templateId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (targetRpe != null) 'target_rpe': targetRpe,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (notes != null) 'notes': notes,
    };
  }

  TemplateExerciseEntity toEntity() => this;
}
