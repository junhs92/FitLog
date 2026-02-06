import '../../domain/entities/template_exercise_entity.dart';
import '../../domain/entities/workout_template_entity.dart';
import 'template_exercise_model.dart';

/// Data model for Workout Template
class WorkoutTemplateModel extends WorkoutTemplateEntity {
  const WorkoutTemplateModel({
    required super.id,
    required super.creatorId,
    required super.name,
    super.nameKo,
    super.description,
    super.exercises,
    super.estimatedDurationMinutes,
    super.focusArea,
    super.usageCount,
    super.lastUsedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    List<TemplateExerciseEntity> exercises = [];
    if (json['workout_template_exercises'] != null) {
      exercises = (json['workout_template_exercises'] as List)
          .map((e) => TemplateExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // Sort by order_index
      exercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return WorkoutTemplateModel(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      description: json['description'] as String?,
      exercises: exercises,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      focusArea: json['focus_area'] as String?,
      usageCount: json['usage_count'] as int? ?? 0,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'name': name,
      'name_ko': nameKo,
      'description': description,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'focus_area': focusArea,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to insert JSON (without id, timestamps, and derived fields)
  Map<String, dynamic> toInsertJson() {
    return {
      'creator_id': creatorId,
      'name': name,
      if (nameKo != null) 'name_ko': nameKo,
      if (description != null) 'description': description,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (focusArea != null) 'focus_area': focusArea,
    };
  }

  /// Convert to update JSON
  Map<String, dynamic> toUpdateJson({
    String? name,
    String? nameKo,
    String? description,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) {
    return {
      if (name != null) 'name': name,
      if (nameKo != null) 'name_ko': nameKo,
      if (description != null) 'description': description,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (focusArea != null) 'focus_area': focusArea,
    };
  }

  WorkoutTemplateEntity toEntity() => this;
}
