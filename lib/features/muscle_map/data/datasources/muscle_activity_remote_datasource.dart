import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/muscle_activity_entity.dart';
import '../../domain/entities/client_muscle_map_entity.dart';

/// Remote data source for muscle activity operations via Supabase
class MuscleActivityRemoteDataSource {
  final SupabaseClient _client;
  String? _cachedAccountId;

  MuscleActivityRemoteDataSource(this._client);

  String get _currentAuthUserId => _client.auth.currentUser!.id;

  Future<String> _getCurrentAccountId() async {
    if (_cachedAccountId != null) return _cachedAccountId!;

    final response = await _client
        .from('accounts')
        .select('id')
        .eq('user_id', _currentAuthUserId)
        .single();

    _cachedAccountId = response['id'] as String;
    return _cachedAccountId!;
  }

  /// Get aggregated muscle activity for a client over a date range
  /// [dayRange] - Number of days to include, null = all time
  Future<ClientMuscleMapEntity> getClientMuscleMap({
    required String clientId,
    int? dayRange,
  }) async {
    final now = DateTime.now();

    debugPrint('🔍 [MuscleActivityDS] Getting muscle map for client: $clientId, range: ${dayRange ?? "all time"} days');

    // Query completed sessions with exercises and set records
    // Note: trainer_id filter removed to match getExerciseStats behavior
    var query = _client
        .from('sessions')
        .select('''
          id,
          completed_at,
          session_exercises(
            id,
            exercises(
              id,
              muscle_group
            ),
            set_records(
              weight,
              reps
            )
          )
        ''')
        .eq('client_id', clientId)
        .eq('status', 'completed');

    // Apply date filter only if dayRange is specified
    if (dayRange != null) {
      final fromDate = now.subtract(Duration(days: dayRange));
      query = query
          .gte('completed_at', fromDate.toIso8601String())
          .lte('completed_at', now.toIso8601String());
    }

    final response = await query.order('completed_at', ascending: false);

    debugPrint('🔍 [MuscleActivityDS] Found ${(response as List).length} completed sessions');

    // Aggregate muscle activity data
    final muscleData = <MuscleGroup, _MuscleAggregation>{};

    // Initialize all muscle groups
    for (final group in MuscleGroup.values) {
      if (group != MuscleGroup.fullBody) {
        muscleData[group] = _MuscleAggregation();
      }
    }

    for (final session in response) {
      final completedAt = session['completed_at'] != null
          ? DateTime.parse(session['completed_at'] as String)
          : null;

      final sessionExercises = session['session_exercises'] as List? ?? [];

      for (final sessionExercise in sessionExercises) {
        final exerciseData = sessionExercise['exercises'];
        if (exerciseData == null) continue;

        final muscleGroupStr = exerciseData['muscle_group'] as String?;
        if (muscleGroupStr == null) continue;

        final muscleGroup = MuscleGroup.fromString(muscleGroupStr);
        if (muscleGroup == null || muscleGroup == MuscleGroup.fullBody) continue;

        final setRecords = sessionExercise['set_records'] as List? ?? [];

        // Calculate volume and sets for this exercise
        int exerciseVolume = 0;
        int exerciseSets = setRecords.length;

        for (final set in setRecords) {
          final weight = (set['weight'] as num?)?.toDouble() ?? 0;
          final reps = (set['reps'] as num?)?.toInt() ?? 0;
          exerciseVolume += (weight * reps).toInt();
        }

        // Update muscle aggregation
        final agg = muscleData[muscleGroup]!;
        agg.totalVolume += exerciseVolume;
        agg.totalSets += exerciseSets;
        agg.sessionIds.add(session['id'] as String);

        // Track last worked date
        if (completedAt != null) {
          if (agg.lastWorkedAt == null || completedAt.isAfter(agg.lastWorkedAt!)) {
            agg.lastWorkedAt = completedAt;
          }
        }
      }
    }

    // Handle fullBody - distribute to all main muscles
    if (muscleData.containsKey(MuscleGroup.fullBody)) {
      final fullBodyAgg = muscleData[MuscleGroup.fullBody]!;
      for (final group in MuscleGroup.fullBodyMuscles) {
        final agg = muscleData[group]!;
        agg.totalVolume += fullBodyAgg.totalVolume ~/ MuscleGroup.fullBodyMuscles.length;
        agg.totalSets += fullBodyAgg.totalSets ~/ MuscleGroup.fullBodyMuscles.length;
        agg.sessionIds.addAll(fullBodyAgg.sessionIds);
        if (fullBodyAgg.lastWorkedAt != null) {
          if (agg.lastWorkedAt == null || fullBodyAgg.lastWorkedAt!.isAfter(agg.lastWorkedAt!)) {
            agg.lastWorkedAt = fullBodyAgg.lastWorkedAt;
          }
        }
      }
    }

    // Calculate max volume for normalization
    final maxVolume = muscleData.values
        .map((a) => a.totalVolume)
        .fold(0, (a, b) => a > b ? a : b);

    // Convert to MuscleActivityEntity map
    final activities = <MuscleGroup, MuscleActivityEntity>{};

    for (final entry in muscleData.entries) {
      final group = entry.key;
      final agg = entry.value;

      // Calculate normalized intensity (0.0 - 1.0)
      double intensity = 0.0;
      if (maxVolume > 0 && agg.totalVolume > 0) {
        // Base intensity on volume ratio
        intensity = agg.totalVolume / maxVolume;

        // Boost intensity based on recency
        if (agg.lastWorkedAt != null) {
          final daysSince = now.difference(agg.lastWorkedAt!).inDays;
          if (daysSince <= 1) {
            intensity = (intensity + 0.3).clamp(0.0, 1.0);
          } else if (daysSince <= 2) {
            intensity = (intensity + 0.15).clamp(0.0, 1.0);
          }
        }
      }

      // Calculate days since worked
      int? daysSinceWorked;
      if (agg.lastWorkedAt != null) {
        daysSinceWorked = now.difference(agg.lastWorkedAt!).inDays;
      }

      activities[group] = MuscleActivityEntity(
        muscleGroup: group,
        intensity: intensity,
        totalVolume: agg.totalVolume,
        sessionCount: agg.sessionIds.length,
        totalSets: agg.totalSets,
        daysSinceWorked: daysSinceWorked,
        lastWorkedAt: agg.lastWorkedAt,
      );
    }

    debugPrint('🔍 [MuscleActivityDS] Aggregated ${activities.length} muscle groups');

    return ClientMuscleMapEntity(
      clientId: clientId,
      calculatedAt: now,
      dayRange: dayRange,
      activities: activities,
    );
  }

