import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../../domain/entities/exercise_stats_entity.dart';
import '../../domain/entities/exercise_volume_history_entity.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/water_log_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/mood_log_entity.dart';
import '../../domain/entities/body_photo_entity.dart';
import '../models/meal_log_model.dart';
import '../models/water_log_model.dart';
import '../models/sleep_log_model.dart';
import '../models/mood_log_model.dart';
import '../models/body_photo_model.dart';

/// Remote data source for lifestyle logging operations
class LifestyleRemoteDataSource {
  final SupabaseClient _client;

  LifestyleRemoteDataSource(this._client);

  // =============== Meal Operations ===============

  Future<MealLogModel> logMeal({
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
    final data = await _client.from('meal_logs').insert({
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
      'meal_type': _mealTypeToString(mealType),
      'photo_url': photoUrl,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    }).select().single();

    return MealLogModel.fromJson(data);
  }

  Future<MealLogModel> updateMeal({
    required String mealId,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': nowLocalIso8601(),
    };
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (description != null) updates['description'] = description;
    if (calories != null) updates['calories'] = calories;
    if (protein != null) updates['protein'] = protein;
    if (carbs != null) updates['carbs'] = carbs;
    if (fat != null) updates['fat'] = fat;

    final data = await _client
        .from('meal_logs')
        .update(updates)
        .eq('id', mealId)
        .select()
        .single();

    return MealLogModel.fromJson(data);
  }

  Future<void> deleteMeal(String mealId) async {
    await _client.from('meal_logs').delete().eq('id', mealId);
  }

  Future<List<MealLogModel>> getMeals({
    required String clientId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _client
        .from('meal_logs')
        .select()
        .eq('client_id', clientId)
        .eq('log_date', dateStr)
        .order('created_at');

    return (data as List).map((json) => MealLogModel.fromJson(json)).toList();
  }

  // =============== Water Operations ===============

  Future<WaterLogModel> logWater({
    required String clientId,
    required DateTime date,
    required int amountMl,
  }) async {
    final data = await _client.from('water_logs').insert({
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
      'amount_ml': amountMl,
      'logged_at': nowLocalIso8601(),
    }).select().single();

    return WaterLogModel.fromJson(data);
  }

  Future<void> deleteWater(String waterLogId) async {
    await _client.from('water_logs').delete().eq('id', waterLogId);
  }

  Future<List<WaterLogModel>> getWaterLogs({
    required String clientId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _client
        .from('water_logs')
        .select()
        .eq('client_id', clientId)
        .eq('log_date', dateStr)
        .order('logged_at');

    return (data as List).map((json) => WaterLogModel.fromJson(json)).toList();
  }

  Future<List<WaterLogModel>> getWaterLogsRange({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    final data = await _client
        .from('water_logs')
        .select()
        .eq('client_id', clientId)
        .gte('log_date', fromStr)
        .lte('log_date', toStr)
        .order('log_date')
        .order('logged_at');

    return (data as List).map((json) => WaterLogModel.fromJson(json)).toList();
  }

  // =============== Sleep Operations ===============

  Future<SleepLogModel> logSleep({
    required String clientId,
    required DateTime date,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) async {
    final data = await _client.from('sleep_logs').insert({
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
      'bedtime': bedtime != null ? toLocalIso8601(bedtime) : null,
      'wake_time': wakeTime != null ? toLocalIso8601(wakeTime) : null,
      'quality': quality != null ? _sleepQualityToInt(quality) : null,
      'notes': notes,
    }).select().single();

    return SleepLogModel.fromJson(data);
  }

  Future<SleepLogModel> updateSleep({
    required String sleepId,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': nowLocalIso8601(),
    };
    if (bedtime != null) updates['bedtime'] = toLocalIso8601(bedtime);
    if (wakeTime != null) updates['wake_time'] = toLocalIso8601(wakeTime);
    if (quality != null) updates['quality'] = _sleepQualityToInt(quality);
    if (notes != null) updates['notes'] = notes;

    final data = await _client
        .from('sleep_logs')
        .update(updates)
        .eq('id', sleepId)
        .select()
        .single();

    return SleepLogModel.fromJson(data);
  }

  Future<SleepLogModel?> getSleep({
    required String clientId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _client
        .from('sleep_logs')
        .select()
        .eq('client_id', clientId)
        .eq('log_date', dateStr)
        .maybeSingle();

    if (data == null) return null;
    return SleepLogModel.fromJson(data);
  }

  Future<List<SleepLogModel>> getSleepHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    final data = await _client
        .from('sleep_logs')
        .select()
        .eq('client_id', clientId)
        .gte('log_date', fromStr)
        .lte('log_date', toStr)
        .order('log_date', ascending: false);

    return (data as List).map((json) => SleepLogModel.fromJson(json)).toList();
  }

  // =============== Mood Operations ===============

  Future<MoodLogModel> logMood({
    required String clientId,
    required DateTime date,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) async {
    final data = await _client.from('mood_logs').insert({
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
      'mood': mood != null ? _moodLevelToInt(mood) : null,
      'energy': energy != null ? _energyLevelToInt(energy) : null,
      'stress_level': stressLevel,
      'notes': notes,
    }).select().single();

    return MoodLogModel.fromJson(data);
  }

  Future<MoodLogModel> updateMood({
    required String moodId,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': nowLocalIso8601(),
    };
    if (mood != null) updates['mood'] = _moodLevelToInt(mood);
    if (energy != null) updates['energy'] = _energyLevelToInt(energy);
    if (stressLevel != null) updates['stress_level'] = stressLevel;
    if (notes != null) updates['notes'] = notes;

    final data = await _client
        .from('mood_logs')
        .update(updates)
        .eq('id', moodId)
        .select()
        .single();

    return MoodLogModel.fromJson(data);
  }

  Future<MoodLogModel?> getMood({
    required String clientId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _client
        .from('mood_logs')
        .select()
        .eq('client_id', clientId)
        .eq('log_date', dateStr)
        .maybeSingle();

    if (data == null) return null;
    return MoodLogModel.fromJson(data);
  }

  Future<List<MoodLogModel>> getMoodHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    final data = await _client
        .from('mood_logs')
        .select()
        .eq('client_id', clientId)
        .gte('log_date', fromStr)
        .lte('log_date', toStr)
        .order('log_date', ascending: false);

    return (data as List).map((json) => MoodLogModel.fromJson(json)).toList();
  }

  // =============== Body Photo Operations ===============

  Future<BodyPhotoModel> logBodyPhoto({
    required String clientId,
    required DateTime date,
    required PhotoAngle angle,
    required String localFilePath,
    double? weight,
    String? notes,
  }) async {
    // Upload photo to Supabase Storage
    final file = File(localFilePath);
    final fileName =
        '${clientId}_${date.toIso8601String().split('T')[0]}_${_photoAngleToString(angle)}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('body_photos').upload(
          fileName,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final photoUrl = _client.storage.from('body_photos').getPublicUrl(fileName);

    // Create database record
    final data = await _client.from('body_photos').insert({
      'client_id': clientId,
      'photo_date': date.toIso8601String().split('T')[0],
      'angle': _photoAngleToString(angle),
      'photo_url': photoUrl,
      'weight': weight,
      'notes': notes,
    }).select().single();

    return BodyPhotoModel.fromJson(data);
  }

  Future<void> deleteBodyPhoto(String photoId) async {
    // Get the photo URL to delete from storage
    final photo = await _client
        .from('body_photos')
        .select()
        .eq('id', photoId)
        .single();

    final photoUrl = photo['photo_url'] as String;
    final fileName = photoUrl.split('/').last;

    // Delete from storage
    await _client.storage.from('body_photos').remove([fileName]);

    // Delete from database
    await _client.from('body_photos').delete().eq('id', photoId);
  }

  Future<List<BodyPhotoModel>> getBodyPhotos({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
    PhotoAngle? angle,
    int limit = 50,
  }) async {
    var query = _client.from('body_photos').select().eq('client_id', clientId);

    if (fromDate != null) {
      query = query.gte('photo_date', fromDate.toIso8601String().split('T')[0]);
    }
    if (toDate != null) {
      query = query.lte('photo_date', toDate.toIso8601String().split('T')[0]);
    }
    if (angle != null) {
      query = query.eq('angle', _photoAngleToString(angle));
    }

    final data = await query.order('photo_date', ascending: false).limit(limit);

    return (data as List).map((json) => BodyPhotoModel.fromJson(json)).toList();
  }

  // =============== Weight Operations ===============

  Future<void> logWeight({
    required String clientId,
    required DateTime date,
    required double weight,
  }) async {
    // Upsert weight log (one per day)
    await _client.from('weight_logs').upsert({
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
      'weight': weight,
    }, onConflict: 'client_id,log_date');
  }

  Future<List<({DateTime date, double weight})>> getWeightHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    final data = await _client
        .from('weight_logs')
        .select()
        .eq('client_id', clientId)
        .gte('log_date', fromStr)
        .lte('log_date', toStr)
        .order('log_date');

    return (data as List).map((json) {
      return (
        date: DateTime.parse(json['log_date'] as String),
        weight: (json['weight'] as num).toDouble(),
      );
    }).toList();
  }

  // =============== Activity Operations ===============

  Future<void> logActivity({
    required String clientId,
    required DateTime date,
    int? steps,
    int? activeMinutes,
  }) async {
    // Upsert activity log (one per day)
    final updates = <String, dynamic>{
      'client_id': clientId,
      'log_date': date.toIso8601String().split('T')[0],
    };
    if (steps != null) updates['steps'] = steps;
    if (activeMinutes != null) updates['active_minutes'] = activeMinutes;

    await _client
        .from('activity_logs')
        .upsert(updates, onConflict: 'client_id,log_date');
  }

  Future<List<({DateTime date, int? steps, int? activeMinutes})>>
      getActivityHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    final data = await _client
        .from('activity_logs')
        .select()
        .eq('client_id', clientId)
        .gte('log_date', fromStr)
        .lte('log_date', toStr)
        .order('log_date');

    return (data as List).map((json) {
      return (
        date: DateTime.parse(json['log_date'] as String),
        steps: json['steps'] as int?,
        activeMinutes: json['active_minutes'] as int?,
      );
    }).toList();
  }

  // =============== 7-Day Lifestyle Summary ===============

  /// Fetches aggregated lifestyle data for the past 7 days
  /// Used in Flow 0 (Pre-Session) to show trainer the client's recent status
  Future<
      ({
        List<SleepLogModel> sleepLogs,
        List<MoodLogModel> moodLogs,
        List<MealLogModel> mealLogs,
        List<WaterLogModel> waterLogs,
        List<({DateTime date, double weight})> weightLogs,
        List<({DateTime date, int? steps, int? activeMinutes})> activityLogs,
      })> get7DayLifestyleData({
    required String clientId,
  }) async {
    final now = DateTime.now();
    final toDate = DateTime(now.year, now.month, now.day);
    final fromDate = toDate.subtract(const Duration(days: 6)); // 7 days including today

    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    // Fetch all data in parallel
    final results = await Future.wait([
      // Sleep logs
      _client
          .from('sleep_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date', ascending: false),
      // Mood logs
      _client
          .from('mood_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date', ascending: false),
      // Meal logs
      _client
          .from('meal_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date', ascending: false),
      // Water logs
      _client
          .from('water_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date', ascending: false),
      // Weight logs
      _client
          .from('weight_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date'),
      // Activity logs
      _client
          .from('activity_logs')
          .select()
          .eq('client_id', clientId)
          .gte('log_date', fromStr)
          .lte('log_date', toStr)
          .order('log_date'),
    ]);

    return (
      sleepLogs: (results[0] as List)
          .map((json) => SleepLogModel.fromJson(json))
          .toList(),
      moodLogs: (results[1] as List)
          .map((json) => MoodLogModel.fromJson(json))
          .toList(),
      mealLogs: (results[2] as List)
          .map((json) => MealLogModel.fromJson(json))
          .toList(),
      waterLogs: (results[3] as List)
          .map((json) => WaterLogModel.fromJson(json))
          .toList(),
      weightLogs: (results[4] as List).map((json) {
        return (
          date: DateTime.parse(json['log_date'] as String),
          weight: (json['weight'] as num).toDouble(),
        );
      }).toList(),
      activityLogs: (results[5] as List).map((json) {
        return (
          date: DateTime.parse(json['log_date'] as String),
          steps: json['steps'] as int?,
          activeMinutes: json['active_minutes'] as int?,
        );
      }).toList(),
    );
  }

  // =============== Exercise Volume History Operations ===============

  /// Fetches volume history for a specific exercise across sessions
  /// Returns sessions ordered by date ascending (for charting)
  Future<ExerciseVolumeHistoryEntity> getExerciseVolumeHistory({
    required String clientId,
    required String exerciseId,
    int limit = 50,
  }) async {
    // Query set_records for this client with completed sessions
    // Filter by exerciseId in Dart since nested Supabase filters can be unreliable
    final data = await _client.from('set_records').select('''
      id,
      weight,
      reps,
      tags,
      comments,
      completed_at,
      session_exercises!inner(
        id,
        exercise_id,
        exercises!inner(id, name, name_ko),
        sessions!inner(id, client_id, status, completed_at)
      )
    ''')
        .eq('session_exercises.sessions.client_id', clientId)
        .eq('session_exercises.sessions.status', 'completed');

    // Filter by exerciseId in Dart
    final filteredData = (data as List).where((record) {
      final se = record['session_exercises'] as Map<String, dynamic>;
      return se['exercise_id'] == exerciseId;
    }).toList();

    if (filteredData.isEmpty) {
      // Return empty history - we need exercise info from exercises table
      final exerciseData = await _client
          .from('exercises')
          .select('id, name, name_ko')
          .eq('id', exerciseId)
          .maybeSingle();

      return ExerciseVolumeHistoryEntity(
        exerciseId: exerciseId,
        exerciseName: exerciseData?['name'] as String? ?? '',
        exerciseNameKo: exerciseData?['name_ko'] as String? ?? '',
        sessions: const [],
      );
    }

    // Get exercise info from first record
    final firstRecord = filteredData[0];
    final sessionExercise = firstRecord['session_exercises'] as Map<String, dynamic>;
    final exercise = sessionExercise['exercises'] as Map<String, dynamic>;

    // Group records by session
    final sessionMap = <String, _SessionVolumeAccumulator>{};

    for (final record in filteredData) {
      final se = record['session_exercises'] as Map<String, dynamic>;
      final session = se['sessions'] as Map<String, dynamic>;
      final sessionId = session['id'] as String;
      final completedAt = session['completed_at'] != null
          ? DateTime.parse(session['completed_at'] as String)
          : DateTime.now();

      final weight = (record['weight'] as num?)?.toDouble() ?? 0;
      final reps = (record['reps'] as num?)?.toInt() ?? 0;
      final tags = (record['tags'] as List?)?.cast<String>() ?? [];
      final comments = (record['comments'] as List?)?.cast<String>() ?? [];
      final setCompletedAt = record['completed_at'] != null
          ? DateTime.parse(record['completed_at'] as String)
          : null;

      // Calculate volume for this set
      final setVolume = weight * reps;

      // Get or create accumulator
      final acc = sessionMap.putIfAbsent(
        sessionId,
        () => _SessionVolumeAccumulator(
          sessionId: sessionId,
          sessionDate: completedAt,
        ),
      );

      // Update accumulator
      acc.totalVolume += setVolume;
      acc.setCount++;

      // Collect comments with timestamp
      for (final comment in comments) {
        acc.comments.add(comment);
        if (setCompletedAt != null) {
          final existing = acc.commentTimestamps[comment];
          if (existing == null || setCompletedAt.isAfter(existing)) {
            acc.commentTimestamps[comment] = setCompletedAt;
          }
        }
      }

      // Check for PR tags
      if (tags.contains('weight_pr')) {
        acc.hasPR = true;
        acc.prType = 'weight';
      } else if (tags.contains('volume_pr')) {
        acc.hasPR = true;
        acc.prType ??= 'volume';
      } else if (tags.contains('reps_pr')) {
        acc.hasPR = true;
        acc.prType ??= 'reps';
      }
    }

    // Convert to entities, sorted by date, and limit
    final sessions = sessionMap.values
        .map((acc) => acc.toEntity())
        .toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    // Apply limit from most recent
    final limitedSessions = sessions.length > limit
        ? sessions.sublist(sessions.length - limit)
        : sessions;

    // Aggregate comments across all sessions
    final commentAggregator = <String, _CommentAggregator>{};
    for (final acc in sessionMap.values) {
      for (final comment in acc.comments) {
        // Parse comment key and detail (e.g., 'pain_reported:knee area')
        final parts = comment.split(':');
        final key = parts[0];
        final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;
        final aggregatorKey = detail != null ? '$key:$detail' : key;

        final aggregator = commentAggregator.putIfAbsent(
          aggregatorKey,
          () => _CommentAggregator(commentKey: key, detail: detail),
        );
        aggregator.count++;
        final timestamp = acc.commentTimestamps[comment];
        if (timestamp != null &&
            (aggregator.lastUsedAt == null ||
                timestamp.isAfter(aggregator.lastUsedAt!))) {
          aggregator.lastUsedAt = timestamp;
        }
      }
    }

    // Sort by frequency descending
    final commentSummary = commentAggregator.values
        .map((agg) => ExerciseCommentSummaryEntity(
              commentKey: agg.commentKey,
              detail: agg.detail,
              count: agg.count,
              lastUsedAt: agg.lastUsedAt,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return ExerciseVolumeHistoryEntity(
      exerciseId: exerciseId,
      exerciseName: exercise['name'] as String? ?? '',
      exerciseNameKo: exercise['name_ko'] as String? ?? '',
      sessions: limitedSessions,
      commentSummary: commentSummary,
    );
  }

  // =============== Exercise Stats Operations ===============

  /// Fetches aggregated exercise statistics from completed sessions
  /// Groups by exercise and calculates max weight, 1RM, total sets, etc.
  Future<List<ExerciseStatsEntity>> getExerciseStats({
    required String clientId,
    int? dayRange,
  }) async {
    // Build query to fetch set_records with related exercise and session data
    var query = _client.from('set_records').select('''
      id,
      weight,
      reps,
      completed_at,
      session_exercises!inner(
        id,
        exercise_id,
        exercises!inner(id, name, name_ko, muscle_group),
        sessions!inner(id, client_id, status, completed_at)
      )
    ''').eq('session_exercises.sessions.client_id', clientId).eq(
        'session_exercises.sessions.status', 'completed');

    // Apply date filter if dayRange specified
    if (dayRange != null) {
      final fromDate = DateTime.now().subtract(Duration(days: dayRange - 1));
      query = query.gte('session_exercises.sessions.completed_at',
          fromDate.toIso8601String());
    }

    final data = await query;

    // Aggregate in Dart: group by exercise, calculate stats
    final statsMap = <String, _ExerciseStatsAccumulator>{};

    for (final record in data as List) {
      final sessionExercise =
          record['session_exercises'] as Map<String, dynamic>;
      final exercise = sessionExercise['exercises'] as Map<String, dynamic>;
      final session = sessionExercise['sessions'] as Map<String, dynamic>;

      final exerciseId = exercise['id'] as String;
      final sessionExerciseId = sessionExercise['id'] as String;
      final weight = (record['weight'] as num?)?.toDouble();
      final reps = (record['reps'] as num?)?.toInt();
      final sessionCompletedAt = session['completed_at'] != null
          ? DateTime.parse(session['completed_at'] as String)
          : null;

      // Get or create accumulator for this exercise
      final acc = statsMap.putIfAbsent(
        exerciseId,
        () => _ExerciseStatsAccumulator(
          exerciseId: exerciseId,
          exerciseName: exercise['name'] as String? ?? '',
          exerciseNameKo: exercise['name_ko'] as String? ?? '',
          muscleGroup: exercise['muscle_group'] as String? ?? 'other',
        ),
      );

      // Update accumulator with this set record
      acc.sessionExerciseIds.add(sessionExerciseId);
      acc.totalSets++;

      if (weight != null && weight > 0) {
        if (acc.maxWeight == null || weight > acc.maxWeight!) {
          acc.maxWeight = weight;
        }

        if (reps != null && reps > 0) {
          final volume = weight * reps;
          if (acc.bestVolume == null || volume > acc.bestVolume!) {
            acc.bestVolume = volume;
          }

          // Brzycki formula for 1RM estimate: weight * (1 + reps/30)
          final estimated1RM = weight * (1 + reps / 30);
          if (acc.estimated1RM == null || estimated1RM > acc.estimated1RM!) {
            acc.estimated1RM = estimated1RM;
          }
        }
      }

      if (sessionCompletedAt != null) {
        if (acc.lastPerformedAt == null ||
            sessionCompletedAt.isAfter(acc.lastPerformedAt!)) {
          acc.lastPerformedAt = sessionCompletedAt;
        }
      }
    }

    // Convert accumulators to entities and sort by last performed
    final stats = statsMap.values.map((acc) => acc.toEntity()).toList();
    stats.sort((a, b) {
      if (a.lastPerformedAt == null && b.lastPerformedAt == null) return 0;
      if (a.lastPerformedAt == null) return 1;
      if (b.lastPerformedAt == null) return -1;
      return b.lastPerformedAt!.compareTo(a.lastPerformedAt!);
    });

    return stats;
  }

  // =============== Helper Methods ===============

  String _mealTypeToString(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.snack:
        return 'snack';
    }
  }

  /// Convert SleepQuality enum to integer (1-4)
  int _sleepQualityToInt(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 1;
      case SleepQuality.fair:
        return 2;
      case SleepQuality.good:
        return 3;
      case SleepQuality.excellent:
        return 4;
    }
  }

  /// Convert MoodLevel enum to integer (1-5)
  int _moodLevelToInt(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return 1;
      case MoodLevel.low:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.excellent:
        return 5;
    }
  }

  /// Convert EnergyLevel enum to integer (1-5)
  int _energyLevelToInt(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.exhausted:
        return 1;
      case EnergyLevel.tired:
        return 2;
      case EnergyLevel.normal:
        return 3;
      case EnergyLevel.energetic:
        return 4;
      case EnergyLevel.veryEnergetic:
        return 5;
    }
  }

  String _photoAngleToString(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'front';
      case PhotoAngle.side:
        return 'side';
      case PhotoAngle.back:
        return 'back';
    }
  }
}

/// Helper class to accumulate session volume data
class _SessionVolumeAccumulator {
  final String sessionId;
  final DateTime sessionDate;
  double totalVolume = 0;
  int setCount = 0;
  bool hasPR = false;
  String? prType;
  List<String> comments = [];
  Map<String, DateTime> commentTimestamps = {};

