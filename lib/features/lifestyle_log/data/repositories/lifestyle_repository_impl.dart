import 'package:dartz/dartz.dart';
import '../../../../shared/models/result.dart';
import '../../domain/entities/daily_log_entity.dart';
import '../../domain/entities/exercise_stats_entity.dart';
import '../../domain/entities/exercise_volume_history_entity.dart';
import '../../domain/entities/lifestyle_summary_entity.dart';
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

  // =============== 7-Day Lifestyle Summary ===============

  @override
  Future<Result<LifestyleSummaryEntity>> get7DayLifestyleSummary({
    required String clientId,
  }) async {
    try {
      final data = await _remoteDataSource.get7DayLifestyleData(
        clientId: clientId,
      );

      final now = DateTime.now();
      final toDate = DateTime(now.year, now.month, now.day);
      final fromDate = toDate.subtract(const Duration(days: 6));

      // Aggregate sleep data
      final sleepSummary = _aggregateSleepData(data.sleepLogs);

      // Aggregate mood data
      final moodSummary = _aggregateMoodData(data.moodLogs);

      // Aggregate nutrition data (meals + water)
      final nutritionSummary = _aggregateNutritionData(
        data.mealLogs,
        data.waterLogs,
      );

      // Aggregate weight data
      final weightSummary = _aggregateWeightData(data.weightLogs);

      // Aggregate activity data
      final activitySummary = _aggregateActivityData(data.activityLogs);

      return Right(LifestyleSummaryEntity(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
        sleep: sleepSummary,
        mood: moodSummary,
        nutrition: nutritionSummary,
        weight: weightSummary,
        activity: activitySummary,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  SleepSummary _aggregateSleepData(List<SleepLogEntity> logs) {
    if (logs.isEmpty) {
      return const SleepSummary(
        daysLogged: 0,
        avgHours: null,
        avgQuality: null,
        avgBedtimeHour: null,
        avgWakeTimeHour: null,
        loggedDates: [],
      );
    }

    // Collect logged dates
    final loggedDates = logs.map((log) => log.logDate).toList();

    double totalHours = 0;
    int hoursCount = 0;
    double totalBedtimeHour = 0;
    int bedtimeCount = 0;
    double totalWakeTimeHour = 0;
    int wakeTimeCount = 0;
    final qualityCounts = <SleepQuality, int>{};

    for (final log in logs) {
      // Calculate sleep duration
      if (log.bedtime != null && log.wakeTime != null) {
        final duration = log.wakeTime!.difference(log.bedtime!);
        totalHours += duration.inMinutes / 60.0;
        hoursCount++;
      }

      // Track bedtime
      if (log.bedtime != null) {
        var hour = log.bedtime!.hour + log.bedtime!.minute / 60.0;
        // Normalize late night times (e.g., 11 PM = 23, but 1 AM = 25 for averaging)
        if (hour < 12) hour += 24;
        totalBedtimeHour += hour;
        bedtimeCount++;
      }

      // Track wake time
      if (log.wakeTime != null) {
        final hour = log.wakeTime!.hour + log.wakeTime!.minute / 60.0;
        totalWakeTimeHour += hour;
        wakeTimeCount++;
      }

      // Track quality
      if (log.quality != null) {
        qualityCounts[log.quality!] = (qualityCounts[log.quality!] ?? 0) + 1;
      }
    }

    // Calculate average quality (most common)
    SleepQuality? avgQuality;
    if (qualityCounts.isNotEmpty) {
      avgQuality = qualityCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Normalize bedtime hour back (if > 24, subtract 24)
    double? avgBedtime;
    if (bedtimeCount > 0) {
      avgBedtime = totalBedtimeHour / bedtimeCount;
      if (avgBedtime >= 24) avgBedtime -= 24;
    }

    return SleepSummary(
      daysLogged: logs.length,
      avgHours: hoursCount > 0 ? totalHours / hoursCount : null,
      avgQuality: avgQuality,
      avgBedtimeHour: avgBedtime,
      avgWakeTimeHour: wakeTimeCount > 0 ? totalWakeTimeHour / wakeTimeCount : null,
      loggedDates: loggedDates,
    );
  }

  MoodSummary _aggregateMoodData(List<MoodLogEntity> logs) {
    if (logs.isEmpty) {
      return const MoodSummary(
        daysLogged: 0,
        avgMood: null,
        avgEnergy: null,
        avgStressLevel: null,
        loggedDates: [],
      );
    }

    // Collect logged dates
    final loggedDates = logs.map((log) => log.logDate).toList();

    final moodCounts = <MoodLevel, int>{};
    final energyCounts = <EnergyLevel, int>{};
    double totalStress = 0;
    int stressCount = 0;

    for (final log in logs) {
      if (log.mood != null) {
        moodCounts[log.mood!] = (moodCounts[log.mood!] ?? 0) + 1;
      }
      if (log.energy != null) {
        energyCounts[log.energy!] = (energyCounts[log.energy!] ?? 0) + 1;
      }
      if (log.stressLevel != null) {
        totalStress += log.stressLevel!;
        stressCount++;
      }
    }

    MoodLevel? avgMood;
    if (moodCounts.isNotEmpty) {
      avgMood = moodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    EnergyLevel? avgEnergy;
    if (energyCounts.isNotEmpty) {
      avgEnergy = energyCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return MoodSummary(
      daysLogged: logs.length,
      avgMood: avgMood,
      avgEnergy: avgEnergy,
      avgStressLevel: stressCount > 0 ? totalStress / stressCount : null,
      loggedDates: loggedDates,
    );
  }

  NutritionSummary _aggregateNutritionData(
    List<MealLogEntity> mealLogs,
    List<WaterLogEntity> waterLogs,
  ) {
    // Group meals by date to count unique days
    final mealDays = <String>{};
    int totalCalories = 0;
    int caloriesCount = 0;
    double totalProtein = 0;
    int proteinCount = 0;
    double totalCarbs = 0;
    int carbsCount = 0;
    double totalFat = 0;
    int fatCount = 0;

    for (final meal in mealLogs) {
      mealDays.add(meal.logDate.toIso8601String().split('T')[0]);
      if (meal.calories != null) {
        totalCalories += meal.calories!;
        caloriesCount++;
      }
      if (meal.protein != null) {
        totalProtein += meal.protein!;
        proteinCount++;
      }
      if (meal.carbs != null) {
        totalCarbs += meal.carbs!;
        carbsCount++;
      }
      if (meal.fat != null) {
        totalFat += meal.fat!;
        fatCount++;
      }
    }

    // Calculate daily averages (sum per day, then average across days)
    // Group water by date
    final waterByDate = <String, int>{};
    for (final water in waterLogs) {
      final dateKey = water.logDate.toIso8601String().split('T')[0];
      waterByDate[dateKey] = (waterByDate[dateKey] ?? 0) + water.amountMl;
    }

    int? avgWater;
    if (waterByDate.isNotEmpty) {
      final totalWater = waterByDate.values.reduce((a, b) => a + b);
      avgWater = totalWater ~/ waterByDate.length;
    }

    // For calories/macros, calculate daily totals then average
    final caloriesByDate = <String, int>{};
    final proteinByDate = <String, double>{};
    final carbsByDate = <String, double>{};
    final fatByDate = <String, double>{};

    for (final meal in mealLogs) {
      final dateKey = meal.logDate.toIso8601String().split('T')[0];
      if (meal.calories != null) {
        caloriesByDate[dateKey] = (caloriesByDate[dateKey] ?? 0) + meal.calories!;
      }
      if (meal.protein != null) {
        proteinByDate[dateKey] = (proteinByDate[dateKey] ?? 0) + meal.protein!;
      }
      if (meal.carbs != null) {
        carbsByDate[dateKey] = (carbsByDate[dateKey] ?? 0) + meal.carbs!;
      }
      if (meal.fat != null) {
        fatByDate[dateKey] = (fatByDate[dateKey] ?? 0) + meal.fat!;
      }
    }

    // Collect unique logged dates
    final mealLoggedDates = mealLogs
        .map((log) => DateTime(log.logDate.year, log.logDate.month, log.logDate.day))
        .toSet()
        .toList();
    final waterLoggedDates = waterLogs
        .map((log) => DateTime(log.logDate.year, log.logDate.month, log.logDate.day))
        .toSet()
        .toList();

    return NutritionSummary(
      daysLogged: mealDays.length,
      avgCalories: caloriesByDate.isNotEmpty
          ? caloriesByDate.values.reduce((a, b) => a + b) ~/ caloriesByDate.length
          : null,
      avgProtein: proteinByDate.isNotEmpty
          ? proteinByDate.values.reduce((a, b) => a + b) / proteinByDate.length
          : null,
      avgCarbs: carbsByDate.isNotEmpty
          ? carbsByDate.values.reduce((a, b) => a + b) / carbsByDate.length
          : null,
      avgFat: fatByDate.isNotEmpty
          ? fatByDate.values.reduce((a, b) => a + b) / fatByDate.length
          : null,
      avgWaterMl: avgWater,
      mealLoggedDates: mealLoggedDates,
      waterLoggedDates: waterLoggedDates,
    );
  }

  WeightSummary _aggregateWeightData(
    List<({DateTime date, double weight})> logs,
  ) {
    if (logs.isEmpty) {
      return const WeightSummary(
        daysLogged: 0,
        currentWeight: null,
        startWeight: null,
        changeKg: null,
        loggedDates: [],
      );
    }

    // Collect logged dates
    final loggedDates = logs.map((log) => log.date).toList();

    // Logs are ordered by date ascending
    final startWeight = logs.first.weight;
    final currentWeight = logs.last.weight;
    final changeKg = currentWeight - startWeight;

    return WeightSummary(
      daysLogged: logs.length,
      currentWeight: currentWeight,
      startWeight: startWeight,
      changeKg: changeKg,
      loggedDates: loggedDates,
    );
  }

  ActivitySummary _aggregateActivityData(
    List<({DateTime date, int? steps, int? activeMinutes})> logs,
  ) {
    if (logs.isEmpty) {
      return const ActivitySummary(
        daysLogged: 0,
        avgSteps: null,
        avgActiveMinutes: null,
        totalSteps: null,
        totalActiveMinutes: null,
        loggedDates: [],
      );
    }

    // Collect logged dates
    final loggedDates = logs.map((log) => log.date).toList();

    int totalSteps = 0;
    int stepsCount = 0;
    int totalActiveMinutes = 0;
    int activeMinutesCount = 0;

    for (final log in logs) {
      if (log.steps != null) {
        totalSteps += log.steps!;
        stepsCount++;
      }
      if (log.activeMinutes != null) {
        totalActiveMinutes += log.activeMinutes!;
        activeMinutesCount++;
      }
    }

    return ActivitySummary(
      daysLogged: logs.length,
      avgSteps: stepsCount > 0 ? totalSteps ~/ stepsCount : null,
      avgActiveMinutes:
          activeMinutesCount > 0 ? totalActiveMinutes ~/ activeMinutesCount : null,
      totalSteps: stepsCount > 0 ? totalSteps : null,
      totalActiveMinutes: activeMinutesCount > 0 ? totalActiveMinutes : null,
      loggedDates: loggedDates,
    );
  }

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

  // =============== Exercise Stats Operations ===============

  @override
  Future<Result<List<ExerciseStatsEntity>>> getExerciseStats({
    required String clientId,
    int? dayRange,
  }) async {
    try {
      final stats = await _remoteDataSource.getExerciseStats(
        clientId: clientId,
        dayRange: dayRange,
      );
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ExerciseVolumeHistoryEntity>> getExerciseVolumeHistory({
    required String clientId,
    required String exerciseId,
    int limit = 50,
  }) async {
    try {
      final history = await _remoteDataSource.getExerciseVolumeHistory(
        clientId: clientId,
        exerciseId: exerciseId,
        limit: limit,
      );
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
