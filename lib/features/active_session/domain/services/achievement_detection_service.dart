import '../entities/auto_achievement.dart';
import '../entities/detected_achievement.dart';
import '../entities/exercise_set_entity.dart';
import '../entities/session_entity.dart';

/// Service for detecting achievements from session data
class AchievementDetectionService {
  /// Detect all achievements for a completed session
  ///
  /// [currentSession] - The session that was just completed
  /// [sessionHistory] - Previous completed sessions (newest first)
  /// [exerciseHistories] - Map of exerciseId -> list of historical sets
  List<DetectedAchievement> detectAchievements({
    required SessionEntity currentSession,
    required List<SessionEntity> sessionHistory,
    required Map<String, List<ExerciseSetEntity>> exerciseHistories,
  }) {
    final achievements = <DetectedAchievement>[];

    // Performance achievements
    achievements.addAll(_detectPRs(currentSession, exerciseHistories));
    achievements.addAll(_detectVolumeIncrease(currentSession, sessionHistory));
    achievements.addAll(_detectMoreSets(currentSession, sessionHistory));
    achievements.addAll(_detectProgressiveOverload(currentSession, sessionHistory));

    // Consistency achievements
    achievements.addAll(_detectWeeklyStreak(sessionHistory));
    achievements.addAll(_detectExerciseStreak(currentSession, sessionHistory));

    // Effort achievements
    achievements.addAll(_detectHighIntensity(currentSession));

    // Milestone achievements
    achievements.addAll(_detectMilestones(sessionHistory));

    return achievements;
  }

  /// Detect PR achievements (1RM, weight, volume)
  List<DetectedAchievement> _detectPRs(
    SessionEntity session,
    Map<String, List<ExerciseSetEntity>> exerciseHistories,
  ) {
    final achievements = <DetectedAchievement>[];

    for (final exercise in session.exercises) {
      if (exercise.sets.isEmpty) continue;

      final history = exerciseHistories[exercise.exercise.id] ?? [];
      final isFirstTime = history.isEmpty;

      // Calculate best estimated 1RM from this session
      double bestSessionEstimated1RM = 0;
      ExerciseSetEntity? bestSessionSet;
      for (final set in exercise.sets) {
        final estimated1RM = _calculateEstimated1RM(set.weight ?? 0, set.reps ?? 0);
        if (estimated1RM > bestSessionEstimated1RM) {
          bestSessionEstimated1RM = estimated1RM;
          bestSessionSet = set;
        }
      }

      // Calculate historical best estimated 1RM
      double historicalBest1RM = 0;
      for (final set in history) {
        final estimated1RM = _calculateEstimated1RM(set.weight ?? 0, set.reps ?? 0);
        if (estimated1RM > historicalBest1RM) {
          historicalBest1RM = estimated1RM;
        }
      }

      // First PR for this exercise
      if (isFirstTime && bestSessionSet != null) {
        achievements.add(DetectedAchievement(
          type: AutoAchievement.firstPR,
          exerciseName: exercise.exercise.displayName,
          value: bestSessionEstimated1RM,
          context: '${bestSessionSet.weight?.toStringAsFixed(0)}kg x ${bestSessionSet.reps}',
        ));
      }
      // New estimated 1RM PR (>1% improvement)
      else if (bestSessionEstimated1RM > historicalBest1RM * 1.01 && bestSessionSet != null) {
        achievements.add(DetectedAchievement(
          type: AutoAchievement.prEstimated1RM,
          exerciseName: exercise.exercise.displayName,
          value: bestSessionEstimated1RM,
          previousValue: historicalBest1RM,
          context: '${bestSessionSet.weight?.toStringAsFixed(0)}kg x ${bestSessionSet.reps}',
        ));
      }

      // Check for weight PR (heaviest weight at same or more reps)
      for (final set in exercise.sets) {
        if (set.weight == null || set.reps == null) continue;
        final weight = set.weight!;
        final reps = set.reps!;

        // Find max weight at same or more reps in history
        double maxHistoricalWeight = 0;
        for (final histSet in history) {
          if ((histSet.reps ?? 0) >= reps && (histSet.weight ?? 0) > maxHistoricalWeight) {
            maxHistoricalWeight = histSet.weight ?? 0;
          }
        }

        if (weight > maxHistoricalWeight && !isFirstTime) {
          achievements.add(DetectedAchievement(
            type: AutoAchievement.prWeight,
            exerciseName: exercise.exercise.displayName,
            value: weight,
            previousValue: maxHistoricalWeight,
            context: '${weight.toStringAsFixed(0)}kg x $reps',
          ));
          break; // Only one weight PR per exercise
        }
      }

      // Check for single-set volume PR
      double bestSessionVolume = 0;
      ExerciseSetEntity? bestVolumeSet;
      for (final set in exercise.sets) {
        final volume = (set.weight ?? 0) * (set.reps ?? 0);
        if (volume > bestSessionVolume) {
          bestSessionVolume = volume;
          bestVolumeSet = set;
        }
      }

      double historicalBestVolume = 0;
      for (final set in history) {
        final volume = (set.weight ?? 0) * (set.reps ?? 0);
        if (volume > historicalBestVolume) {
          historicalBestVolume = volume;
        }
      }

      if (bestSessionVolume > historicalBestVolume * 1.01 && !isFirstTime && bestVolumeSet != null) {
        achievements.add(DetectedAchievement(
          type: AutoAchievement.prVolume,
          exerciseName: exercise.exercise.displayName,
          value: bestSessionVolume,
          previousValue: historicalBestVolume,
          context: '${bestVolumeSet.weight?.toStringAsFixed(0)}kg x ${bestVolumeSet.reps}',
        ));
      }
    }

    return achievements;
  }

