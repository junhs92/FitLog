import '../../domain/entities/exercise_entity.dart';

/// Data model for Exercise
class ExerciseModel extends ExerciseEntity {
  const ExerciseModel({
    required super.id,
    required super.name,
    super.nameKo,
    required super.category,
    required super.movementGroup,
    super.movementDetail,
    super.family,
    super.angle,
    super.gripOrientation,
    super.equipment,
    super.muscleGroup,
    super.secondaryMuscles = const [],
    super.description,
    super.videoUrl,
    super.thumbnailUrl,
    super.gifUrl,
    super.isCustom,
    super.trainerId,
    super.isIsometric,
    super.defaultDurationSeconds,
    super.exerciseDbId,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      category: json['category'] as String? ?? 'compound',
      movementGroup: json['movement_group'] as String? ?? 'other',
      movementDetail: json['movement_detail'] as String?,
      family: json['family'] as String?,
      angle: json['angle'] as String?,
      gripOrientation: json['grip_orientation'] as String?,
      equipment: json['equipment'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      gifUrl: json['gif_url'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      trainerId: json['trainer_id'] as String?,
      isIsometric: json['is_isometric'] as bool? ?? false,
      defaultDurationSeconds: json['default_duration_seconds'] as int? ?? 30,
      exerciseDbId: json['exercisedb_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ko': nameKo,
      'category': category,
      'movement_group': movementGroup,
      'movement_detail': movementDetail,
      'family': family,
      'angle': angle,
      'grip_orientation': gripOrientation,
      'equipment': equipment,
      'muscle_group': muscleGroup,
      'secondary_muscles': secondaryMuscles,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'gif_url': gifUrl,
      'is_custom': isCustom,
      'trainer_id': trainerId,
      'is_isometric': isIsometric,
      'default_duration_seconds': defaultDurationSeconds,
      'exercisedb_id': exerciseDbId,
    };
  }

  factory ExerciseModel.fromEntity(ExerciseEntity entity) {
    return ExerciseModel(
      id: entity.id,
      name: entity.name,
      nameKo: entity.nameKo,
      category: entity.category,
      movementGroup: entity.movementGroup,
      movementDetail: entity.movementDetail,
      family: entity.family,
      angle: entity.angle,
      gripOrientation: entity.gripOrientation,
      equipment: entity.equipment,
      muscleGroup: entity.muscleGroup,
      secondaryMuscles: entity.secondaryMuscles,
      description: entity.description,
      videoUrl: entity.videoUrl,
      thumbnailUrl: entity.thumbnailUrl,
      gifUrl: entity.gifUrl,
      isCustom: entity.isCustom,
      trainerId: entity.trainerId,
      isIsometric: entity.isIsometric,
      defaultDurationSeconds: entity.defaultDurationSeconds,
      exerciseDbId: entity.exerciseDbId,
    );
  }

  ExerciseEntity toEntity() => this;
}
