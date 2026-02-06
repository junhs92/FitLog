import 'package:freezed_annotation/freezed_annotation.dart';
import 'sleep_log_entity.dart';
import 'mood_log_entity.dart';

part 'lifestyle_summary_entity.freezed.dart';

/// Aggregated 7-day lifestyle summary for a client
/// Used in the pre-session flow (Flow 0) to show trainer the client's recent status
@freezed
class LifestyleSummaryEntity with _$LifestyleSummaryEntity {
  const factory LifestyleSummaryEntity({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
    required SleepSummary sleep,
    required MoodSummary mood,
    required NutritionSummary nutrition,
    required WeightSummary weight,
    required ActivitySummary activity,
  }) = _LifestyleSummaryEntity;

  const LifestyleSummaryEntity._();

  /// Check if there's any data recorded
  bool get hasData =>
      sleep.daysLogged > 0 ||
      mood.daysLogged > 0 ||
      nutrition.daysLogged > 0 ||
      weight.daysLogged > 0 ||
      activity.daysLogged > 0;
}

/// Sleep summary for 7 days
@freezed
class SleepSummary with _$SleepSummary {
  const factory SleepSummary({
    required int daysLogged,
    required double? avgHours,
    required SleepQuality? avgQuality,
    required double? avgBedtimeHour, // e.g., 23.5 = 11:30 PM
    required double? avgWakeTimeHour, // e.g., 7.0 = 7:00 AM
    @Default([]) List<DateTime> loggedDates, // Which days have data
  }) = _SleepSummary;

  const SleepSummary._();

  /// Format average bedtime as string (e.g., "11:30 PM")
  String? get avgBedtimeFormatted {
    if (avgBedtimeHour == null) return null;
    final hour = avgBedtimeHour!.floor();
    final minute = ((avgBedtimeHour! - hour) * 60).round();
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Format average wake time as string
  String? get avgWakeTimeFormatted {
    if (avgWakeTimeHour == null) return null;
    final hour = avgWakeTimeHour!.floor();
    final minute = ((avgWakeTimeHour! - hour) * 60).round();
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// Mood and energy summary for 7 days
@freezed
class MoodSummary with _$MoodSummary {
  const factory MoodSummary({
    required int daysLogged,
    required MoodLevel? avgMood,
    required EnergyLevel? avgEnergy,
    required double? avgStressLevel, // 1-10 scale
    @Default([]) List<DateTime> loggedDates, // Which days have data
  }) = _MoodSummary;
}

/// Nutrition summary for 7 days
@freezed
class NutritionSummary with _$NutritionSummary {
  const factory NutritionSummary({
    required int daysLogged,
    required int? avgCalories,
    required double? avgProtein,
    required double? avgCarbs,
    required double? avgFat,
    required int? avgWaterMl,
    @Default([]) List<DateTime> mealLoggedDates, // Which days have meal data
    @Default([]) List<DateTime> waterLoggedDates, // Which days have water data
  }) = _NutritionSummary;

  const NutritionSummary._();

  /// Format water as liters (e.g., "2.5L")
  String? get avgWaterFormatted {
    if (avgWaterMl == null) return null;
    final liters = avgWaterMl! / 1000;
    return '${liters.toStringAsFixed(1)}L';
  }
}

/// Weight trend summary for 7 days
@freezed
class WeightSummary with _$WeightSummary {
  const factory WeightSummary({
    required int daysLogged,
    required double? currentWeight,
    required double? startWeight,
    required double? changeKg,
    @Default([]) List<DateTime> loggedDates, // Which days have data
  }) = _WeightSummary;

  const WeightSummary._();

  /// Get weight change as formatted string with sign
  String? get changeFormatted {
    if (changeKg == null) return null;
    final sign = changeKg! > 0 ? '+' : '';
    return '$sign${changeKg!.toStringAsFixed(1)} kg';
  }

  /// Check if weight went down
  bool get isLoss => changeKg != null && changeKg! < 0;

  /// Check if weight went up
  bool get isGain => changeKg != null && changeKg! > 0;
}

/// Activity summary for 7 days
@freezed
class ActivitySummary with _$ActivitySummary {
  const factory ActivitySummary({
    required int daysLogged,
    required int? avgSteps,
    required int? avgActiveMinutes,
    required int? totalSteps,
    required int? totalActiveMinutes,
    @Default([]) List<DateTime> loggedDates, // Which days have data
  }) = _ActivitySummary;

  const ActivitySummary._();

  /// Format steps with thousands separator
  String? get avgStepsFormatted {
    if (avgSteps == null) return null;
    if (avgSteps! >= 1000) {
      return '${(avgSteps! / 1000).toStringAsFixed(1)}k';
    }
    return avgSteps.toString();
  }
}