  /// Detect session volume increase
  List<DetectedAchievement> _detectVolumeIncrease(
    SessionEntity session,
    List<SessionEntity> history,
  ) {
    if (history.isEmpty) return [];

    final currentVolume = session.totalVolume;
    final lastSession = history.first;
    final lastVolume = lastSession.totalVolume;

    if (currentVolume > lastVolume && lastVolume > 0) {
      final percentChange = ((currentVolume - lastVolume) / lastVolume) * 100;
      return [
        DetectedAchievement(
          type: AutoAchievement.volumeIncrease,
          value: currentVolume,
          previousValue: lastVolume,
          percentageChange: percentChange,
        ),
      ];
    }

    return [];
  }

  /// Detect more sets than last session
  List<DetectedAchievement> _detectMoreSets(
    SessionEntity session,
    List<SessionEntity> history,
  ) {
    if (history.isEmpty) return [];

    final currentSets = session.totalSetsCount;
    final lastSession = history.first;
    final lastSets = lastSession.totalSetsCount;

    if (currentSets > lastSets && lastSets > 0) {
      return [
        DetectedAchievement(
          type: AutoAchievement.moreSets,
          value: currentSets.toDouble(),
          previousValue: lastSets.toDouble(),
        ),
      ];
    }

    return [];
  }

  /// Detect progressive overload (heavier weight than last session for same exercise)
  List<DetectedAchievement> _detectProgressiveOverload(
    SessionEntity session,
    List<SessionEntity> history,
  ) {
    if (history.isEmpty) return [];

    final achievements = <DetectedAchievement>[];
    final lastSession = history.first;

    for (final exercise in session.exercises) {
      if (exercise.sets.isEmpty) continue;

      // Find same exercise in last session
      final lastExercise = lastSession.exercises
          .where((e) => e.exercise.id == exercise.exercise.id)
          .firstOrNull;

      if (lastExercise == null || lastExercise.sets.isEmpty) continue;

      // Compare max weights
      final currentMaxWeight = exercise.sets
          .map((s) => s.weight ?? 0)
          .reduce((a, b) => a > b ? a : b);
      final lastMaxWeight = lastExercise.sets
          .map((s) => s.weight ?? 0)
          .reduce((a, b) => a > b ? a : b);

      if (currentMaxWeight > lastMaxWeight) {
        achievements.add(DetectedAchievement(
          type: AutoAchievement.progressiveOverload,
          exerciseName: exercise.exercise.displayName,
          value: currentMaxWeight,
          previousValue: lastMaxWeight,
        ));
      }
    }

    return achievements;
  }

