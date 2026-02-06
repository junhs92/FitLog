import '../../../../shared/models/result.dart';
import '../entities/daily_log_entity.dart';
import '../entities/exercise_stats_entity.dart';
import '../entities/exercise_volume_history_entity.dart';
import '../entities/lifestyle_summary_entity.dart';
import '../entities/meal_log_entity.dart';
import '../entities/water_log_entity.dart';
import '../entities/sleep_log_entity.dart';
import '../entities/mood_log_entity.dart';
import '../entities/body_photo_entity.dart';

/// Repository interface for lifestyle logging operations
abstract class LifestyleRepository {
  // =============== 7-Day Lifestyle Summary ===============

  /// Get aggregated 7-day lifestyle summary for a client
  /// Used in Flow 0 (Pre-Session) to show trainer the client's recent status
  Future<Result<LifestyleSummaryEntity>> get7DayLifestyleSummary({
    required String clientId,
  });
  // =============== Daily Log Operations ===============

  /// Get daily log for a specific date
  Future<Result<DailyLogEntity>> getDailyLog({
    required String clientId,
    required DateTime date,
  });

  /// Get daily logs for a date range
  Future<Result<List<DailyLogEntity>>> getDailyLogs({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // =============== Meal Operations ===============

  /// Log a meal
  Future<Result<MealLogEntity>> logMeal({
    required String clientId,
    required DateTime date,
    required MealType mealType,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  });

  /// Update a meal log
  Future<Result<MealLogEntity>> updateMeal({
    required String mealId,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  });

  /// Delete a meal log
  Future<Result<void>> deleteMeal(String mealId);

  /// Get meals for a date
  Future<Result<List<MealLogEntity>>> getMeals({
    required String clientId,
    required DateTime date,
  });

  // =============== Water Operations ===============

  /// Log water intake
  Future<Result<WaterLogEntity>> logWater({
    required String clientId,
    required DateTime date,
    required int amountMl,
  });

  /// Delete a water log entry
  Future<Result<void>> deleteWater(String waterLogId);

  /// Get water summary for a date
  Future<Result<DailyWaterSummary>> getWaterSummary({
    required String clientId,
    required DateTime date,
    int goalMl = 2500,
  });

  /// Get water history for date range
  Future<Result<List<DailyWaterSummary>>> getWaterHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
    int goalMl = 2500,
  });

  // =============== Sleep Operations ===============

  /// Log sleep
  Future<Result<SleepLogEntity>> logSleep({
    required String clientId,
    required DateTime date,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  });

  /// Update sleep log
  Future<Result<SleepLogEntity>> updateSleep({
    required String sleepId,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  });

  /// Get sleep log for a date
  Future<Result<SleepLogEntity?>> getSleep({
    required String clientId,
    required DateTime date,
  });

  /// Get sleep history for date range
  Future<Result<List<SleepLogEntity>>> getSleepHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // =============== Mood Operations ===============

  /// Log mood and energy
  Future<Result<MoodLogEntity>> logMood({
    required String clientId,
    required DateTime date,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  });

  /// Update mood log
  Future<Result<MoodLogEntity>> updateMood({
    required String moodId,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  });

  /// Get mood log for a date
  Future<Result<MoodLogEntity?>> getMood({
    required String clientId,
    required DateTime date,
  });

  /// Get mood history for date range
  Future<Result<List<MoodLogEntity>>> getMoodHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // =============== Body Photo Operations ===============

  /// Upload and log a body photo
  Future<Result<BodyPhotoEntity>> logBodyPhoto({
    required String clientId,
    required DateTime date,
    required PhotoAngle angle,
    required String localFilePath,
    double? weight,
    String? notes,
  });

  /// Delete a body photo
  Future<Result<void>> deleteBodyPhoto(String photoId);

  /// Get body photos for a client
  Future<Result<List<BodyPhotoEntity>>> getBodyPhotos({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
    PhotoAngle? angle,
    int limit = 50,
  });

  // =============== Weight Operations ===============

  /// Log weight
  Future<Result<void>> logWeight({
    required String clientId,
    required DateTime date,
    required double weight,
  });

  /// Get weight history
  Future<Result<List<({DateTime date, double weight})>>> getWeightHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // =============== Activity Operations ===============

  /// Log daily activity (steps, active minutes)
  Future<Result<void>> logActivity({
    required String clientId,
    required DateTime date,
    int? steps,
    int? activeMinutes,
  });

  /// Get activity history
  Future<Result<List<({DateTime date, int? steps, int? activeMinutes})>>>
      getActivityHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // =============== Exercise Stats Operations ===============

  /// Get aggregated exercise statistics for a client
  /// [dayRange] - Optional number of days to look back (null = all time)
  Future<Result<List<ExerciseStatsEntity>>> getExerciseStats({
    required String clientId,
    int? dayRange,
  });

  /// Get exercise volume history for charting
  /// Returns sessions with volume totals ordered by date
  Future<Result<ExerciseVolumeHistoryEntity>> getExerciseVolumeHistory({
    required String clientId,
    required String exerciseId,
    int limit = 50,
  });
}
