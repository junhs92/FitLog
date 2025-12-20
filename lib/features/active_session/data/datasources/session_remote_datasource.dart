import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../models/session_exercise_model.dart';
import '../models/session_model.dart';
import '../../domain/entities/session_entity.dart';

/// Remote data source for session operations via Supabase
class SessionRemoteDataSource {
  final SupabaseClient _client;
  String? _cachedAccountId;

  SessionRemoteDataSource(this._client);

  String get _currentAuthUserId => _client.auth.currentUser!.id;

  /// Get the current user's account ID (not auth user_id)
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

  /// Get sessions with optional filters
  Future<List<SessionModel>> getSessions({
    String? clientId,
    SessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final accountId = await _getCurrentAccountId();

    // Build filter query first, then add ordering
    // Note: sets are stored as JSONB in session_exercises, not a separate table
    // Include program_exercises join to get target values from AI recommendations
    var filterQuery = _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            program_exercises(target_sets, target_reps, target_weight, target_rpe, rest_seconds)
          )
        ''')
        .eq('trainer_id', accountId);

    if (clientId != null) {
      filterQuery = filterQuery.eq('client_id', clientId);
    }

    if (status != null) {
      filterQuery = filterQuery.eq('status', _statusToString(status));
    }

    if (fromDate != null) {
      filterQuery = filterQuery.gte('created_at', fromDate.toIso8601String());
    }

    if (toDate != null) {
      filterQuery = filterQuery.lte('created_at', toDate.toIso8601String());
    }

    final response = await filterQuery.order('created_at', ascending: false);
    return (response as List)
        .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific session by ID
  Future<SessionModel> getSessionById(String sessionId) async {
    // Note: sets are stored as JSONB in session_exercises, not a separate table
    // Include program_exercises join to get target values from AI recommendations
    final response = await _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            program_exercises(target_sets, target_reps, target_weight, target_rpe, rest_seconds)
          )
        ''')
        .eq('id', sessionId)
        .single();

