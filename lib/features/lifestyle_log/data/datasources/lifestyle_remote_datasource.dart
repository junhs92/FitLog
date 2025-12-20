import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      'updated_at': DateTime.now().toIso8601String(),
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
      'logged_at': DateTime.now().toIso8601String(),
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
      'bedtime': bedtime?.toIso8601String(),
      'wake_time': wakeTime?.toIso8601String(),
      'quality': quality != null ? _sleepQualityToString(quality) : null,
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
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (bedtime != null) updates['bedtime'] = bedtime.toIso8601String();
    if (wakeTime != null) updates['wake_time'] = wakeTime.toIso8601String();
    if (quality != null) updates['quality'] = _sleepQualityToString(quality);
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
      'mood': mood != null ? _moodLevelToString(mood) : null,
      'energy': energy != null ? _energyLevelToString(energy) : null,
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
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (mood != null) updates['mood'] = _moodLevelToString(mood);
    if (energy != null) updates['energy'] = _energyLevelToString(energy);
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

  String _sleepQualityToString(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 'poor';
      case SleepQuality.fair:
        return 'fair';
      case SleepQuality.good:
        return 'good';
      case SleepQuality.excellent:
        return 'excellent';
    }
  }

  String _moodLevelToString(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return 'very_low';
      case MoodLevel.low:
        return 'low';
      case MoodLevel.neutral:
        return 'neutral';
      case MoodLevel.good:
        return 'good';
      case MoodLevel.excellent:
        return 'excellent';
    }
  }

  String _energyLevelToString(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.exhausted:
        return 'exhausted';
      case EnergyLevel.tired:
        return 'tired';
      case EnergyLevel.normal:
        return 'normal';
      case EnergyLevel.energetic:
        return 'energetic';
      case EnergyLevel.veryEnergetic:
        return 'very_energetic';
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
