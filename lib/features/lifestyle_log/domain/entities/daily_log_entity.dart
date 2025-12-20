import 'package:equatable/equatable.dart';
import 'meal_log_entity.dart';
import 'water_log_entity.dart';
import 'sleep_log_entity.dart';
import 'mood_log_entity.dart';
import 'body_photo_entity.dart';

/// Entity representing a complete daily lifestyle log
class DailyLogEntity extends Equatable {
  final String clientId;
  final DateTime date;
  final List<MealLogEntity> meals;
  final DailyWaterSummary? waterSummary;
  final SleepLogEntity? sleep;
  final MoodLogEntity? mood;
  final List<BodyPhotoEntity> bodyPhotos;
  final int? steps;
  final int? activeMinutes;
  final double? weight;

  const DailyLogEntity({
    required this.clientId,
    required this.date,
    this.meals = const [],
    this.waterSummary,
    this.sleep,
    this.mood,
    this.bodyPhotos = const [],
    this.steps,
    this.activeMinutes,
    this.weight,
  });

  /// Check if any data is logged for this day
  bool get hasAnyData =>
      meals.isNotEmpty ||
      waterSummary != null ||
      sleep != null ||
      mood != null ||
      bodyPhotos.isNotEmpty ||
      steps != null ||
      weight != null;

  /// Get meal by type
  MealLogEntity? getMealByType(MealType type) {
    try {
      return meals.firstWhere((m) => m.mealType == type);
    } catch (_) {
      return null;
    }
  }

  /// Total logged meals count
  int get mealCount => meals.length;

  /// Total calories from meals
  int? get totalCalories {
    if (meals.isEmpty) return null;
    int total = 0;
    bool hasAny = false;
    for (final meal in meals) {
      if (meal.calories != null) {
        total += meal.calories!;
        hasAny = true;
      }
    }
    return hasAny ? total : null;
  }

  /// Total protein from meals
  double? get totalProtein {
    if (meals.isEmpty) return null;
    double total = 0;
    bool hasAny = false;
    for (final meal in meals) {
      if (meal.protein != null) {
        total += meal.protein!;
        hasAny = true;
      }
    }
    return hasAny ? total : null;
  }

  /// Completion score (0-100)
  int get completionScore {
    int score = 0;
    int total = 0;

    // Meals (up to 30 points)
    total += 30;
    if (meals.isNotEmpty) {
      score += (meals.length * 10).clamp(0, 30);
    }

    // Water (20 points)
    total += 20;
    if (waterSummary != null && waterSummary!.goalReached) {
      score += 20;
    } else if (waterSummary != null && waterSummary!.progress >= 0.5) {
      score += 10;
    }

    // Sleep (20 points)
    total += 20;
    if (sleep != null && sleep!.duration != null) {
      score += 20;
    }

    // Mood (15 points)
    total += 15;
    if (mood != null && mood!.mood != null) {
      score += 15;
    }

    // Activity (15 points)
    total += 15;
    if (steps != null && steps! > 0) {
      score += 15;
    }

    return total > 0 ? ((score / total) * 100).round() : 0;
  }

  /// Summary text for the day
  String get summaryText {
    final parts = <String>[];

    if (meals.isNotEmpty) {
      parts.add('${meals.length} meal${meals.length > 1 ? 's' : ''}');
    }
    if (waterSummary != null) {
      parts.add(waterSummary!.displayTotal);
    }
    if (sleep?.durationDisplay != null) {
      parts.add('${sleep!.durationDisplay} sleep');
    }
    if (steps != null) {
      parts.add('$steps steps');
    }

    return parts.isEmpty ? 'No data logged' : parts.join(' • ');
  }

  DailyLogEntity copyWith({
    String? clientId,
    DateTime? date,
    List<MealLogEntity>? meals,
    DailyWaterSummary? waterSummary,
    SleepLogEntity? sleep,
    MoodLogEntity? mood,
    List<BodyPhotoEntity>? bodyPhotos,
    int? steps,
    int? activeMinutes,
    double? weight,
  }) {
    return DailyLogEntity(
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      waterSummary: waterSummary ?? this.waterSummary,
      sleep: sleep ?? this.sleep,
      mood: mood ?? this.mood,
      bodyPhotos: bodyPhotos ?? this.bodyPhotos,
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      weight: weight ?? this.weight,
    );
  }

  @override
  List<Object?> get props => [
        clientId,
        date,
        meals,
        waterSummary,
        sleep,
        mood,
        bodyPhotos,
        steps,
        activeMinutes,
        weight,
      ];
}
