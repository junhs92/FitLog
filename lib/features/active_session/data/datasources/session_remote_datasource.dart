import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../models/exercise_model.dart';
import '../models/exercise_set_model.dart';
import '../models/session_exercise_input.dart';
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
  /// Set [asClient] to true when querying as a client (filters by client_id instead of trainer_id)
  Future<List<SessionModel>> getSessions({
    String? clientId,
    SessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    bool asClient = false,
  }) async {
    final accountId = await _getCurrentAccountId();

    // Build filter query first, then add ordering
    // Note: sets are stored in set_records table (joined via session_exercises)
    var filterQuery = _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''');

    // For client queries, filter by client_id; for trainer queries, filter by trainer_id
    if (asClient) {
      filterQuery = filterQuery.eq('client_id', accountId);
    } else {
      filterQuery = filterQuery.eq('trainer_id', accountId);
      if (clientId != null) {
        filterQuery = filterQuery.eq('client_id', clientId);
      }
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
    // Note: sets are stored in set_records table (joined via session_exercises)
    final response = await _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''')
        .eq('id', sessionId)
        .single();

    return SessionModel.fromJson(response);
  }

  /// Get active session for a client
  Future<SessionModel?> getActiveSession(String clientId) async {
    final accountId = await _getCurrentAccountId();
    debugPrint('🔍 [getActiveSession] trainerId: $accountId, clientId: $clientId');

    // Note: sets are stored in set_records table (joined via session_exercises)
    final response = await _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''')
        .eq('trainer_id', accountId)
        .eq('client_id', clientId)
        .eq('status', 'active')
        .maybeSingle();

    if (response == null) {
      debugPrint('🔍 [getActiveSession] No active session found');
      return null;
    }

    debugPrint('🔍 [getActiveSession] Response session_id: ${response['id']}');
    final sessionExercises = response['session_exercises'] as List?;
    debugPrint('🔍 [getActiveSession] session_exercises count: ${sessionExercises?.length ?? 0}');
    if (sessionExercises != null && sessionExercises.isNotEmpty) {
      debugPrint('🔍 [getActiveSession] First exercise: ${sessionExercises[0]}');
    }

    return SessionModel.fromJson(response);
  }

  /// Start a new session
  /// If programId is provided, the session will be linked to the training program
  /// If exercises are provided, they will be added to session_exercises
  /// If aiReasoning is provided, it will be saved as session-level AI description
  Future<SessionModel> startSession({
    required String clientId,
    String? sessionType,
    String? notes,
    String? programId,
    List<Map<String, dynamic>>? exercises,
    String? aiReasoning,
  }) async {
    debugPrint('🟢 [DATASOURCE] startSession: Starting...');
    debugPrint('🟢 [DATASOURCE] clientId: $clientId, programId: $programId');
    debugPrint('🟢 [DATASOURCE] exercises provided: ${exercises?.length ?? 0}');
    debugPrint('🟢 [DATASOURCE] aiReasoning: ${aiReasoning != null ? 'provided' : 'null'}');

    final accountId = await _getCurrentAccountId();
    final now = DateTime.now();

    // Create session with optional program link
    final sessionData = {
      'trainer_id': accountId,
      'client_id': clientId,
      'status': 'active',
      'session_type': sessionType ?? 'training',
      'notes': notes,
      'scheduled_at': toLocalIso8601(now),
      'started_at': toLocalIso8601(now),
    };

    // Add program reference if provided
    if (programId != null) {
      sessionData['program_id'] = programId;
    }

    // Add AI reasoning if provided
    if (aiReasoning != null) {
      sessionData['ai_reasoning'] = aiReasoning;
    }

    final response = await _client.from('sessions').insert(sessionData).select('''
      *,
      accounts!sessions_client_id_fkey(full_name),
      session_exercises(
        *,
        exercises(*),
        set_records(*)
      )
    ''').single();

    final session = SessionModel.fromJson(response);
    debugPrint('🟢 [DATASOURCE] Session created: ${session.id}');

    // If exercises provided, add them to session_exercises
    if (exercises != null && exercises.isNotEmpty) {
      debugPrint('🟢 [DATASOURCE] Adding ${exercises.length} exercises to session');

      for (int i = 0; i < exercises.length; i++) {
        final exerciseData = exercises[i];
        final exerciseId = exerciseData['exercise_id'] as String;

        debugPrint('🟢 [DATASOURCE] Adding exercise $i: $exerciseId');

        // Insert exercise into session_exercises with target values
        await _client.from('session_exercises').insert({
          'session_id': session.id,
          'exercise_id': exerciseId,
          'order_index': i,
          'sets': [], // Empty sets array to start
          'target_sets': exerciseData['target_sets'],
          'target_reps': exerciseData['target_reps']?.toString(),
          'target_weight': exerciseData['target_weight'],
        });
      }

      debugPrint('🟢 [DATASOURCE] All exercises added. Fetching updated session...');

      // Fetch the updated session with exercises
      try {
        final updatedResponse = await _client
            .from('sessions')
            .select('''
              *,
              accounts!sessions_client_id_fkey(full_name),
              session_exercises(
                *,
                exercises(*),
                set_records(*)
              )
            ''')
            .eq('id', session.id)
            .single();

        debugPrint('🟢 [DATASOURCE] Updated session fetched successfully');
        return SessionModel.fromJson(updatedResponse);
      } catch (e) {
        debugPrint('🔴 [DATASOURCE] Failed to fetch updated session: $e');
        // Return the original session if fetch fails
        return session;
      }
    }

    return session;
  }

  /// Activate an existing session (created by AI edge function)
  /// Updates status from 'scheduled' to 'active', creates session_exercises from the exercise list
  /// Note: Session is created by edge function without session_exercises
  /// When user confirms in review screen, this method creates the session_exercises
  Future<SessionModel> activateSession({
    required String sessionId,
    List<Map<String, dynamic>>? exercises,
  }) async {
    debugPrint('🟢 [DATASOURCE] activateSession: $sessionId');
    debugPrint('🟢 [DATASOURCE] exercises to create: ${exercises?.length ?? 0}');

    final now = DateTime.now();

    // Create session_exercises from the exercise list (possibly modified by user in review screen)
    if (exercises != null && exercises.isNotEmpty) {
      debugPrint('🟢 [DATASOURCE] Creating ${exercises.length} session_exercises...');

      for (int i = 0; i < exercises.length; i++) {
        final exerciseData = exercises[i];
        final exerciseId = exerciseData['exerciseId'] as String;

        // Build notes JSON with metadata (only aiReasoning, targetRpe, restSeconds)
        final notesData = {
          'targetRpe': exerciseData['targetRpe'],
          'restSeconds': exerciseData['restSeconds'] ?? 60,
          'aiReasoning': exerciseData['aiReasoning'],
        };

        debugPrint('🟢 [DATASOURCE] Creating session_exercise $i: $exerciseId');

        // Insert with target values in proper columns
        await _client.from('session_exercises').insert({
          'session_id': sessionId,
          'exercise_id': exerciseId,
          'order_index': exerciseData['orderIndex'] ?? i,
          'target_sets': exerciseData['targetSets'] ?? 3,
          'target_reps': (exerciseData['targetReps'] ?? '10-12').toString(),
          'target_weight': exerciseData['targetWeight'],
          'notes': jsonEncode(notesData),
        });
      }

      debugPrint('🟢 [DATASOURCE] All session_exercises created');
    }

    // Update session status to 'active' and set started_at
    final response = await _client
        .from('sessions')
        .update({
          'status': 'active',
          'started_at': toLocalIso8601(now),
        })
        .eq('id', sessionId)
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''')
        .single();

    final session = SessionModel.fromJson(response);
    debugPrint('🟢 [DATASOURCE] Session activated: ${session.id} with ${session.exercises.length} exercises');

    return session;
  }

  /// Unified session creation (Template Pattern)
  ///
  /// Handles all 3 session start flows:
  /// - AI: [existingSessionId] provided → activate pre-created session
  /// - Previous: [exercises] provided → create new session with exercises
  /// - Empty: no exercises → create empty session for manual entry
  Future<SessionModel> createSession({
    required String clientId,
    List<SessionExerciseInput>? exercises,
    String? programId,
    String? existingSessionId,
    String? aiReasoning,
  }) async {
    debugPrint('🟢 [DATASOURCE] createSession: Starting unified flow...');
    debugPrint('🟢 [DATASOURCE] clientId: $clientId, existingSessionId: $existingSessionId');
    debugPrint('🟢 [DATASOURCE] exercises: ${exercises?.length ?? 0}, programId: $programId');

    final accountId = await _getCurrentAccountId();
    final now = DateTime.now();
    String sessionId;

    // Phase 1: Get or create session
    if (existingSessionId != null && existingSessionId.isNotEmpty) {
      // AI flow: session pre-created by edge function
      debugPrint('🟢 [DATASOURCE] AI flow: activating existing session $existingSessionId');
      sessionId = existingSessionId;

      // Update session status to 'active'
      await _client
          .from('sessions')
          .update({
            'status': 'active',
            'started_at': toLocalIso8601(now),
          })
          .eq('id', sessionId);
    } else {
      // Empty/Previous flow: create new session
      debugPrint('🟢 [DATASOURCE] Creating new session...');

      final sessionData = {
        'trainer_id': accountId,
        'client_id': clientId,
        'status': 'active',
        'session_type': 'training',
        'scheduled_at': toLocalIso8601(now),
        'started_at': toLocalIso8601(now),
        if (programId != null) 'program_id': programId,
        if (aiReasoning != null) 'ai_reasoning': aiReasoning,
      };

      final sessionResponse = await _client
          .from('sessions')
          .insert(sessionData)
          .select('id')
          .single();

      sessionId = sessionResponse['id'] as String;
      debugPrint('🟢 [DATASOURCE] Session created: $sessionId');
    }

    // Phase 2: Create session_exercises (if any)
    if (exercises != null && exercises.isNotEmpty) {
      debugPrint('🟢 [DATASOURCE] Creating ${exercises.length} session_exercises...');

      final exerciseRows = exercises
          .map((e) => e.toInsertMap(sessionId))
          .toList();

      await _client.from('session_exercises').insert(exerciseRows);
      debugPrint('🟢 [DATASOURCE] All session_exercises created');
    }

    // Phase 3: Fetch complete session with relations
    debugPrint('🟢 [DATASOURCE] Fetching complete session...');
    final response = await _client
        .from('sessions')
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''')
        .eq('id', sessionId)
        .single();

    final session = SessionModel.fromJson(response);
    debugPrint('🟢 [DATASOURCE] createSession complete: ${session.id} with ${session.exercises.length} exercises');

    return session;
  }

  /// Complete a session
  Future<SessionModel> completeSession({
    required String sessionId,
    int? overallRating,
    String? trainerFeedback,
  }) async {
    final now = DateTime.now();

    // Get session to calculate duration and summary stats
    final currentSession = await getSessionById(sessionId);
    final duration = currentSession.startedAt != null
        ? now.difference(currentSession.startedAt!)
        : null;

    // Calculate summary stats from exercises
    final summaryStats = _calculateSessionSummary(currentSession);

    // Build update data - only include fields that exist in the database
    final updateData = <String, dynamic>{
      'status': 'completed',
      'completed_at': toLocalIso8601(now),
      // Session summary stats
      'total_exercises': summaryStats['total_exercises'],
      'total_sets': summaryStats['total_sets'],
      'total_volume': summaryStats['total_volume'],
      'avg_reps': summaryStats['avg_reps'],
      'avg_rpe': summaryStats['avg_rpe'],
    };

    // Only add optional fields if they have values
    if (duration != null) {
      updateData['duration_seconds'] = duration.inSeconds;
    }
    if (overallRating != null) {
      updateData['rating'] = overallRating; // Column is 'rating' in database
    }
    if (trainerFeedback != null) {
      updateData['feedback'] = trainerFeedback; // Column is 'feedback' in database
    }

    debugPrint('🟢 [completeSession] Summary: ${summaryStats['total_exercises']} exercises, ${summaryStats['total_sets']} sets, volume: ${summaryStats['total_volume']}');

    // Note: sets are stored in set_records table (joined via session_exercises)
    final response = await _client
        .from('sessions')
        .update(updateData)
        .eq('id', sessionId)
        .select('''
          *,
          accounts!sessions_client_id_fkey(full_name),
          session_exercises(
            *,
            exercises(*),
            set_records(*)
          )
        ''')
        .single();

    return SessionModel.fromJson(response);
  }

  /// Calculate session summary stats from exercises
  Map<String, dynamic> _calculateSessionSummary(SessionModel session) {
    final exercises = session.exercises;

    int totalExercises = exercises.length;
    int totalSets = 0;
    double totalVolume = 0.0;
    int totalReps = 0;
    int setsWithReps = 0;
    double totalRpe = 0.0;
    int setsWithRpe = 0;

    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        totalSets++;

        // Volume = weight * reps
        if (set.weight != null && set.reps != null) {
          totalVolume += set.weight! * set.reps!;
        }

        // Track reps for average
        if (set.reps != null) {
          totalReps += set.reps!;
          setsWithReps++;
        }

        // Track RPE for average
        if (set.rpe != null) {
          totalRpe += set.rpe!;
          setsWithRpe++;
        }
      }
    }

    return {
      'total_exercises': totalExercises,
      'total_sets': totalSets,
      'total_volume': totalVolume,
      'avg_reps': setsWithReps > 0 ? (totalReps / setsWithReps) : null,
      'avg_rpe': setsWithRpe > 0 ? (totalRpe / setsWithRpe) : null,
    };
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
      'started_at': nowLocalIso8601(),
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

  /// Log a set (INSERT into set_records table)
  Future<ExerciseSetModel> logSet({
    required String sessionExerciseId,
    required int setNumber,
    double? weight,
    int? reps,
    double? rpe,
    int? durationSeconds,
    double? distance,
    List<String> tags = const [],
    List<String> comments = const [],
    String? notes,
    String? prType,
  }) async {
    debugPrint('🟡 DS.logSet: sessionExerciseId=$sessionExerciseId');
    debugPrint('🟡 DS.logSet: weight=$weight, reps=$reps, setNumber=$setNumber');

    // Create new set data for insert
    final newSetData = {
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'duration_seconds': durationSeconds,
      'distance': distance,
      'tags': tags,
      'comments': comments,
      'pr_type': prType,
      'notes': notes,
      'completed_at': nowLocalIso8601(),
    };
    debugPrint('🟡 DS.logSet: Inserting new set: $newSetData');

    // Insert into set_records table and return the created record
    final response = await _client
        .from('set_records')
        .insert(newSetData)
        .select()
        .single();
    debugPrint('🟡 DS.logSet: Insert complete! ID: ${response['id']}');

    return ExerciseSetModel.fromJson(response);
  }

  /// Update a set (UPDATE set_records table row)
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
    String? prType,
  }) async {
    debugPrint('🟡 DS.updateSet: setId=$setId');

    // Build update data with only non-null fields
    final updateData = <String, dynamic>{};
    if (weight != null) updateData['weight'] = weight;
    if (reps != null) updateData['reps'] = reps;
    if (rpe != null) updateData['rpe'] = rpe;
    if (durationSeconds != null) updateData['duration_seconds'] = durationSeconds;
    if (distance != null) updateData['distance'] = distance;
    if (tags != null) updateData['tags'] = tags;
    if (notes != null) updateData['notes'] = notes;
    if (prType != null) updateData['pr_type'] = prType;

    if (updateData.isEmpty) {
      // Nothing to update, just fetch and return current
      final current = await _client
          .from('set_records')
          .select()
          .eq('id', setId)
          .single();
      return ExerciseSetModel.fromJson(current);
    }

    // Update the set_records row and return updated record
    final response = await _client
        .from('set_records')
        .update(updateData)
        .eq('id', setId)
        .select()
        .single();

    debugPrint('🟡 DS.updateSet: Update complete!');
    return ExerciseSetModel.fromJson(response);
  }

  /// Delete a set (DELETE from set_records table)
  Future<void> deleteSet({
    required String setId,
    required String sessionExerciseId,
  }) async {
    debugPrint('🟡 DS.deleteSet: setId=$setId');

    // Delete the set_records row
    await _client
        .from('set_records')
        .delete()
        .eq('id', setId);

    debugPrint('🟡 DS.deleteSet: Delete complete!');
  }

  /// Complete an exercise
  Future<void> completeExercise(String sessionExerciseId) async {
    await _client.from('session_exercises').update({
      'completed_at': nowLocalIso8601(),
    }).eq('id', sessionExerciseId);
  }

  /// Update session exercise notes (for storing trainer comments)
  Future<void> updateSessionExerciseNotes({
    required String sessionExerciseId,
    required String notes,
  }) async {
    await _client
        .from('session_exercises')
        .update({'notes': notes})
        .eq('id', sessionExerciseId);
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
    String? movementGroup,
    String? searchQuery,
  }) async {
    final accountId = await _getCurrentAccountId();
    var query = _client.from('exercises').select();

    // Include default exercises and trainer's custom exercises
    query = query.or('is_custom.eq.false,trainer_id.eq.$accountId');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (movementGroup != null) {
      query = query.eq('movement_group', movementGroup);
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
        .from('set_records')
        .select('''
          *,
          session_exercises!inner(
            exercise_id,
            sessions!inner(client_id, status)
          )
        ''')
        .eq('session_exercises.exercise_id', exerciseId)
        .eq('session_exercises.sessions.client_id', clientId)
        .eq('session_exercises.sessions.status', 'completed')
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
      case SessionStatus.noShow:
        return 'no_show';
    }
  }
}
