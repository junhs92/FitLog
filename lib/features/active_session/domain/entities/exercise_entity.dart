/// Exercise domain entity for workout exercises
class ExerciseEntity {
  final String id;
  final String name;
  final String? nameKo;
  final String category;
  final String movementGroup;
  final String? movementDetail;
  final String? family;
  final String? angle;
  final String? equipment;
  final String? muscleGroup;
  final List<String> secondaryMuscles;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? gifUrl;
  final bool isCustom;
  final String? trainerId;
  final bool isIsometric;
  final int defaultDurationSeconds;
  final String? exerciseDbId;

  const ExerciseEntity({
    required this.id,
    required this.name,
    this.nameKo,
    required this.category,
    required this.movementGroup,
    this.movementDetail,
    this.family,
    this.angle,
    this.equipment,
    this.muscleGroup,
    this.secondaryMuscles = const [],
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.gifUrl,
    this.isCustom = false,
    this.trainerId,
    this.isIsometric = false,
    this.defaultDurationSeconds = 30,
    this.exerciseDbId,
  });

  /// Check if this is a bodyweight exercise
  bool get isBodyweight => equipment == 'bodyweight';

  /// Get display name (Korean if available, otherwise English)
  String get displayName => nameKo ?? name;

  /// Get image URL - prefers animated GIF over static thumbnail
  String? get imageUrl => gifUrl ?? thumbnailUrl;

  /// Check if this exercise has an animated GIF available
  bool get hasGif => gifUrl != null && gifUrl!.isNotEmpty;

  /// Check if this exercise has video available
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Check if this exercise has any media (video, gif, or thumbnail)
  bool get hasMedia =>
      hasVideo ||
      hasGif ||
      (thumbnailUrl != null && thumbnailUrl!.isNotEmpty);

  ExerciseEntity copyWith({
    String? id,
    String? name,
    String? nameKo,
    String? category,
    String? movementGroup,
    String? movementDetail,
    String? family,
    String? angle,
    String? equipment,
    String? muscleGroup,
    List<String>? secondaryMuscles,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    String? gifUrl,
    bool? isCustom,
    String? trainerId,
    bool? isIsometric,
    int? defaultDurationSeconds,
    String? exerciseDbId,
  }) {
    return ExerciseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKo: nameKo ?? this.nameKo,
      category: category ?? this.category,
      movementGroup: movementGroup ?? this.movementGroup,
      movementDetail: movementDetail ?? this.movementDetail,
      family: family ?? this.family,
      angle: angle ?? this.angle,
      equipment: equipment ?? this.equipment,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gifUrl: gifUrl ?? this.gifUrl,
      isCustom: isCustom ?? this.isCustom,
      trainerId: trainerId ?? this.trainerId,
      isIsometric: isIsometric ?? this.isIsometric,
      defaultDurationSeconds: defaultDurationSeconds ?? this.defaultDurationSeconds,
      exerciseDbId: exerciseDbId ?? this.exerciseDbId,
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

/// Movement groups for high-level exercise categorization
class MovementGroup {
  static const String push = 'push';
  static const String pull = 'pull';
  static const String legs = 'legs';
  static const String core = 'core';
  static const String other = 'other';

  static const List<String> all = [
    push,
    pull,
    legs,
    core,
    other,
  ];

  static String getDisplayName(String group) {
    switch (group) {
      case push:
        return 'Push';
      case pull:
        return 'Pull';
      case legs:
        return 'Legs';
      case core:
        return 'Core';
      case other:
        return 'Other';
      default:
        return group;
    }
  }

  static String getDisplayNameKo(String group) {
    switch (group) {
      case push:
        return '밀기';
      case pull:
        return '당기기';
      case legs:
        return '하체';
      case core:
        return '코어';
      case other:
        return '기타';
      default:
        return group;
    }
  }
}

/// Movement detail for fine-grained categorization within a movement group
class MovementDetail {
  // Push/Pull details
  static const String horizontal = 'horizontal';
  static const String vertical = 'vertical';

  // Legs details
  static const String squat = 'squat';
  static const String hinge = 'hinge';
  static const String lunge = 'lunge';

  // Core details
  static const String antiExtension = 'anti_extension';
  static const String antiFlexion = 'anti_flexion';
  static const String antiLateralFlexion = 'anti_lateral_flexion';
  static const String rotation = 'rotation';

  /// Get details available for a movement group
  static List<String> getDetailsForGroup(String group) {
    switch (group) {
      case MovementGroup.push:
      case MovementGroup.pull:
        return [horizontal, vertical];
      case MovementGroup.legs:
        return [squat, hinge, lunge];
      case MovementGroup.core:
        return [antiExtension, antiFlexion, antiLateralFlexion, rotation];
      default:
        return [];
    }
  }

  static String getDisplayName(String detail) {
    switch (detail) {
      case horizontal:
        return 'Horizontal';
      case vertical:
        return 'Vertical';
      case squat:
        return 'Squat';
      case hinge:
        return 'Hinge';
      case lunge:
        return 'Lunge';
      case antiExtension:
        return 'Anti-Extension';
      case antiFlexion:
        return 'Anti-Flexion';
      case antiLateralFlexion:
        return 'Anti-Lateral Flexion';
      case rotation:
        return 'Rotation';
      default:
        return detail;
    }
  }

  static String getDisplayNameKo(String detail) {
    switch (detail) {
      case horizontal:
        return '수평';
      case vertical:
        return '수직';
      case squat:
        return '스쿼트';
      case hinge:
        return '힌지';
      case lunge:
        return '런지';
      case antiExtension:
        return '항신전';
      case antiFlexion:
        return '항굴곡';
      case antiLateralFlexion:
        return '항측굴';
      case rotation:
        return '회전';
      default:
        return detail;
    }
  }
}

/// Exercise angle (for bench exercises)
class ExerciseAngle {
  static const String flat = 'flat';
  static const String incline = 'incline';
  static const String decline = 'decline';
  static const String neutral = 'neutral';
  static const String na = 'na';

  static const List<String> all = [flat, incline, decline, neutral, na];

  static String getDisplayName(String angle) {
    switch (angle) {
      case flat:
        return 'Flat';
      case incline:
        return 'Incline';
      case decline:
        return 'Decline';
      case neutral:
        return 'Neutral';
      case na:
        return 'N/A';
      default:
        return angle;
    }
  }

  static String getDisplayNameKo(String angle) {
    switch (angle) {
      case flat:
        return '플랫';
      case incline:
        return '인클라인';
      case decline:
        return '디클라인';
      case neutral:
        return '중립';
      case na:
        return '해당없음';
      default:
        return angle;
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
