import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/lifestyle_remote_datasource.dart';
import '../../data/repositories/lifestyle_repository_impl.dart';
import '../../domain/entities/daily_log_entity.dart';
import '../../domain/entities/exercise_stats_entity.dart';
import '../../domain/entities/exercise_volume_history_entity.dart';
import '../../domain/entities/lifestyle_summary_entity.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/water_log_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/mood_log_entity.dart';
import '../../domain/repositories/lifestyle_repository.dart';

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for lifestyle remote datasource
final lifestyleRemoteDataSourceProvider =
    Provider<LifestyleRemoteDataSource>((ref) {
  return LifestyleRemoteDataSource(ref.read(supabaseClientProvider));
});

/// Provider for lifestyle repository
final lifestyleRepositoryProvider = Provider<LifestyleRepository>((ref) {
  return LifestyleRepositoryImpl(ref.read(lifestyleRemoteDataSourceProvider));
});

/// State for daily lifestyle log
class DailyLogState {
  final DailyLogEntity? log;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  const DailyLogState({
    this.log,
    this.isLoading = false,
    this.error,
    required this.selectedDate,
  });

  DailyLogState copyWith({
    DailyLogEntity? log,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return DailyLogState(
      log: log ?? this.log,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

/// Notifier for daily lifestyle log
class DailyLogNotifier extends StateNotifier<DailyLogState> {
  final LifestyleRepository _repository;
  final String clientId;

  DailyLogNotifier(this._repository, this.clientId)
      : super(DailyLogState(selectedDate: DateTime.now())) {
    loadDailyLog(DateTime.now());
  }

  /// Load daily log for a specific date
  Future<void> loadDailyLog(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);

    final result = await _repository.getDailyLog(
      clientId: clientId,
      date: date,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (log) => state = state.copyWith(
        log: log,
        isLoading: false,
      ),
    );
  }

  /// Refresh current day's log
  Future<void> refresh() async {
    await loadDailyLog(state.selectedDate);
  }

  /// Log a meal
  Future<void> logMeal({
    required MealType mealType,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.logMeal(
      clientId: clientId,
      date: state.selectedDate,
      mealType: mealType,
      photoUrl: photoUrl,
      description: description,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (_) => refresh(),
    );
  }

  /// Log water intake
  Future<void> logWater(int amountMl) async {
    final result = await _repository.logWater(
      clientId: clientId,
      date: state.selectedDate,
      amountMl: amountMl,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => refresh(),
    );
  }

  /// Log sleep
  Future<void> logSleep({
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.logSleep(
      clientId: clientId,
      date: state.selectedDate,
      bedtime: bedtime,
      wakeTime: wakeTime,
      quality: quality,
      notes: notes,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (_) => refresh(),
    );
  }

  /// Update sleep quality
  Future<void> updateSleepQuality(SleepQuality quality) async {
    if (state.log?.sleep == null) return;

    final result = await _repository.updateSleep(
      sleepId: state.log!.sleep!.id,
      quality: quality,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => refresh(),
    );
  }

  /// Log mood
  Future<void> logMood({
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.logMood(
      clientId: clientId,
      date: state.selectedDate,
      mood: mood,
      energy: energy,
      stressLevel: stressLevel,
      notes: notes,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (_) => refresh(),
    );
  }

  /// Update mood
  Future<void> updateMood({
    MoodLevel? mood,
    EnergyLevel? energy,
  }) async {
    if (state.log?.mood == null) {
      // Create new mood log
      await logMood(mood: mood, energy: energy);
      return;
    }

    final result = await _repository.updateMood(
      moodId: state.log!.mood!.id,
      mood: mood,
      energy: energy,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => refresh(),
    );
  }

  /// Log weight
  Future<void> logWeight(double weight) async {
    final result = await _repository.logWeight(
      clientId: clientId,
      date: state.selectedDate,
      weight: weight,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => refresh(),
    );
  }

  /// Log activity
  Future<void> logActivity({int? steps, int? activeMinutes}) async {
    final result = await _repository.logActivity(
      clientId: clientId,
      date: state.selectedDate,
      steps: steps,
      activeMinutes: activeMinutes,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => refresh(),
    );
  }

  /// Navigate to previous day
  void previousDay() {
    loadDailyLog(state.selectedDate.subtract(const Duration(days: 1)));
  }

  /// Navigate to next day
  void nextDay() {
    final tomorrow = state.selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();
    if (tomorrow.isBefore(today) ||
        tomorrow.day == today.day &&
            tomorrow.month == today.month &&
            tomorrow.year == today.year) {
      loadDailyLog(tomorrow);
    }
  }

  /// Go to today
  void goToToday() {
    loadDailyLog(DateTime.now());
  }
}

/// Provider for daily log state
final dailyLogProvider =
    StateNotifierProvider.family<DailyLogNotifier, DailyLogState, String>(
  (ref, clientId) {
    return DailyLogNotifier(
      ref.read(lifestyleRepositoryProvider),
      clientId,
    );
  },
);

/// Provider for water history
final waterHistoryProvider = FutureProvider.family<List<DailyWaterSummary>,
    ({String clientId, DateTime fromDate, DateTime toDate})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getWaterHistory(
      clientId: params.clientId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
    return result.fold((_) => [], (history) => history);
  },
);

/// Provider for sleep history
final sleepHistoryProvider = FutureProvider.family<List<SleepLogEntity>,
    ({String clientId, DateTime fromDate, DateTime toDate})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getSleepHistory(
      clientId: params.clientId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
    return result.fold((_) => [], (history) => history);
  },
);

/// Provider for mood history
final moodHistoryProvider = FutureProvider.family<List<MoodLogEntity>,
    ({String clientId, DateTime fromDate, DateTime toDate})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getMoodHistory(
      clientId: params.clientId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
    return result.fold((_) => [], (history) => history);
  },
);

/// Provider for weight history
final weightHistoryProvider = FutureProvider.family<
    List<({DateTime date, double weight})>,
    ({String clientId, DateTime fromDate, DateTime toDate})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getWeightHistory(
      clientId: params.clientId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
    return result.fold((_) => [], (history) => history);
  },
);

/// Provider for 7-day lifestyle summary
/// Used in Flow 0 (Pre-Session) to show trainer the client's recent status
final clientLifestyleSummaryProvider =
    FutureProvider.family<LifestyleSummaryEntity?, String>(
  (ref, clientId) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.get7DayLifestyleSummary(clientId: clientId);
    return result.fold((_) => null, (summary) => summary);
  },
);

/// Combined 7-day lifestyle logs for detailed view
/// Returns all raw logs for sleep, mood, meals, water, and activity
class Client7DayLifestyleLogs {
  final String clientId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<SleepLogEntity> sleepLogs;
  final List<MoodLogEntity> moodLogs;
  final List<MealLogEntity> mealLogs;
  final List<DailyWaterSummary> waterLogs;
  final List<({DateTime date, int? steps, int? activeMinutes})> activityLogs;

