import 'auto_achievement.dart';

/// A detected achievement instance with context data
class DetectedAchievement {
  final AutoAchievement type;

  /// Exercise name for exercise-specific achievements (PRs, streaks)
  final String? exerciseName;

  /// Primary value (e.g., new 1RM, volume, session count)
  final double? value;

  /// Previous value for comparison (e.g., old 1RM, last session volume)
  final double? previousValue;

  /// Percentage change (for volume/sets increases)
  final double? percentageChange;

  /// Additional context string (e.g., "80kg x 8" for PR)
  final String? context;

  const DetectedAchievement({
    required this.type,
    this.exerciseName,
    this.value,
    this.previousValue,
    this.percentageChange,
    this.context,
  });

  /// Get formatted description based on achievement type
  String get description {
    switch (type) {
      case AutoAchievement.prEstimated1RM:
        if (exerciseName != null && value != null) {
          return '추정 1RM ${value!.toStringAsFixed(0)}kg 달성!';
        }
        return '추정 1RM 신기록 달성!';

      case AutoAchievement.prWeight:
        if (exerciseName != null && context != null) {
          return '$context';
        }
        return '최고 무게 달성!';

      case AutoAchievement.prVolume:
        if (exerciseName != null && value != null) {
          return '단일 세트 볼륨 ${value!.toStringAsFixed(0)}kg';
        }
        return '세트 볼륨 신기록!';

      case AutoAchievement.volumeIncrease:
        if (percentageChange != null) {
          return '지난 세션 대비 ${percentageChange!.toStringAsFixed(0)}% 증가';
        }
        return '총 볼륨이 증가했습니다!';

      case AutoAchievement.moreSets:
        if (value != null && previousValue != null) {
          return '${value!.toInt()}세트 (이전: ${previousValue!.toInt()}세트)';
        }
        return '세트 수가 증가했습니다!';

      case AutoAchievement.progressiveOverload:
        if (exerciseName != null) {
          return '$exerciseName 무게 증가!';
        }
        return '이전보다 더 무거운 무게!';

      case AutoAchievement.weeklyStreak2:
        return '이번 주 2회째 운동입니다!';

      case AutoAchievement.weeklyStreak3:
        return '이번 주 3회째 운동입니다!';

      case AutoAchievement.weeklyStreak4:
        return '이번 주 4회 이상 운동 중!';

      case AutoAchievement.exerciseStreak3:
        if (exerciseName != null) {
          return '$exerciseName 3회 연속 수행!';
        }
        return '같은 운동 3회 연속 수행!';

      case AutoAchievement.highIntensitySet:
        if (context != null) {
          return '$context';
        }
        return 'RPE 8 이상의 고강도 세트!';

      case AutoAchievement.maxEffortSession:
        if (value != null) {
          return '${value!.toInt()}개의 RPE 9+ 세트!';
        }
        return '여러 세트에서 최대 노력!';

      case AutoAchievement.session10:
        return '10번째 세션을 완료했습니다!';

      case AutoAchievement.session25:
        return '25번째 세션을 완료했습니다!';

      case AutoAchievement.session50:
        return '50번째 세션을 완료했습니다!';

      case AutoAchievement.session100:
        return '100번째 세션을 완료했습니다!';

      case AutoAchievement.firstPR:
        if (exerciseName != null) {
          return '$exerciseName 첫 기록 달성!';
        }
        return '첫 번째 기록을 세웠습니다!';

      case AutoAchievement.firstSession:
        return '첫 세션을 완료했습니다!';
    }
  }

  /// Get subtitle for the achievement (exercise name if applicable)
  String? get subtitle {
    switch (type) {
      case AutoAchievement.prEstimated1RM:
      case AutoAchievement.prWeight:
      case AutoAchievement.prVolume:
      case AutoAchievement.progressiveOverload:
      case AutoAchievement.exerciseStreak3:
      case AutoAchievement.firstPR:
        return exerciseName;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedAchievement &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          exerciseName == other.exerciseName;

  @override
  int get hashCode => type.hashCode ^ (exerciseName?.hashCode ?? 0);
}
