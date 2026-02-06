/// Enum representing all supported muscle groups in the system
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  adductors,
  core,
  abs,
  lats,
  traps,
  fullBody;

  /// Get display name in English
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quadriceps:
        return 'Quadriceps';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.adductors:
        return 'Adductors';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.lats:
        return 'Lats';
      case MuscleGroup.traps:
        return 'Traps';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  /// Get display name in Korean
  String get displayNameKo {
    switch (this) {
      case MuscleGroup.chest:
        return '가슴';
      case MuscleGroup.back:
        return '등';
      case MuscleGroup.shoulders:
        return '어깨';
      case MuscleGroup.biceps:
        return '이두';
      case MuscleGroup.triceps:
        return '삼두';
      case MuscleGroup.forearms:
        return '전완';
      case MuscleGroup.quadriceps:
        return '대퇴사두';
      case MuscleGroup.hamstrings:
        return '햄스트링';
      case MuscleGroup.glutes:
        return '둔근';
      case MuscleGroup.calves:
        return '종아리';
      case MuscleGroup.adductors:
        return '내전근';
      case MuscleGroup.core:
        return '코어';
      case MuscleGroup.abs:
        return '복근';
      case MuscleGroup.lats:
        return '광배근';
      case MuscleGroup.traps:
        return '승모근';
      case MuscleGroup.fullBody:
        return '전신';
    }
  }

  /// Get the database key for this muscle group
  String get key => name;

  /// Whether this muscle is primarily visible from the front view
  bool get isFrontView {
    switch (this) {
      case MuscleGroup.chest:
      case MuscleGroup.shoulders:
      case MuscleGroup.biceps:
      case MuscleGroup.forearms:
      case MuscleGroup.quadriceps:
      case MuscleGroup.adductors:
      case MuscleGroup.core:
      case MuscleGroup.abs:
        return true;
      case MuscleGroup.back:
      case MuscleGroup.triceps:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
      case MuscleGroup.lats:
      case MuscleGroup.traps:
        return false;
      case MuscleGroup.fullBody:
        return true; // Show on front by default
    }
  }

  /// Get muscle groups that are expanded from fullBody
  static List<MuscleGroup> get fullBodyMuscles => [
        MuscleGroup.chest,
        MuscleGroup.back,
        MuscleGroup.shoulders,
        MuscleGroup.biceps,
        MuscleGroup.triceps,
        MuscleGroup.quadriceps,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.core,
      ];

  /// Parse muscle group from string (database value)
  static MuscleGroup? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.toLowerCase().replaceAll('_', '');
    for (final group in MuscleGroup.values) {
      if (group.name.toLowerCase() == normalized ||
          group.key.toLowerCase() == value.toLowerCase()) {
        return group;
      }
    }
    // Handle special cases
    if (normalized == 'fullbody' || value == 'full_body') {
      return MuscleGroup.fullBody;
    }
    return null;
  }
}
