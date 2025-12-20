/// Exercise difficulty levels for progression and alternatives
enum ExerciseDifficulty {
  beginner(1, 'Beginner', '초급'),
  intermediate(2, 'Intermediate', '중급'),
  advanced(3, 'Advanced', '고급'),
  expert(4, 'Expert', '전문가');

  final int level;
  final String name;
  final String nameKo;

  const ExerciseDifficulty(this.level, this.name, this.nameKo);

  String get displayName => nameKo;

  /// Get easier difficulty level
  ExerciseDifficulty? get easier {
    if (level <= 1) return null;
    return ExerciseDifficulty.values.firstWhere((d) => d.level == level - 1);
  }

  /// Get harder difficulty level
  ExerciseDifficulty? get harder {
    if (level >= 4) return null;
    return ExerciseDifficulty.values.firstWhere((d) => d.level == level + 1);
  }

  static ExerciseDifficulty fromString(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (d) => d.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExerciseDifficulty.intermediate,
    );
  }
}

/// Equipment types available in gyms
enum EquipmentType {
  barbell('barbell', 'Barbell', '바벨'),
  dumbbell('dumbbell', 'Dumbbell', '덤벨'),
  kettlebell('kettlebell', 'Kettlebell', '케틀벨'),
  cable('cable', 'Cable Machine', '케이블'),
  machine('machine', 'Machine', '머신'),
  bodyweight('bodyweight', 'Bodyweight', '맨몸'),
  band('band', 'Resistance Band', '밴드'),
  smith('smith', 'Smith Machine', '스미스머신'),
  trx('trx', 'TRX/Suspension', 'TRX'),
  other('other', 'Other', '기타');

  final String id;
  final String name;
  final String nameKo;

  const EquipmentType(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static EquipmentType fromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.id == value.toLowerCase(),
      orElse: () => EquipmentType.other,
    );
  }
}

/// Primary muscle groups
enum MuscleGroup {
  chest('chest', 'Chest', '가슴'),
  back('back', 'Back', '등'),
  shoulders('shoulders', 'Shoulders', '어깨'),
  biceps('biceps', 'Biceps', '이두'),
  triceps('triceps', 'Triceps', '삼두'),
  forearms('forearms', 'Forearms', '전완'),
  quadriceps('quadriceps', 'Quadriceps', '대퇴사두'),
  hamstrings('hamstrings', 'Hamstrings', '햄스트링'),
  glutes('glutes', 'Glutes', '둔근'),
  calves('calves', 'Calves', '종아리'),
  core('core', 'Core', '코어'),
  fullBody('full_body', 'Full Body', '전신');

  final String id;
  final String name;
  final String nameKo;

  const MuscleGroup(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static MuscleGroup fromString(String value) {
    return MuscleGroup.values.firstWhere(
      (m) => m.id == value.toLowerCase(),
      orElse: () => MuscleGroup.fullBody,
    );
  }
}
