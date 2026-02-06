import 'template_exercise_entity.dart';

/// A reusable workout template created by a trainer
class WorkoutTemplateEntity {
  final String id;
  final String creatorId;
  final String name;
  final String? nameKo;
  final String? description;
  final List<TemplateExerciseEntity> exercises;
  final int? estimatedDurationMinutes;
  final String? focusArea;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutTemplateEntity({
    required this.id,
    required this.creatorId,
    required this.name,
    this.nameKo,
    this.description,
    this.exercises = const [],
    this.estimatedDurationMinutes,
    this.focusArea,
    this.usageCount = 0,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name (Korean if available)
  String get displayName => nameKo ?? name;

  /// Get exercise count
  int get exerciseCount => exercises.length;

  /// Get focus area in Korean
  String get focusAreaKorean {
    if (focusArea == null || focusArea!.isEmpty) return '운동';
    switch (focusArea!.toLowerCase()) {
      case 'chest':
        return '가슴';
      case 'push':
        return '푸시';
      case 'back':
        return '등';
      case 'pull':
        return '풀';
      case 'legs':
      case 'lower':
        return '하체';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'full_body':
        return '전신';
      case 'upper':
        return '상체';
      case 'core':
        return '코어';
      default:
        return focusArea!;
    }
  }

  WorkoutTemplateEntity copyWith({
    String? id,
    String? creatorId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseEntity>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplateEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      focusArea: focusArea ?? this.focusArea,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTemplateEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
