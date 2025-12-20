import '../../domain/entities/exercise_entity.dart';

/// Data model for Exercise
class ExerciseModel extends ExerciseEntity {
  const ExerciseModel({
    required super.id,
    required super.name,
    super.nameKo,
    required super.category,
    required super.movementPattern,
    super.equipment,
    super.muscleGroup,
    super.description,
    super.videoUrl,
    super.thumbnailUrl,
    super.isCustom,
    super.trainerId,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      category: json['category'] as String? ?? 'compound',
      movementPattern: json['movement_pattern'] as String? ?? 'isolation',
      equipment: json['equipment'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      trainerId: json['trainer_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ko': nameKo,
      'category': category,
      'movement_pattern': movementPattern,
      'equipment': equipment,
      'muscle_group': muscleGroup,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_custom': isCustom,
      'trainer_id': trainerId,
    };
  }

  factory ExerciseModel.fromEntity(ExerciseEntity entity) {
    return ExerciseModel(
      id: entity.id,
      name: entity.name,
      nameKo: entity.nameKo,
      category: entity.category,
      movementPattern: entity.movementPattern,
      equipment: entity.equipment,
      muscleGroup: entity.muscleGroup,
      description: entity.description,
      videoUrl: entity.videoUrl,
      thumbnailUrl: entity.thumbnailUrl,
      isCustom: entity.isCustom,
      trainerId: entity.trainerId,
    );
  }

  ExerciseEntity toEntity() => this;
}
