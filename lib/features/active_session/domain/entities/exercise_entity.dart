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
  final String? gripOrientation;
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
    this.gripOrientation,
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
    String? gripOrientation,
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
      gripOrientation: gripOrientation ?? this.gripOrientation,
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

/// Exercise angle (for bench exercises and cable pulley positions)
class ExerciseAngle {
  static const String flat = 'flat';
  static const String incline = 'incline';
  static const String decline = 'decline';
  static const String high = 'high';
  static const String low = 'low';
  static const String neutral = 'neutral';
  static const String na = 'na';

  static const List<String> all = [flat, incline, decline, high, low, neutral, na];

  static String getDisplayName(String angle) {
    switch (angle) {
      case flat:
        return 'Flat';
      case incline:
        return 'Incline';
      case decline:
        return 'Decline';
      case high:
        return 'High';
      case low:
        return 'Low';
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
      case high:
        return '하이';
      case low:
        return '로우';
      case neutral:
        return '중립';
      case na:
        return '해당없음';
      default:
        return angle;
    }
  }
}

/// Grip orientation for exercise variation filtering
class GripOrientation {
  static const String overhand = 'overhand';
  static const String underhand = 'underhand';
  static const String neutral = 'neutral';
  static const String mixed = 'mixed';
  static const String rotating = 'rotating';
  static const String na = 'na';

  static const List<String> all = [overhand, underhand, neutral, mixed, rotating, na];

  /// Filterable values (exclude 'na' from user-facing filters)
  static const List<String> filterable = [overhand, underhand, neutral, mixed, rotating];

  static String getDisplayName(String grip) {
    switch (grip) {
      case overhand:
        return 'Overhand';
      case underhand:
        return 'Underhand';
      case neutral:
        return 'Neutral';
      case mixed:
        return 'Mixed';
      case rotating:
        return 'Rotating';
      case na:
        return 'N/A';
      default:
        return grip;
    }
  }

  static String getDisplayNameKo(String grip) {
    switch (grip) {
      case overhand:
        return '오버핸드';
      case underhand:
        return '언더핸드';
      case neutral:
        return '뉴트럴';
      case mixed:
        return '믹스드';
      case rotating:
        return '로테이팅';
      case na:
        return '해당없음';
      default:
        return grip;
    }
  }
}

/// Exercise family constants with Korean display names
/// Each family groups similar exercise variations (e.g., all bench press variants)
class ExerciseFamily {
  // Chest
  static const String benchPress = 'bench_press';
  static const String fly = 'fly';
  static const String pushup = 'pushup';
  static const String pullover = 'pullover';

  // Shoulders
  static const String overheadPress = 'overhead_press';
  static const String lateralRaise = 'lateral_raise';
  static const String frontRaise = 'front_raise';
  static const String rearDelt = 'rear_delt';
  static const String yRaise = 'y_raise';
  static const String shrug = 'shrug';
  static const String uprightRow = 'upright_row';
  static const String shoulderMobility = 'shoulder_mobility';

  // Triceps
  static const String dip = 'dip';
  static const String tricepExtension = 'tricep_extension';
  static const String jmPress = 'jm_press';
  static const String tatePress = 'tate_press';

  // Back
  static const String row = 'row';
  static const String pulldown = 'pulldown';
  static const String pullup = 'pullup';
  static const String rackPull = 'rack_pull';
  static const String spineMobility = 'spine_mobility';

  // Biceps
  static const String curl = 'curl';

  // Forearms
  static const String wristCurl = 'wrist_curl';
  static const String grip = 'grip';

  // Legs - Quad dominant
  static const String squat = 'squat';
  static const String lunge = 'lunge';
  static const String legExtension = 'leg_extension';

  // Legs - Hip dominant
  static const String deadlift = 'deadlift';
  static const String hipThrust = 'hip_thrust';
  static const String legCurl = 'leg_curl';
  static const String gluteKickback = 'glute_kickback';
  static const String reverseHyper = 'reverse_hyper';

  // Legs - Other
  static const String calfRaise = 'calf_raise';
  static const String hipAdduction = 'hip_adduction';
  static const String hipAbduction = 'hip_abduction';
  static const String hipMobility = 'hip_mobility';
  static const String ankleMobility = 'ankle_mobility';

  // Core
  static const String plank = 'plank';
  static const String crunch = 'crunch';
  static const String carry = 'carry';
  static const String rotation = 'rotation';
  static const String mountainClimber = 'mountain_climber';

  // Full body / Cardio
  static const String sled = 'sled';
  static const String jump = 'jump';
  static const String burpee = 'burpee';
  static const String battleRopes = 'battle_ropes';
  static const String wallBall = 'wall_ball';
  static const String cardioMachine = 'cardio_machine';

  // Mobility
  static const String yoga = 'yoga';
  static const String foamRoll = 'foam_roll';

  /// Korean display names for each family key
  static String getDisplayNameKo(String family) {
    switch (family) {
      // Chest
      case benchPress: return '벤치 프레스';
      case fly: return '플라이';
      case pushup: return '푸시업';
      case pullover: return '풀오버';
      // Shoulders
      case overheadPress: return '오버헤드 프레스';
      case lateralRaise: return '레터럴 레이즈';
      case frontRaise: return '프론트 레이즈';
      case rearDelt: return '리어 델트';
      case yRaise: return 'Y 레이즈';
      case shrug: return '슈러그';
      case uprightRow: return '업라이트 로우';
      case shoulderMobility: return '어깨 모빌리티';
      // Triceps
      case dip: return '딥';
      case tricepExtension: return '트라이셉 익스텐션';
      case jmPress: return 'JM 프레스';
      case tatePress: return '테이트 프레스';
      // Back
      case row: return '로우';
      case pulldown: return '풀다운';
      case pullup: return '풀업';
      case rackPull: return '랙 풀';
      case spineMobility: return '척추 모빌리티';
      // Biceps
      case curl: return '컬';
      // Forearms
      case wristCurl: return '손목 컬';
      case grip: return '그립';
      // Legs
      case squat: return '스쿼트';
      case lunge: return '런지';
      case legExtension: return '레그 익스텐션';
      case deadlift: return '데드리프트';
      case hipThrust: return '힙 스러스트';
      case legCurl: return '레그 컬';
      case gluteKickback: return '글루트 킥백';
      case reverseHyper: return '리버스 하이퍼';
      case calfRaise: return '카프 레이즈';
      case hipAdduction: return '힙 어덕션';
      case hipAbduction: return '힙 어브덕션';
      case hipMobility: return '고관절 모빌리티';
      case ankleMobility: return '발목 모빌리티';
      // Core
      case plank: return '플랭크';
      case crunch: return '크런치';
      case carry: return '캐리';
      case rotation: return '로테이션';
      case mountainClimber: return '마운틴 클라이머';
      // Full body / Cardio
      case sled: return '슬레드';
      case jump: return '점프';
      case burpee: return '버피';
      case battleRopes: return '배틀 로프';
      case wallBall: return '월볼';
      case cardioMachine: return '유산소 머신';
      // Mobility
      case yoga: return '요가';
      case foamRoll: return '폼 롤링';
      default: return family.replaceAll('_', ' ');
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