  _SessionVolumeAccumulator({
    required this.sessionId,
    required this.sessionDate,
  });

  ExerciseSessionVolumeEntity toEntity() {
    // Get unique comments for this session
    final uniqueComments = comments.toSet().toList();

    return ExerciseSessionVolumeEntity(
      sessionId: sessionId,
      sessionDate: sessionDate,
      totalVolume: totalVolume,
      setCount: setCount,
      hasPR: hasPR,
      prType: prType,
      comments: uniqueComments,
      completedAt: sessionDate,
    );
  }
}

/// Helper class to aggregate comment frequency
class _CommentAggregator {
  final String commentKey;
  final String? detail;
  int count = 0;
  DateTime? lastUsedAt;

  _CommentAggregator({
    required this.commentKey,
    this.detail,
  });
}

/// Helper class to accumulate exercise statistics during aggregation
class _ExerciseStatsAccumulator {
  final String exerciseId;
  final String exerciseName;
  final String exerciseNameKo;
  final String muscleGroup;

  final Set<String> sessionExerciseIds = {};
  int totalSets = 0;
  double? maxWeight;
  double? bestVolume;
  double? estimated1RM;
  DateTime? lastPerformedAt;

  _ExerciseStatsAccumulator({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseNameKo,
    required this.muscleGroup,
  });

  int get timesPerformed => sessionExerciseIds.length;

  ExerciseStatsEntity toEntity() {
    return ExerciseStatsEntity(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseNameKo: exerciseNameKo,
      muscleGroup: muscleGroup,
      timesPerformed: timesPerformed,
      totalSets: totalSets,
      maxWeight: maxWeight,
      bestVolume: bestVolume,
      estimated1RM: estimated1RM,
      lastPerformedAt: lastPerformedAt,
    );
  }
}