  /// Detect weekly streak (sessions this week including current)
  List<DetectedAchievement> _detectWeeklyStreak(List<SessionEntity> history) {
    // Calculate start of current week (Monday)
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));

    // Count sessions completed this week (including current session)
    int sessionsThisWeek = 1; // Current session counts as 1
    for (final session in history) {
      final completedAt = session.completedAt;
      if (completedAt != null && completedAt.isAfter(weekStart)) {
        sessionsThisWeek++;
      }
    }

    if (sessionsThisWeek >= 4) {
      return [const DetectedAchievement(type: AutoAchievement.weeklyStreak4)];
    } else if (sessionsThisWeek == 3) {
      return [const DetectedAchievement(type: AutoAchievement.weeklyStreak3)];
    } else if (sessionsThisWeek == 2) {
      return [const DetectedAchievement(type: AutoAchievement.weeklyStreak2)];
    }

    return [];
  }

  /// Detect exercise streak (same exercise in 3 consecutive sessions)
  List<DetectedAchievement> _detectExerciseStreak(
    SessionEntity session,
    List<SessionEntity> history,
  ) {
    if (history.length < 2) return [];

    final achievements = <DetectedAchievement>[];

    for (final exercise in session.exercises) {
      final exerciseId = exercise.exercise.id;
      int streak = 1; // Current session

      // Check last 2 sessions
      for (int i = 0; i < 2 && i < history.length; i++) {
        final hasExercise = history[i].exercises.any((e) => e.exercise.id == exerciseId);
        if (hasExercise) {
          streak++;
        } else {
          break;
        }
      }

      if (streak >= 3) {
        achievements.add(DetectedAchievement(
          type: AutoAchievement.exerciseStreak3,
          exerciseName: exercise.exercise.displayName,
        ));
      }
    }

    return achievements;
  }

  /// Detect high intensity achievements
  List<DetectedAchievement> _detectHighIntensity(SessionEntity session) {
    final achievements = <DetectedAchievement>[];
    int rpe9PlusSets = 0;
    String? highIntensityContext;

    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        final rpe = set.rpe;
        if (rpe == null) continue;

        if (rpe >= 9) {
          rpe9PlusSets++;
        }

        // Track first RPE 8+ set for context
        if (rpe >= 8 && highIntensityContext == null) {
          highIntensityContext =
              '${exercise.exercise.displayName} ${set.weight?.toStringAsFixed(0)}kg x ${set.reps} @ RPE ${rpe.toStringAsFixed(0)}';
        }
      }
    }

    // Multiple RPE 9+ sets
    if (rpe9PlusSets >= 3) {
      achievements.add(DetectedAchievement(
        type: AutoAchievement.maxEffortSession,
        value: rpe9PlusSets.toDouble(),
      ));
    }

    // At least one RPE 8+ set
    if (highIntensityContext != null) {
      achievements.add(DetectedAchievement(
        type: AutoAchievement.highIntensitySet,
        context: highIntensityContext,
      ));
    }

    return achievements;
  }

  /// Detect session milestone achievements
  List<DetectedAchievement> _detectMilestones(List<SessionEntity> history) {
    // Session count includes current session
    final sessionCount = history.length + 1;

    if (sessionCount == 1) {
      return [const DetectedAchievement(type: AutoAchievement.firstSession)];
    } else if (sessionCount == 10) {
      return [const DetectedAchievement(type: AutoAchievement.session10)];
    } else if (sessionCount == 25) {
      return [const DetectedAchievement(type: AutoAchievement.session25)];
    } else if (sessionCount == 50) {
      return [const DetectedAchievement(type: AutoAchievement.session50)];
    } else if (sessionCount == 100) {
      return [const DetectedAchievement(type: AutoAchievement.session100)];
    }

    return [];
  }

  /// Calculate estimated 1RM using Epley formula
  /// Formula: weight × (1 + reps/30)
  double _calculateEstimated1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight; // Actual 1RM
    return weight * (1 + reps / 30);
  }
}