  /// Get muscle activity for a single session
  Future<SessionMuscleActivity> getSessionMuscleActivity({
    required String sessionId,
  }) async {
    debugPrint('🔍 [MuscleActivityDS] Getting session muscle activity: $sessionId');

    final response = await _client
        .from('sessions')
        .select('''
          id,
          completed_at,
          session_exercises(
            id,
            exercises(
              id,
              muscle_group
            ),
            set_records(
              weight,
              reps
            )
          )
        ''')
        .eq('id', sessionId)
        .single();

    final sessionDate = response['completed_at'] != null
        ? DateTime.parse(response['completed_at'] as String)
        : DateTime.now();

    final muscleVolumes = <MuscleGroup, int>{};
    final muscleSets = <MuscleGroup, int>{};

    final sessionExercises = response['session_exercises'] as List? ?? [];

    for (final sessionExercise in sessionExercises) {
      final exerciseData = sessionExercise['exercises'];
      if (exerciseData == null) continue;

      final muscleGroupStr = exerciseData['muscle_group'] as String?;
      if (muscleGroupStr == null) continue;

      final muscleGroup = MuscleGroup.fromString(muscleGroupStr);
      if (muscleGroup == null) continue;

      final setRecords = sessionExercise['set_records'] as List? ?? [];

      int exerciseVolume = 0;
      for (final set in setRecords) {
        final weight = (set['weight'] as num?)?.toDouble() ?? 0;
        final reps = (set['reps'] as num?)?.toInt() ?? 0;
        exerciseVolume += (weight * reps).toInt();
      }

      // Handle fullBody by distributing to main muscles
      if (muscleGroup == MuscleGroup.fullBody) {
        final volumePerMuscle = exerciseVolume ~/ MuscleGroup.fullBodyMuscles.length;
        final setsPerMuscle = setRecords.length ~/ MuscleGroup.fullBodyMuscles.length;
        for (final group in MuscleGroup.fullBodyMuscles) {
          muscleVolumes[group] = (muscleVolumes[group] ?? 0) + volumePerMuscle;
          muscleSets[group] = (muscleSets[group] ?? 0) + (setsPerMuscle > 0 ? setsPerMuscle : 1);
        }
      } else {
        muscleVolumes[muscleGroup] = (muscleVolumes[muscleGroup] ?? 0) + exerciseVolume;
        muscleSets[muscleGroup] = (muscleSets[muscleGroup] ?? 0) + setRecords.length;
      }
    }

    debugPrint('🔍 [MuscleActivityDS] Session worked ${muscleVolumes.length} muscle groups');

    return SessionMuscleActivity(
      sessionId: sessionId,
      sessionDate: sessionDate,
      muscleVolumes: muscleVolumes,
      muscleSets: muscleSets,
    );
  }