  const Client7DayLifestyleLogs({
    required this.clientId,
    required this.fromDate,
    required this.toDate,
    required this.sleepLogs,
    required this.moodLogs,
    required this.mealLogs,
    required this.waterLogs,
    required this.activityLogs,
  });

  bool get hasData =>
      sleepLogs.isNotEmpty ||
      moodLogs.isNotEmpty ||
      mealLogs.isNotEmpty ||
      waterLogs.isNotEmpty ||
      activityLogs.isNotEmpty;
}

/// Provider for detailed 7-day lifestyle logs
/// Used in lifestyle detail screen to show all records
final client7DayLifestyleLogsProvider =
    FutureProvider.family<Client7DayLifestyleLogs, String>(
  (ref, clientId) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fromDate = today.subtract(const Duration(days: 6));
    final toDate = today;

    // Fetch daily logs which contain all data including meals
    final dailyLogsResult = await repository.getDailyLogs(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    );

    // Also fetch specific history for complete data
    final results = await Future.wait([
      repository.getSleepHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      ),
      repository.getMoodHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      ),
      repository.getWaterHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      ),
      repository.getActivityHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      ),
    ]);

    // Extract meals from daily logs
    final mealLogs = dailyLogsResult.fold(
      (_) => <MealLogEntity>[],
      (dailyLogs) => dailyLogs.expand((log) => log.meals).toList(),
    );

    return Client7DayLifestyleLogs(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
      sleepLogs: results[0].fold((_) => [], (data) => data as List<SleepLogEntity>),
      moodLogs: results[1].fold((_) => [], (data) => data as List<MoodLogEntity>),
      mealLogs: mealLogs,
      waterLogs: results[2].fold((_) => [], (data) => data as List<DailyWaterSummary>),
      activityLogs: results[3].fold(
        (_) => [],
        (data) => data as List<({DateTime date, int? steps, int? activeMinutes})>,
      ),
    );
  },
);

/// Provider for exercise statistics
/// Shows aggregated stats for each exercise the client has performed
final exerciseStatsProvider = FutureProvider.family<
    List<ExerciseStatsEntity>,
    ({String clientId, int? dayRange})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getExerciseStats(
      clientId: params.clientId,
      dayRange: params.dayRange,
    );
    return result.fold((_) => [], (stats) => stats);
  },
);

/// Provider for exercise volume history
/// Shows volume progression per session for charting
final exerciseVolumeHistoryProvider = FutureProvider.family<
    ExerciseVolumeHistoryEntity,
    ({String clientId, String exerciseId})>(
  (ref, params) async {
    final repository = ref.read(lifestyleRepositoryProvider);
    final result = await repository.getExerciseVolumeHistory(
      clientId: params.clientId,
      exerciseId: params.exerciseId,
    );
    return result.fold(
      (_) => ExerciseVolumeHistoryEntity(
        exerciseId: params.exerciseId,
        exerciseName: '',
        exerciseNameKo: '',
        sessions: const [],
      ),
      (history) => history,
    );
  },
);
