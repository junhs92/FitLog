/// Exercise domain entity for workout exercises
class ExerciseEntity {
  final String id;
  final String name;
  final String? nameKo;
  final String category;
  final String movementPattern;
  final String? equipment;
  final String? muscleGroup;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isCustom;
  final String? trainerId;

  const ExerciseEntity({
    required this.id,
    required this.name,
    this.nameKo,
    required this.category,
    required this.movementPattern,
    this.equipment,
    this.muscleGroup,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.isCustom = false,
    this.trainerId,
  });

  /// Get display name (Korean if available, otherwise English)
  String get displayName => nameKo ?? name;

  ExerciseEntity copyWith({
    String? id,
    String? name,
    String? nameKo,
    String? category,
    String? movementPattern,
    String? equipment,
    String? muscleGroup,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    bool? isCustom,
    String? trainerId,
  }) {
    return ExerciseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      category: category ?? this.category,
      movementPattern: movementPattern ?? this.movementPattern,
      equipment: equipment ?? this.equipment,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isCustom: isCustom ?? this.isCustom,
      trainerId: trainerId ?? this.trainerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Movement patterns for exercise categorization
class MovementPattern {
  static const String squat = 'squat';
  static const String hinge = 'hinge';
  static const String horizontalPush = 'horizontal_push';
  static const String horizontalPull = 'horizontal_pull';
  static const String verticalPush = 'vertical_push';
  static const String verticalPull = 'vertical_pull';
  static const String carry = 'carry';
  static const String rotation = 'rotation';
  static const String isolation = 'isolation';
  static const String cardio = 'cardio';

  static const List<String> all = [
    squat,
    hinge,
    horizontalPush,
    horizontalPull,
    verticalPush,
    verticalPull,
    carry,
    rotation,
    isolation,
    cardio,
  ];

  static String getDisplayName(String pattern) {
    switch (pattern) {
      case squat:
        return 'Squat';
      case hinge:
        return 'Hip Hinge';
      case horizontalPush:
        return 'Horizontal Push';
      case horizontalPull:
        return 'Horizontal Pull';
      case verticalPush:
        return 'Vertical Push';
      case verticalPull:
        return 'Vertical Pull';
      case carry:
        return 'Carry';
      case rotation:
        return 'Rotation';
      case isolation:
        return 'Isolation';
      case cardio:
        return 'Cardio';
      default:
        return pattern;
    }
  }
}

/// Exercise categories
class ExerciseCategory {
  static const String compound = 'compound';
  static const String isolation = 'isolation';
  static const String cardio = 'cardio';
  static const String mobility = 'mobility';
  static const String warmup = 'warmup';
  static const String cooldown = 'cooldown';

  static const List<String> all = [
    compound,
    isolation,
    cardio,
    mobility,
    warmup,
    cooldown,
  ];
}
