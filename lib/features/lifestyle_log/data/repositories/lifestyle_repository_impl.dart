import 'package:dartz/dartz.dart';
import '../../../../shared/models/result.dart';
import '../../domain/entities/daily_log_entity.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/water_log_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/mood_log_entity.dart';
import '../../domain/entities/body_photo_entity.dart';
import '../../domain/repositories/lifestyle_repository.dart';
import '../datasources/lifestyle_remote_datasource.dart';

/// Implementation of LifestyleRepository
class LifestyleRepositoryImpl implements LifestyleRepository {
  final LifestyleRemoteDataSource _remoteDataSource;

  LifestyleRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<DailyLogEntity>> getDailyLog({
    required String clientId,
    required DateTime date,
  }) async {
    try {
      // Fetch all data for the day in parallel
      final results = await Future.wait([
        _remoteDataSource.getMeals(clientId: clientId, date: date),
        _remoteDataSource.getWaterLogs(clientId: clientId, date: date),
        _remoteDataSource.getSleep(clientId: clientId, date: date),
        _remoteDataSource.getMood(clientId: clientId, date: date),
        _remoteDataSource.getBodyPhotos(
          clientId: clientId,
          fromDate: date,
          toDate: date,
        ),
      ]);

      final meals = results[0] as List<MealLogEntity>;
      final waterLogs = results[1] as List<WaterLogEntity>;
      final sleep = results[2] as SleepLogEntity?;
      final mood = results[3] as MoodLogEntity?;
      final bodyPhotos = results[4] as List<BodyPhotoEntity>;

      // Calculate water summary
      final totalWater = waterLogs.fold(0, (sum, log) => sum + log.amountMl);
      final waterSummary = DailyWaterSummary(
        date: date,
        totalMl: totalWater,
        goalMl: 2500, // Default goal
        logs: waterLogs,
      );

      return Right(DailyLogEntity(
        clientId: clientId,
        date: date,
        meals: meals,
        waterSummary: waterSummary,
        sleep: sleep,
        mood: mood,
        bodyPhotos: bodyPhotos,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DailyLogEntity>>> getDailyLogs({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final logs = <DailyLogEntity>[];
      var currentDate = fromDate;

      while (currentDate.isBefore(toDate) ||
          currentDate.isAtSameMomentAs(toDate)) {
        final result = await getDailyLog(clientId: clientId, date: currentDate);
        result.fold(
          (_) {},
          (log) => logs.add(log),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Meal Operations ===============

  @override
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
  }) async {
    try {
      final meal = await _remoteDataSource.logMeal(
        clientId: clientId,
        date: date,
        mealType: mealType,
        photoUrl: photoUrl,
        description: description,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      return Right(meal);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<MealLogEntity>> updateMeal({
    required String mealId,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) async {
    try {
      final meal = await _remoteDataSource.updateMeal(
        mealId: mealId,
        photoUrl: photoUrl,
        description: description,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      return Right(meal);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMeal(String mealId) async {
    try {
      await _remoteDataSource.deleteMeal(mealId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MealLogEntity>>> getMeals({
    required String clientId,
    required DateTime date,
  }) async {
    try {
      final meals =
          await _remoteDataSource.getMeals(clientId: clientId, date: date);
      return Right(meals);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Water Operations ===============

  @override
  Future<Result<WaterLogEntity>> logWater({
    required String clientId,
    required DateTime date,
    required int amountMl,
  }) async {
    try {
      final log = await _remoteDataSource.logWater(
        clientId: clientId,
        date: date,
        amountMl: amountMl,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteWater(String waterLogId) async {
    try {
      await _remoteDataSource.deleteWater(waterLogId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<DailyWaterSummary>> getWaterSummary({
    required String clientId,
    required DateTime date,
    int goalMl = 2500,
  }) async {
    try {
      final logs =
          await _remoteDataSource.getWaterLogs(clientId: clientId, date: date);
      final total = logs.fold(0, (sum, log) => sum + log.amountMl);

      return Right(DailyWaterSummary(
        date: date,
        totalMl: total,
        goalMl: goalMl,
        logs: logs,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DailyWaterSummary>>> getWaterHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
    int goalMl = 2500,
  }) async {
    try {
      final logs = await _remoteDataSource.getWaterLogsRange(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Group by date
      final byDate = <DateTime, List<WaterLogEntity>>{};
      for (final log in logs) {
        final date = DateTime(
          log.logDate.year,
          log.logDate.month,
          log.logDate.day,
        );
        byDate.putIfAbsent(date, () => []).add(log);
      }

      final summaries = byDate.entries.map((entry) {
        final total = entry.value.fold(0, (sum, log) => sum + log.amountMl);
        return DailyWaterSummary(
          date: entry.key,
          totalMl: total,
          goalMl: goalMl,
          logs: entry.value,
        );
      }).toList();

      summaries.sort((a, b) => a.date.compareTo(b.date));
      return Right(summaries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Sleep Operations ===============

  @override
  Future<Result<SleepLogEntity>> logSleep({
    required String clientId,
    required DateTime date,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) async {
    try {
      final log = await _remoteDataSource.logSleep(
        clientId: clientId,
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: quality,
        notes: notes,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SleepLogEntity>> updateSleep({
    required String sleepId,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) async {
    try {
      final log = await _remoteDataSource.updateSleep(
        sleepId: sleepId,
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: quality,
        notes: notes,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SleepLogEntity?>> getSleep({
    required String clientId,
    required DateTime date,
  }) async {
    try {
      final log =
          await _remoteDataSource.getSleep(clientId: clientId, date: date);
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<SleepLogEntity>>> getSleepHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final logs = await _remoteDataSource.getSleepHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Mood Operations ===============

  @override
  Future<Result<MoodLogEntity>> logMood({
    required String clientId,
    required DateTime date,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) async {
    try {
      final log = await _remoteDataSource.logMood(
        clientId: clientId,
        date: date,
        mood: mood,
        energy: energy,
        stressLevel: stressLevel,
        notes: notes,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<MoodLogEntity>> updateMood({
    required String moodId,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) async {
    try {
      final log = await _remoteDataSource.updateMood(
        moodId: moodId,
        mood: mood,
        energy: energy,
        stressLevel: stressLevel,
        notes: notes,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<MoodLogEntity?>> getMood({
    required String clientId,
    required DateTime date,
  }) async {
    try {
      final log =
          await _remoteDataSource.getMood(clientId: clientId, date: date);
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MoodLogEntity>>> getMoodHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final logs = await _remoteDataSource.getMoodHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Body Photo Operations ===============

  @override
  Future<Result<BodyPhotoEntity>> logBodyPhoto({
    required String clientId,
    required DateTime date,
    required PhotoAngle angle,
    required String localFilePath,
    double? weight,
    String? notes,
  }) async {
    try {
      final photo = await _remoteDataSource.logBodyPhoto(
        clientId: clientId,
        date: date,
        angle: angle,
        localFilePath: localFilePath,
        weight: weight,
        notes: notes,
      );
      return Right(photo);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBodyPhoto(String photoId) async {
    try {
      await _remoteDataSource.deleteBodyPhoto(photoId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<BodyPhotoEntity>>> getBodyPhotos({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
    PhotoAngle? angle,
    int limit = 50,
  }) async {
    try {
      final photos = await _remoteDataSource.getBodyPhotos(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
        angle: angle,
        limit: limit,
      );
      return Right(photos);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Weight Operations ===============

  @override
  Future<Result<void>> logWeight({
    required String clientId,
    required DateTime date,
    required double weight,
  }) async {
    try {
      await _remoteDataSource.logWeight(
        clientId: clientId,
        date: date,
        weight: weight,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<({DateTime date, double weight})>>> getWeightHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final history = await _remoteDataSource.getWeightHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // =============== Activity Operations ===============

  @override
  Future<Result<void>> logActivity({
    required String clientId,
    required DateTime date,
    int? steps,
    int? activeMinutes,
  }) async {
    try {
      await _remoteDataSource.logActivity(
        clientId: clientId,
        date: date,
        steps: steps,
        activeMinutes: activeMinutes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<({DateTime date, int? steps, int? activeMinutes})>>>
      getActivityHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final history = await _remoteDataSource.getActivityHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
