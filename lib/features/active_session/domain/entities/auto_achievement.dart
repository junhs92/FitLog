/// Categories for auto-achievements
enum AchievementCategory {
  performance, // 성과
  consistency, // 꾸준함
  effort, // 노력
  milestone, // 마일스톤
}

/// Auto-generated motivational achievements
enum AutoAchievement {
  // ============ Performance (성과) - 6 items ============
  prEstimated1RM, // New estimated 1RM
  prWeight, // Heaviest weight at same+ reps
  prVolume, // Highest single-set volume
  volumeIncrease, // Session volume > last session
  moreSets, // More sets than last session
  progressiveOverload, // Heavier weight than last session

  // ============ Consistency (꾸준함) - 4 items ============
  weeklyStreak2, // 2 sessions this week
  weeklyStreak3, // 3 sessions this week
  weeklyStreak4, // 4+ sessions this week
  exerciseStreak3, // Same exercise 3x in a row

  // ============ Effort (노력) - 2 items ============
  highIntensitySet, // RPE 8+ logged
  maxEffortSession, // Multiple RPE 9+ sets

  // ============ Milestone (마일스톤) - 6 items ============
  session10, // 10 sessions completed
  session25, // 25 sessions completed
  session50, // 50 sessions completed
  session100, // 100 sessions completed
  firstPR, // First ever PR for exercise
  firstSession, // First session ever
}

extension AutoAchievementExtension on AutoAchievement {
  /// Korean display name
  String get displayName {
    switch (this) {
      // Performance
      case AutoAchievement.prEstimated1RM:
        return '1RM 신기록!';
      case AutoAchievement.prWeight:
        return '무게 신기록!';
      case AutoAchievement.prVolume:
        return '볼륨 신기록!';
      case AutoAchievement.volumeIncrease:
        return '볼륨 증가!';
      case AutoAchievement.moreSets:
        return '세트 수 증가!';
      case AutoAchievement.progressiveOverload:
        return '점진적 과부하!';
      // Consistency
      case AutoAchievement.weeklyStreak2:
        return '이번 주 2회 운동!';
      case AutoAchievement.weeklyStreak3:
        return '이번 주 3회 운동!';
      case AutoAchievement.weeklyStreak4:
        return '이번 주 4회 이상!';
      case AutoAchievement.exerciseStreak3:
        return '3회 연속 수행!';
      // Effort
      case AutoAchievement.highIntensitySet:
        return '고강도 세트!';
      case AutoAchievement.maxEffortSession:
        return '최대 노력!';
      // Milestone
      case AutoAchievement.session10:
        return '10회 세션 달성!';
      case AutoAchievement.session25:
        return '25회 세션 달성!';
      case AutoAchievement.session50:
        return '50회 세션 달성!';
      case AutoAchievement.session100:
        return '100회 세션 달성!';
      case AutoAchievement.firstPR:
        return '첫 신기록!';
      case AutoAchievement.firstSession:
        return '첫 세션 완료!';
    }
  }

  /// English display name
  String get displayNameEn {
    switch (this) {
      // Performance
      case AutoAchievement.prEstimated1RM:
        return 'New 1RM PR!';
      case AutoAchievement.prWeight:
        return 'Weight PR!';
      case AutoAchievement.prVolume:
        return 'Volume PR!';
      case AutoAchievement.volumeIncrease:
        return 'Volume Increase!';
      case AutoAchievement.moreSets:
        return 'More Sets!';
      case AutoAchievement.progressiveOverload:
        return 'Progressive Overload!';
      // Consistency
      case AutoAchievement.weeklyStreak2:
        return '2 Sessions This Week!';
      case AutoAchievement.weeklyStreak3:
        return '3 Sessions This Week!';
      case AutoAchievement.weeklyStreak4:
        return '4+ Sessions This Week!';
      case AutoAchievement.exerciseStreak3:
        return '3x Exercise Streak!';
      // Effort
      case AutoAchievement.highIntensitySet:
        return 'High Intensity Set!';
      case AutoAchievement.maxEffortSession:
        return 'Maximum Effort!';
      // Milestone
      case AutoAchievement.session10:
        return '10 Sessions!';
      case AutoAchievement.session25:
        return '25 Sessions!';
      case AutoAchievement.session50:
        return '50 Sessions!';
      case AutoAchievement.session100:
        return '100 Sessions!';
      case AutoAchievement.firstPR:
        return 'First PR!';
      case AutoAchievement.firstSession:
        return 'First Session!';
    }
  }

  /// Category of the achievement
  AchievementCategory get category {
    switch (this) {
      case AutoAchievement.prEstimated1RM:
      case AutoAchievement.prWeight:
      case AutoAchievement.prVolume:
      case AutoAchievement.volumeIncrease:
      case AutoAchievement.moreSets:
      case AutoAchievement.progressiveOverload:
        return AchievementCategory.performance;
      case AutoAchievement.weeklyStreak2:
      case AutoAchievement.weeklyStreak3:
      case AutoAchievement.weeklyStreak4:
      case AutoAchievement.exerciseStreak3:
        return AchievementCategory.consistency;
      case AutoAchievement.highIntensitySet:
      case AutoAchievement.maxEffortSession:
        return AchievementCategory.effort;
      case AutoAchievement.session10:
      case AutoAchievement.session25:
      case AutoAchievement.session50:
      case AutoAchievement.session100:
      case AutoAchievement.firstPR:
      case AutoAchievement.firstSession:
        return AchievementCategory.milestone;
    }
  }

  /// Icon for the achievement
  String get icon {
    switch (category) {
      case AchievementCategory.performance:
        return '🏆';
      case AchievementCategory.consistency:
        return '🔥';
      case AchievementCategory.effort:
        return '💪';
      case AchievementCategory.milestone:
        return '⭐';
    }
  }
}

extension AchievementCategoryExtension on AchievementCategory {
  /// Display name in Korean
  String get displayName {
    switch (this) {
      case AchievementCategory.performance:
        return '성과';
      case AchievementCategory.consistency:
        return '꾸준함';
      case AchievementCategory.effort:
        return '노력';
      case AchievementCategory.milestone:
        return '마일스톤';
    }
  }

  /// Display name in English
  String get displayNameEn {
    switch (this) {
      case AchievementCategory.performance:
        return 'Performance';
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.effort:
        return 'Effort';
      case AchievementCategory.milestone:
        return 'Milestone';
    }
  }

  /// Get all achievements in this category
  List<AutoAchievement> get achievements {
    return AutoAchievement.values.where((a) => a.category == this).toList();
  }
}