    return SessionModel.fromJson(response);
  }

  /// Get active session for a client
  Future<SessionModel?> getActiveSession(String clientId) async {
    final accountId = await _getCurrentAccountId();

    // Note: sets are stored as JSONB in session_exercises, not a separate table
    // Include program_exercises join to get target values from AI recommendations
    final response = await _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            program_exercises(target_sets, target_reps, target_weight, target_rpe, rest_seconds)
          )
        ''')
        .eq('trainer_id', accountId)
        .eq('client_id', clientId)
        .eq('status', 'active')
        .maybeSingle();

    if (response == null) return null;
    return SessionModel.fromJson(response);
  }

  /// Start a new session
  /// If programId and workoutDayId are provided, the session will be linked to the program
  /// and exercises will be auto-populated from the workout day
  Future<SessionModel> startSession({
    required String clientId,
    String? sessionType,
    String? notes,
    String? programId,
    String? workoutDayId,
  }) async {
    final accountId = await _getCurrentAccountId();
    final now = DateTime.now();

    // Create session with optional program link
    final sessionData = {
      'trainer_id': accountId,
      'client_id': clientId,
      'status': 'active',
      'session_type': sessionType ?? 'training',
      'notes': notes,
      'scheduled_at': now.toIso8601String(),
      'started_at': now.toIso8601String(),
    };

    // Add program reference if provided
    if (programId != null) {
      sessionData['program_id'] = programId;
    }
    if (workoutDayId != null) {
      sessionData['workout_day_id'] = workoutDayId;
    }

    final response = await _client.from('sessions').insert(sessionData).select('''
      *,
      accounts!sessions_client_id_fkey(full_name)
    ''').single();

    final session = SessionModel.fromJson(response);

    // If linked to a program, auto-populate exercises from the workout day
    if (workoutDayId != null) {
      await _populateExercisesFromProgram(session.id, workoutDayId);
      // Reload session with exercises
      return getSessionById(session.id);
    }

    return session;
  }

  /// Populate session exercises from a program workout day
  Future<void> _populateExercisesFromProgram(String sessionId, String workoutDayId) async {
    // Fetch exercises from the program workout day
    final programExercises = await _client
        .from('program_exercises')
        .select('id, exercise_id, order_index, notes')
        .eq('workout_day_id', workoutDayId)
        .order('order_index');

    // Add each exercise to the session
    for (final pe in (programExercises as List)) {
      await _client.from('session_exercises').insert({
        'session_id': sessionId,
        'exercise_id': pe['exercise_id'],
        'program_exercise_id': pe['id'],  // Link to original program exercise
        'order_index': pe['order_index'],
        'notes': pe['notes'],
        'started_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Complete a session
  Future<SessionModel> completeSession({
    required String sessionId,
    int? overallRating,
    String? trainerFeedback,
  }) async {
    final now = DateTime.now();

    // Get session to calculate duration
    final currentSession = await getSessionById(sessionId);
    final duration = currentSession.startedAt != null
        ? now.difference(currentSession.startedAt!)
        : null;

    // Note: sets are stored as JSONB in session_exercises, not a separate table
    // Include program_exercises join to get target values from AI recommendations
    final response = await _client
        .from('sessions')
        .update({
          'status': 'completed',
          'completed_at': now.toIso8601String(),
          'overall_rating': overallRating,
          'trainer_feedback': trainerFeedback,
          'duration_seconds': duration?.inSeconds,
        })
        .eq('id', sessionId)
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            program_exercises(target_sets, target_reps, target_weight, target_rpe, rest_seconds)
          )
        ''')
        .single();

    return SessionModel.fromJson(response);
  }

  /// Cancel a session
  Future<void> cancelSession(String sessionId) async {
    await _client
        .from('sessions')
        .update({'status': 'cancelled'})
        .eq('id', sessionId);
  }

  /// Add exercise to session
  Future<SessionExerciseModel> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
    int? order,
  }) async {
    // Get current exercise count for order
    final existingExercises = await _client
        .from('session_exercises')
        .select('order_index')
        .eq('session_id', sessionId)
        .order('order_index', ascending: false)
        .limit(1);

    final nextOrder = order ??
        ((existingExercises as List).isNotEmpty
            ? (existingExercises.first['order_index'] as int) + 1
            : 0);

    final response = await _client.from('session_exercises').insert({
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'order_index': nextOrder,
      'started_at': DateTime.now().toIso8601String(),
    }).select('''
      *,
      exercises(*)
    ''').single();

    return SessionExerciseModel.fromJson(response);
  }

  /// Remove exercise from session
  Future<void> removeExerciseFromSession(String sessionExerciseId) async {
    await _client
        .from('session_exercises')
        .delete()
        .eq('id', sessionExerciseId);
  }

  /// Reorder exercises
  Future<void> reorderExercises({
    required String sessionId,
    required List<String> exerciseIds,
  }) async {
    for (int i = 0; i < exerciseIds.length; i++) {
      await _client
          .from('session_exercises')
          .update({'order_index': i})
          .eq('id', exerciseIds[i]);
    }
  }

  /// Log a set (updates JSONB sets column in session_exercises)
  Future<ExerciseSetModel> logSet({
    required String sessionExerciseId,
    required int setNumber,
    double? weight,
    int? reps,
    double? rpe,
    int? durationSeconds,
    double? distance,
    List<String> tags = const [],
    String? notes,
  }) async {
    debugPrint('🟡 DS.logSet: sessionExerciseId=$sessionExerciseId');
    debugPrint('🟡 DS.logSet: weight=$weight, reps=$reps, setNumber=$setNumber');

    // Fetch current sets from session_exercises
    debugPrint('🟡 DS.logSet: Fetching current sets...');
    final currentData = await _client
        .from('session_exercises')
        .select('sets')
        .eq('id', sessionExerciseId)
        .single();
    debugPrint('🟡 DS.logSet: Current data fetched: ${currentData['sets']}');

    final currentSets = (currentData['sets'] as List<dynamic>?) ?? [];
    debugPrint('🟡 DS.logSet: Current sets count: ${currentSets.length}');

    // Create new set data
    final newSet = {
      'id': 'set_${DateTime.now().millisecondsSinceEpoch}',
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'duration_seconds': durationSeconds,
      'distance': distance,
      'tags': tags,
      'notes': notes,
      'completed_at': DateTime.now().toIso8601String(),
    };
    debugPrint('🟡 DS.logSet: New set created: $newSet');

    // Append new set to existing sets
    final updatedSets = [...currentSets, newSet];
    debugPrint('🟡 DS.logSet: Updating with ${updatedSets.length} sets...');

    // Update the session_exercises row
    await _client
        .from('session_exercises')
        .update({'sets': updatedSets})
        .eq('id', sessionExerciseId);
    debugPrint('🟡 DS.logSet: Update complete!');

    return ExerciseSetModel.fromJson(newSet);
  }

  /// Update a set (updates set within JSONB array)
  Future<ExerciseSetModel> updateSet({
    required String setId,
    required String sessionExerciseId,
    double? weight,
    int? reps,
    double? rpe,
    int? durationSeconds,
    double? distance,
    List<String>? tags,
    String? notes,
  }) async {
    // Fetch current sets
    final currentData = await _client
        .from('session_exercises')
        .select('sets')
        .eq('id', sessionExerciseId)
        .single();

    final rawSets = currentData['sets'] as List<dynamic>? ?? <dynamic>[];
    final currentSets = rawSets
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Find and update the set
    Map<String, dynamic>? updatedSet;
    for (int i = 0; i < currentSets.length; i++) {
      if (currentSets[i]['id'] == setId) {
        if (weight != null) currentSets[i]['weight'] = weight;
        if (reps != null) currentSets[i]['reps'] = reps;
        if (rpe != null) currentSets[i]['rpe'] = rpe;
        if (durationSeconds != null) {
          currentSets[i]['duration_seconds'] = durationSeconds;
        }
        if (distance != null) currentSets[i]['distance'] = distance;
        if (tags != null) currentSets[i]['tags'] = tags;
        if (notes != null) currentSets[i]['notes'] = notes;
        updatedSet = currentSets[i];
        break;
      }
    }

    if (updatedSet == null) {
      throw Exception('Set not found: $setId');
    }

    // Update the session_exercises row
    await _client
        .from('session_exercises')
        .update({'sets': currentSets})
        .eq('id', sessionExerciseId);

    return ExerciseSetModel.fromJson(updatedSet);
  }

  /// Delete a set (removes set from JSONB array)
  Future<void> deleteSet({
    required String setId,
    required String sessionExerciseId,
  }) async {
    // Fetch current sets
    final currentData = await _client
        .from('session_exercises')
        .select('sets')
        .eq('id', sessionExerciseId)
        .single();

    final rawSets = currentData['sets'] as List<dynamic>? ?? <dynamic>[];
    final currentSets = rawSets
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Remove the set
    currentSets.removeWhere((set) => set['id'] == setId);

    // Update the session_exercises row
    await _client
        .from('session_exercises')
        .update({'sets': currentSets})
        .eq('id', sessionExerciseId);
  }

  /// Complete an exercise
  Future<void> completeExercise(String sessionExerciseId) async {
    await _client.from('session_exercises').update({
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionExerciseId);
  }

  /// Update session notes
  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    await _client
        .from('sessions')
        .update({'notes': notes})
        .eq('id', sessionId);
  }

  /// Get exercises from library
  Future<List<ExerciseModel>> getExercises({
    String? category,
    String? movementPattern,
    String? searchQuery,
  }) async {
    final accountId = await _getCurrentAccountId();
    var query = _client.from('exercises').select();

    // Include default exercises and trainer's custom exercises
    query = query.or('is_custom.eq.false,trainer_id.eq.$accountId');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (movementPattern != null) {
      query = query.eq('movement_pattern', movementPattern);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,name_ko.ilike.%$searchQuery%');
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get recent exercises for a client
  Future<List<ExerciseModel>> getRecentExercises({
    required String clientId,
    int limit = 10,
  }) async {
    final response = await _client
        .from('session_exercises')
        .select('''
          exercises(*)
        ''')
        .eq('sessions.client_id', clientId)
        .order('created_at', ascending: false)
        .limit(limit);

    // Extract unique exercises
    final exerciseSet = <String, ExerciseModel>{};
    for (final item in response as List) {
      final exerciseData = item['exercises'];
      if (exerciseData != null) {
        final exercise = ExerciseModel.fromJson(exerciseData as Map<String, dynamic>);
        exerciseSet[exercise.id] = exercise;
      }
    }

    return exerciseSet.values.toList();
  }

  /// Get exercise history for a client
  Future<List<ExerciseSetModel>> getExerciseHistory({
    required String clientId,
    required String exerciseId,
    int limit = 10,
  }) async {
    final response = await _client
        .from('exercise_sets')
        .select('''
          *,
          session_exercises!inner(
            exercise_id,
            sessions!inner(client_id)
          )
        ''')
        .eq('session_exercises.exercise_id', exerciseId)
        .eq('session_exercises.sessions.client_id', clientId)
        .order('completed_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ExerciseSetModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  String _statusToString(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return 'scheduled';
      case SessionStatus.active:
        return 'active';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.cancelled:
        return 'cancelled';
    }
  }
}