  /// Get historical muscle activity data
  Future<List<SessionMuscleActivity>> getMuscleHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    debugPrint('🔍 [MuscleActivityDS] Getting muscle history for client: $clientId');

    // Note: trainer_id filter removed to match getExerciseStats behavior
    final response = await _client
        .from('sessions')
        .select('''
          id,
          completed_at,
          session_exercises(
            id,
            exercises(
              id,
              muscle_group
            ),
            set_records(
              weight,
              reps
            )
          )
        ''')
        .eq('client_id', clientId)
        .eq('status', 'completed')
        .gte('completed_at', fromDate.toIso8601String())
        .lte('completed_at', toDate.toIso8601String())
        .order('completed_at', ascending: true);

    final history = <SessionMuscleActivity>[];

    for (final session in response as List) {
      final sessionDate = session['completed_at'] != null
          ? DateTime.parse(session['completed_at'] as String)
          : DateTime.now();

      final muscleVolumes = <MuscleGroup, int>{};
      final muscleSets = <MuscleGroup, int>{};

      final sessionExercises = session['session_exercises'] as List? ?? [];

      for (final sessionExercise in sessionExercises) {
        final exerciseData = sessionExercise['exercises'];
        if (exerciseData == null) continue;

        final muscleGroupStr = exerciseData['muscle_group'] as String?;
        if (muscleGroupStr == null) continue;

        final muscleGroup = MuscleGroup.fromString(muscleGroupStr);
        if (muscleGroup == null) continue;

        final setRecords = sessionExercise['set_records'] as List? ?? [];

        int exerciseVolume = 0;
        for (final set in setRecords) {
          final weight = (set['weight'] as num?)?.toDouble() ?? 0;
          final reps = (set['reps'] as num?)?.toInt() ?? 0;
          exerciseVolume += (weight * reps).toInt();
        }

        if (muscleGroup == MuscleGroup.fullBody) {
          final volumePerMuscle = exerciseVolume ~/ MuscleGroup.fullBodyMuscles.length;
          final setsPerMuscle = setRecords.length ~/ MuscleGroup.fullBodyMuscles.length;
          for (final group in MuscleGroup.fullBodyMuscles) {
            muscleVolumes[group] = (muscleVolumes[group] ?? 0) + volumePerMuscle;
            muscleSets[group] = (muscleSets[group] ?? 0) + (setsPerMuscle > 0 ? setsPerMuscle : 1);
          }
        } else {
          muscleVolumes[muscleGroup] = (muscleVolumes[muscleGroup] ?? 0) + exerciseVolume;
          muscleSets[muscleGroup] = (muscleSets[muscleGroup] ?? 0) + setRecords.length;
        }
      }

      if (muscleVolumes.isNotEmpty) {
        history.add(SessionMuscleActivity(
          sessionId: session['id'] as String,
          sessionDate: sessionDate,
          muscleVolumes: muscleVolumes,
          muscleSets: muscleSets,
        ));
      }
    }

    debugPrint('🔍 [MuscleActivityDS] Found ${history.length} sessions with muscle data');
    return history;
  }

  /// Get exercise IDs filtered by muscle group
  Future<List<String>> getExerciseIdsByMuscleGroup({
    required MuscleGroup muscleGroup,
  }) async {
    final accountId = await _getCurrentAccountId();

    final response = await _client
        .from('exercises')
        .select('id')
        .eq('muscle_group', muscleGroup.key)
        .or('is_custom.eq.false,trainer_id.eq.$accountId');

    return (response as List).map((e) => e['id'] as String).toList();
  }
}

/// Helper class for aggregating muscle data
class _MuscleAggregation {
  int totalVolume = 0;
  int totalSets = 0;
  Set<String> sessionIds = {};
  DateTime? lastWorkedAt;
}
