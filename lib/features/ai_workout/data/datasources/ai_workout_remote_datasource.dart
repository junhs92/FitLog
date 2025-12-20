import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_program_model.dart';
import '../models/session_feedback_model.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/exercise_difficulty.dart';

/// Remote datasource for AI workout operations
class AIWorkoutRemoteDataSource {
  final SupabaseClient _client;
  final _uuid = const Uuid();
  String? _cachedAccountId;

  AIWorkoutRemoteDataSource(this._client);

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

  /// Get previous goal for a client (for pre-filling the form)
  Future<TrainingGoal?> getPreviousGoal(String clientId) async {
    final response = await _client
        .from('workout_programs')
        .select('primary_goal')
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final goalId = response['primary_goal'] as String?;
    if (goalId == null) return null;

    return TrainingGoal.fromString(goalId);
  }

  /// Get previous exercise IDs to avoid overlap
  Future<List<String>> _getPreviousExerciseIds(String clientId, {int limit = 3}) async {
    final response = await _client
        .from('workout_programs')
        .select('''
          workout_days(
            program_exercises(exercise_id)
          )
        ''')
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .limit(limit);

    final exerciseIds = <String>[];
    for (final program in (response as List<dynamic>)) {
      final programMap = program as Map<String, dynamic>;
      final workoutDays = programMap['workout_days'] as List<dynamic>? ?? [];
      for (final day in workoutDays) {
        final dayMap = day as Map<String, dynamic>;
        final programExercises = dayMap['program_exercises'] as List<dynamic>? ?? [];
        for (final pe in programExercises) {
          final peMap = pe as Map<String, dynamic>;
          if (peMap['exercise_id'] != null) {
            exerciseIds.add(peMap['exercise_id'] as String);
          }
        }
      }
    }
    return exerciseIds;
  }

  /// Generate a single workout session using AI (via Edge Function)
  /// Uses OpenAI GPT-4 with comprehensive client context
  /// Always generates 1 session at a time with context from previous sessions
  Future<WorkoutProgramModel> generateProgram({
    required String clientId,
    required String trainerId,
    required TrainingGoal primaryGoal,
    TrainingGoal? secondaryGoal,
    int? durationWeeks, // Ignored - always 1
    int? sessionsPerWeek, // Ignored - always 1
    List<String>? excludedExerciseIds,
    List<String>? preferredEquipment,
    int sessionDurationMinutes = 60,
  }) async {
    // Get account ID if trainerId is empty
    final actualTrainerId = trainerId.isNotEmpty
        ? trainerId
        : await _getCurrentAccountId();

    // Get previous exercises to exclude
    final previousExerciseIds = await _getPreviousExerciseIds(clientId);
    final allExcluded = {...?excludedExerciseIds, ...previousExerciseIds}.toList();

    try {
      // Call Edge Function for AI-powered generation
      // Always generate single session (1 week, 1 session)
      print('[AI Workout] ====== STARTING EDGE FUNCTION CALL ======');
      print('[AI Workout] Timestamp: ${DateTime.now().toIso8601String()}');
      print('[AI Workout] ClientId: $clientId, TrainerId: $actualTrainerId, Goal: ${primaryGoal.id}');

      final response = await _client.functions.invoke(
        'generate-workout',
        body: {
          'clientId': clientId,
          'trainerId': actualTrainerId,
          'primaryGoal': primaryGoal.id,
          'secondaryGoal': secondaryGoal?.id,
          'durationWeeks': 1, // Always 1 session
          'sessionsPerWeek': 1, // Always 1 session
          'excludedExerciseIds': allExcluded,
          'preferredEquipment': preferredEquipment ?? [],
          'sessionDurationMinutes': sessionDurationMinutes,
        },
      );

      print('[AI Workout] Edge Function response status: ${response.status}');
      print('[AI Workout] Edge Function response data type: ${response.data?.runtimeType}');

      if (response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        print('[AI Workout] Edge Function response keys: ${dataMap.keys.toList()}');
        print('[AI Workout] Edge Function response ai_model_version: ${dataMap['ai_model_version']}');
        print('[AI Workout] Edge Function response program name: ${dataMap['name']}');
      }

      if (response.status != 200) {
        print('[AI Workout] Edge Function FAILED with status ${response.status}');
        print('[AI Workout] Error response: ${response.data}');
        throw Exception(
          'Failed to generate workout: ${response.data?['error'] ?? 'Unknown error'}',
        );
      }

      // Parse response and return program
      print('[AI Workout] Edge Function SUCCESS! Starting to parse response...');
      try {
        final program = WorkoutProgramModel.fromJson(response.data as Map<String, dynamic>);
        print('[AI Workout] ====== EDGE FUNCTION SUCCESS ======');
        print('[AI Workout] Program ID: ${program.id}');
        print('[AI Workout] Program name: ${program.name}');
        print('[AI Workout] AI Model Version: ${program.aiModelVersion}');
        print('[AI Workout] Exercises: ${program.workoutDays.firstOrNull?.exercises.length ?? 0}');
        return program;
      } catch (parseError, parseStack) {
        print('[AI Workout] ====== PARSE ERROR ======');
        print('[AI Workout] Failed to parse Edge Function response: $parseError');
        print('[AI Workout] Parse stack trace: $parseStack');
        print('[AI Workout] Raw response data: ${response.data}');
        rethrow;
      }
    } catch (e, stackTrace) {
      // Fallback to local generation if Edge Function fails
      print('[AI Workout] ====== EDGE FUNCTION FAILED ======');
      print('[AI Workout] Error type: ${e.runtimeType}');
      print('[AI Workout] Error message: $e');
      print('[AI Workout] Stack trace: $stackTrace');
      print('[AI Workout] ====== STARTING FALLBACK GENERATION ======');
      return _generateProgramLocally(
        clientId: clientId,
        trainerId: actualTrainerId,
        primaryGoal: primaryGoal,
        secondaryGoal: secondaryGoal,
        excludedExerciseIds: allExcluded,
        preferredEquipment: preferredEquipment,
        recentExerciseIds: previousExerciseIds,
      );
    }
  }

  /// Fallback local generation (rule-based) if AI is unavailable
  /// Always generates single session with variety from previous sessions
  Future<WorkoutProgramModel> _generateProgramLocally({
    required String clientId,
    required String trainerId,
    required TrainingGoal primaryGoal,
    TrainingGoal? secondaryGoal,
    List<String>? excludedExerciseIds,
    List<String>? preferredEquipment,
    List<String>? recentExerciseIds,
  }) async {
    // Safety check: Prevent duplicate creation if Edge Function already saved a program
    // Check if a program was created for this client in the last 60 seconds
    print('[AI Workout Fallback] Checking for recently created programs...');
    final recentProgram = await _client
        .from('workout_programs')
        .select('id, name, ai_model_version, created_at')
        .eq('client_id', clientId)
        .eq('primary_goal', primaryGoal.id)
        .gte('created_at', DateTime.now().subtract(const Duration(seconds: 60)).toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (recentProgram != null) {
      print('[AI Workout Fallback] ====== DUPLICATE PREVENTION ======');
      print('[AI Workout Fallback] Found recent program: ${recentProgram['name']}');
      print('[AI Workout Fallback] AI Model: ${recentProgram['ai_model_version']}');
      print('[AI Workout Fallback] Created at: ${recentProgram['created_at']}');
      print('[AI Workout Fallback] Returning existing program instead of creating duplicate');

      // Return the already-created program instead of making a new one
      return getProgram(recentProgram['id'] as String);
    }

    print('[AI Workout Fallback] No recent program found, proceeding with fallback generation');
    final programId = _uuid.v4();

    // Always generate single session
    const durationWeeks = 1;
    const sessionsPerWeek = 1;

    // Get client profile for personalization
    final clientProfile = await _getClientProfile(clientId);

    // Get exercise library
    final exercises = await _getExerciseLibrary(
      excludedIds: excludedExerciseIds,
      preferredEquipment: preferredEquipment,
    );

    // Get client's exercise history for personalized weight recommendations
    final exerciseHistory = await _getClientExerciseHistory(clientId);
    print('[AI Workout Fallback] Found history for ${exerciseHistory.length} exercises');

    // Generate workout days based on goal and frequency
    final workoutDays = _generateWorkoutDays(
      programId: programId,
      exercises: exercises,
      primaryGoal: primaryGoal,
      sessionsPerWeek: sessionsPerWeek,
      clientProfile: clientProfile,
      recentExerciseIds: recentExerciseIds ?? [],
      exerciseHistory: exerciseHistory,
    );

    // Create program name based on goal
    final programName = _generateSessionName(primaryGoal);

    // Insert program into database
    // ai_model_version: 'dart-fallback' indicates local generation, not OpenAI
    final programData = {
      'id': programId,
      'client_id': clientId,
      'trainer_id': trainerId,
      'name': programName,
      'description': _generateSessionDescription(primaryGoal),
      'primary_goal': primaryGoal.id,
      'secondary_goal': secondaryGoal?.id,
      'duration_weeks': durationWeeks,
      'sessions_per_week': sessionsPerWeek,
      'status': ProgramStatus.draft.id,
      'is_ai_generated': true,
      'ai_model_version': 'dart-fallback',
      'customization_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _client.from('workout_programs').insert(programData);

    // Insert workout days
    for (final day in workoutDays) {
      await _client.from('workout_days').insert(day.toJson());

      // Insert exercises for each day
      for (final exercise in day.exercises) {
        await _client.from('program_exercises').insert(exercise.toJson());
      }
    }

    // Fetch and return complete program
    return getProgram(programId);
  }

  /// Get a workout program by ID
  Future<WorkoutProgramModel> getProgram(String programId) async {
    final response = await _client
        .from('workout_programs')
        .select('''
          *,
          workout_days(
            *,
            program_exercises(
              *,
              exercises!program_exercises_exercise_id_fkey(id, name, name_ko, movement_pattern, equipment, muscle_group)
            )
          )
        ''')
        .eq('id', programId)
        .single();

    return WorkoutProgramModel.fromJson(response);
  }

  /// Get all programs for a client
  Future<List<WorkoutProgramModel>> getClientPrograms(String clientId) async {
    final response = await _client
        .from('workout_programs')
        .select('''
          *,
          workout_days(
            *,
            program_exercises(
              *,
              exercises!program_exercises_exercise_id_fkey(id, name, name_ko)
            )
          )
        ''')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => WorkoutProgramModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get active program for a client
  Future<WorkoutProgramModel?> getActiveProgram(String clientId) async {
    final response = await _client
        .from('workout_programs')
        .select('''
          *,
          workout_days(
            *,
            program_exercises(
              *,
              exercises!program_exercises_exercise_id_fkey(id, name, name_ko, movement_pattern)
            )
          )
        ''')
        .eq('client_id', clientId)
        .eq('status', ProgramStatus.active.id)
        .maybeSingle();

    if (response == null) return null;
    return WorkoutProgramModel.fromJson(response);
  }

  /// Update program status
  Future<void> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async {
    final updates = <String, dynamic>{'status': status.id};

    if (status == ProgramStatus.active) {
      updates['started_at'] = DateTime.now().toIso8601String();
    } else if (status == ProgramStatus.completed) {
      updates['completed_at'] = DateTime.now().toIso8601String();
    }

    await _client
        .from('workout_programs')
        .update(updates)
        .eq('id', programId);
  }

  /// Swap an exercise in a program
  Future<ProgramExerciseModel> swapExercise({
    required String programExerciseId,
    required String newExerciseId,
    String? reason,
  }) async {
    // Get current exercise info
    final current = await _client
        .from('program_exercises')
        .select('*, exercises!program_exercises_exercise_id_fkey(id, name, name_ko)')
        .eq('id', programExerciseId)
        .single();

    // Get new exercise info
    final newExercise = await _client
        .from('exercises')
        .select()
        .eq('id', newExerciseId)
        .single();

    // Update program exercise
    final updates = {
      'exercise_id': newExerciseId,
      'original_exercise_id': current['original_exercise_id'] ?? current['exercise_id'],
      'is_swapped': true,
      'notes': reason,
    };

    await _client
        .from('program_exercises')
        .update(updates)
        .eq('id', programExerciseId);

    // Update customization count on program
    final dayData = await _client
        .from('workout_days')
        .select('program_id')
        .eq('id', current['workout_day_id'])
        .single();

    await _client.rpc('increment_customization_count', params: {
      'program_id': dayData['program_id'],
    });

    // Return updated exercise
    final updated = await _client
        .from('program_exercises')
        .select('*, exercises!program_exercises_exercise_id_fkey(id, name, name_ko, movement_pattern)')
        .eq('id', programExerciseId)
        .single();

    return ProgramExerciseModel.fromJson(updated);
  }

  /// Get alternatives for an exercise
  Future<List<ExerciseAlternative>> getAlternatives({
    required String exerciseId,
    required String clientId,
    DifficultyFeedback? feedbackHint,
  }) async {
    // Get current exercise info
    final currentExercise = await _client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .single();

    final movementPattern = currentExercise['movement_pattern'] as String;
    final currentDifficulty = ExerciseDifficulty.fromString(
      currentExercise['difficulty'] as String? ?? 'intermediate',
    );

    // Get similar exercises
    final alternatives = await _client
        .from('exercises')
        .select()
        .eq('movement_pattern', movementPattern)
        .neq('id', exerciseId)
        .limit(10);

    return (alternatives as List).map((exercise) {
      final difficulty = ExerciseDifficulty.fromString(
        exercise['difficulty'] as String? ?? 'intermediate',
      );
      final equipment = EquipmentType.fromString(
        exercise['equipment'] as String? ?? 'other',
      );

      // Determine alternative type based on difficulty comparison
      AlternativeType type;
      String reason;
      String reasonKo;

      if (feedbackHint == DifficultyFeedback.struggling) {
        type = AlternativeType.easier;
        reason = 'Lower difficulty, same movement pattern';
        reasonKo = '난이도 낮춤, 동일 패턴';
      } else if (feedbackHint == DifficultyFeedback.tooEasy) {
        type = AlternativeType.harder;
        reason = 'Higher challenge, same movement pattern';
        reasonKo = '난이도 높임, 동일 패턴';
      } else if (difficulty.level < currentDifficulty.level) {
        type = AlternativeType.easier;
        reason = 'Reduced complexity while maintaining muscle activation';
        reasonKo = '근육 활성화 유지하며 복잡성 감소';
      } else if (difficulty.level > currentDifficulty.level) {
        type = AlternativeType.harder;
        reason = 'Increased challenge for progressive overload';
        reasonKo = '점진적 과부하를 위한 도전 증가';
      } else {
        type = AlternativeType.samePattern;
        reason = 'Similar difficulty with different stimulus';
        reasonKo = '다른 자극으로 유사 난이도';
      }

      return ExerciseAlternative(
        exerciseId: exercise['id'] as String,
        exerciseName: exercise['name'] as String,
        exerciseNameKo: exercise['name_ko'] as String?,
        type: type,
        reason: reason,
        reasonKo: reasonKo,
        difficulty: difficulty,
        equipment: equipment,
      );
    }).toList();
  }

  /// Get AI reasoning for exercise selection
  Future<AIExerciseReasoning> getExerciseReasoning({
    required String exerciseId,
    required String clientId,
    required TrainingGoal goal,
  }) async {
    // Get exercise details
    final exercise = await _client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .single();

    // Get client history with this exercise
    final history = await _client
        .from('session_exercises')
        .select('sets')
        .eq('exercise_id', exerciseId)
        .eq('sessions.client_id', clientId)
        .limit(5);

    // Generate reasoning based on goal, exercise properties, and history
    final reasons = <AIReasoningPoint>[];

    // Goal alignment reasoning
    reasons.add(AIReasoningPoint(
      category: ReasoningCategory.goalAlignment,
      explanation: _getGoalAlignmentReason(exercise, goal),
      explanationKo: _getGoalAlignmentReasonKo(exercise, goal),
      confidence: 0.9,
    ));

    // History-based reasoning if available
    if ((history as List).isNotEmpty) {
      reasons.add(const AIReasoningPoint(
        category: ReasoningCategory.historyBased,
        explanation: 'Consistent performance in recent sessions',
        explanationKo: '최근 세션에서 일관된 수행',
        confidence: 0.85,
      ));
    }

    // Movement pattern reasoning
    reasons.add(AIReasoningPoint(
      category: ReasoningCategory.progressiveOverload,
      explanation: 'Fits progression plan for ${exercise['movement_pattern']} pattern',
      explanationKo: '${exercise['movement_pattern']} 패턴 진행 계획에 적합',
      confidence: 0.8,
    ));

    return AIExerciseReasoning(
      exerciseId: exerciseId,
      reasons: reasons,
      overallScore: 0.85,
      generatedAt: DateTime.now(),
    );
  }

  /// Record difficulty feedback during session
  Future<SessionExerciseFeedbackModel> recordDifficultyFeedback({
    required String sessionExerciseId,
    required String exerciseId,
    required DifficultyFeedback feedback,
  }) async {
    final feedbackData = {
      'id': _uuid.v4(),
      'session_exercise_id': sessionExerciseId,
      'exercise_id': exerciseId,
      'feedback': feedback.id,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _client.from('session_exercise_feedback').insert(feedbackData);

    return SessionExerciseFeedbackModel(
      sessionExerciseId: sessionExerciseId,
      exerciseId: exerciseId,
      feedback: feedback,
      timestamp: DateTime.now(),
      suggestedAlternatives: [],
    );
  }

  /// Get session alternatives based on feedback
  Future<List<SessionAlternativeModel>> getSessionAlternatives({
    required String exerciseId,
    required String clientId,
    required DifficultyFeedback feedback,
  }) async {
    final exercise = await _client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .single();

    final movementPattern = exercise['movement_pattern'] as String;

    // Get alternatives based on movement pattern and feedback
    var query = _client
        .from('exercises')
        .select()
        .eq('movement_pattern', movementPattern)
        .neq('id', exerciseId);

    // Filter by difficulty based on feedback
    if (feedback == DifficultyFeedback.struggling) {
      query = query.or('difficulty.eq.beginner,difficulty.eq.intermediate');
    } else if (feedback == DifficultyFeedback.tooEasy) {
      query = query.or('difficulty.eq.advanced,difficulty.eq.expert');
    }

    final results = await query.limit(5);

    return (results as List).asMap().entries.map((entry) {
      final alt = entry.value as Map<String, dynamic>;
      final isFirst = entry.key == 0;

      String reason;
      String reasonKo;
      AlternativeType type;

      if (feedback == DifficultyFeedback.struggling) {
        type = AlternativeType.easier;
        reason = 'Same muscle group, stable positioning';
        reasonKo = '동일 근육군, 안정된 자세';
      } else {
        type = AlternativeType.harder;
        reason = 'Increased challenge for better stimulus';
        reasonKo = '더 나은 자극을 위한 도전 증가';
      }

      return SessionAlternativeModel(
        exerciseId: alt['id'] as String,
        exerciseName: alt['name'] as String,
        exerciseNameKo: alt['name_ko'] as String?,
        type: type.id,
        reason: reason,
        reasonKo: reasonKo,
        isRecommended: isFirst,
      );
    }).toList();
  }

  /// Record exercise swap history
  Future<void> recordSwapHistory({
    required String clientId,
    required String trainerId,
    required String originalExerciseId,
    required String replacementExerciseId,
    DifficultyFeedback? feedbackReason,
    String? customReason,
    String? sessionId,
  }) async {
    await _client.from('exercise_swap_history').insert({
      'id': _uuid.v4(),
      'client_id': clientId,
      'trainer_id': trainerId,
      'original_exercise_id': originalExerciseId,
      'replacement_exercise_id': replacementExerciseId,
      'feedback_reason': feedbackReason?.id,
      'custom_reason': customReason,
      'swapped_at': DateTime.now().toIso8601String(),
      'session_id': sessionId,
    });
  }

  /// Get swap history for a client
  Future<List<ExerciseSwapHistoryModel>> getSwapHistory({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client
        .from('exercise_swap_history')
        .select()
        .eq('client_id', clientId);

    if (fromDate != null) {
      query = query.gte('swapped_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('swapped_at', toDate.toIso8601String());
    }

    final results = await query.order('swapped_at', ascending: false);

    return (results as List)
        .map((e) => ExerciseSwapHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Delete a program
  Future<void> deleteProgram(String programId) async {
    // Cascade delete handled by database
    await _client.from('workout_programs').delete().eq('id', programId);
  }

  // Private helper methods

  Future<Map<String, dynamic>?> _getClientProfile(String clientId) async {
    final response = await _client
        .from('accounts')
        .select()
        .eq('id', clientId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> _getExerciseLibrary({
    List<String>? excludedIds,
    List<String>? preferredEquipment,
  }) async {
    var query = _client.from('exercises').select();

    if (excludedIds != null && excludedIds.isNotEmpty) {
      // Supabase doesn't have a direct "not in" for arrays, so we filter client-side
    }

    final results = await query;
    var exercises = (results as List).cast<Map<String, dynamic>>();

    if (excludedIds != null && excludedIds.isNotEmpty) {
      exercises = exercises
          .where((e) => !excludedIds.contains(e['id']))
          .toList();
    }

    return exercises;
  }

  /// Get client's exercise history for personalized weight/rep recommendations
  /// Returns a map of exerciseId -> {bestWeight, bestReps, lastWeight, lastReps, avgRpe}
  Future<Map<String, Map<String, dynamic>>> _getClientExerciseHistory(
    String clientId,
  ) async {
    try {
      // Get recent session data with exercise sets (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _client
          .from('sessions')
          .select('''
            session_exercises (
              exercise_id,
              sets
            )
          ''')
          .eq('client_id', clientId)
          .eq('status', 'completed')
          .gte('started_at', thirtyDaysAgo.toIso8601String())
          .order('started_at', ascending: false)
          .limit(20);

      final history = <String, Map<String, dynamic>>{};

      for (final session in (response as List)) {
        final exercises = session['session_exercises'] as List<dynamic>? ?? [];

        for (final exercise in exercises) {
          final exerciseId = exercise['exercise_id'] as String?;
          final setsJson = exercise['sets'];
          if (exerciseId == null || setsJson == null) continue;

          // Parse sets from JSONB
          final sets = setsJson is List ? setsJson : [];

          for (final set in sets) {
            final weight = (set['weight'] as num?)?.toDouble();
            final reps = set['reps'] as int?;
            final rpe = (set['rpe'] as num?)?.toDouble();

            if (weight == null || reps == null || weight <= 0) continue;

            if (!history.containsKey(exerciseId)) {
              history[exerciseId] = {
                'bestWeight': weight,
                'bestReps': reps,
                'lastWeight': weight,
                'lastReps': reps,
                'totalRpe': rpe ?? 0.0,
                'rpeCount': rpe != null ? 1 : 0,
                'setCount': 1,
              };
            } else {
              final current = history[exerciseId]!;
              // Track best performance (highest weight)
              if (weight > (current['bestWeight'] as double)) {
                current['bestWeight'] = weight;
                current['bestReps'] = reps;
              }
              // Track last performance (for progression)
              current['lastWeight'] = weight;
              current['lastReps'] = reps;
              // Track average RPE
              if (rpe != null) {
                current['totalRpe'] = (current['totalRpe'] as double) + rpe;
                current['rpeCount'] = (current['rpeCount'] as int) + 1;
              }
              current['setCount'] = (current['setCount'] as int) + 1;
            }
          }
        }
      }

      // Calculate average RPE for each exercise
      for (final entry in history.entries) {
        final rpeCount = entry.value['rpeCount'] as int;
        if (rpeCount > 0) {
          entry.value['avgRpe'] = (entry.value['totalRpe'] as double) / rpeCount;
        }
        // Clean up temporary fields
        entry.value.remove('totalRpe');
        entry.value.remove('rpeCount');
      }

      return history;
    } catch (e) {
      print('[AI Workout] Error fetching exercise history: $e');
      return {};
    }
  }

  List<WorkoutDayModel> _generateWorkoutDays({
    required String programId,
    required List<Map<String, dynamic>> exercises,
    required TrainingGoal primaryGoal,
    required int sessionsPerWeek,
    Map<String, dynamic>? clientProfile,
    List<String> recentExerciseIds = const [],
    Map<String, Map<String, dynamic>> exerciseHistory = const {},
  }) {
    final days = <WorkoutDayModel>[];
    final splitType = _getSplitType(sessionsPerWeek);

    for (int i = 0; i < sessionsPerWeek; i++) {
      final dayId = _uuid.v4();
      final dayInfo = _getDayInfo(splitType, i, primaryGoal);
      final dayExercises = _selectExercisesForDay(
        workoutDayId: dayId,
        exercises: exercises,
        focusArea: dayInfo['focus'] as String,
        goal: primaryGoal,
        exerciseCount: dayInfo['exerciseCount'] as int,
        recentExerciseIds: recentExerciseIds,
        exerciseHistory: exerciseHistory,
      );

      days.add(WorkoutDayModel(
        id: dayId,
        programId: programId,
        dayNumber: i + 1,
        name: dayInfo['name'] as String,
        focusArea: dayInfo['focus'] as String,
        exercises: dayExercises,
        estimatedDurationMinutes: dayInfo['duration'] as int,
      ));
    }

    return days;
  }

  String _getSplitType(int sessionsPerWeek) {
    switch (sessionsPerWeek) {
      case 1:
      case 2:
        return 'full_body';
      case 3:
        return 'push_pull_legs';
      case 4:
        return 'upper_lower';
      case 5:
      case 6:
        return 'push_pull_legs_double';
      default:
        return 'full_body';
    }
  }

  Map<String, dynamic> _getDayInfo(
    String splitType,
    int dayIndex,
    TrainingGoal goal,
  ) {
    final baseExerciseCount = goal == TrainingGoal.hypertrophy ? 6 : 5;
    final baseDuration = goal == TrainingGoal.hypertrophy ? 60 : 45;

    switch (splitType) {
      case 'full_body':
        return {
          'name': 'Day ${dayIndex + 1}: Full Body',
          'focus': 'full_body',
          'exerciseCount': baseExerciseCount,
          'duration': baseDuration,
        };
      case 'upper_lower':
        final isUpper = dayIndex % 2 == 0;
        return {
          'name': 'Day ${dayIndex + 1}: ${isUpper ? 'Upper Body' : 'Lower Body'}',
          'focus': isUpper ? 'upper' : 'lower',
          'exerciseCount': baseExerciseCount,
          'duration': baseDuration,
        };
      case 'push_pull_legs':
      case 'push_pull_legs_double':
        final focuses = ['push', 'pull', 'legs'];
        final focus = focuses[dayIndex % 3];
        final names = {
          'push': 'Push (Chest, Shoulders, Triceps)',
          'pull': 'Pull (Back, Biceps)',
          'legs': 'Legs (Quads, Hamstrings, Glutes)',
        };
        return {
          'name': 'Day ${dayIndex + 1}: ${names[focus]}',
          'focus': focus,
          'exerciseCount': baseExerciseCount,
          'duration': baseDuration,
        };
      default:
        return {
          'name': 'Day ${dayIndex + 1}',
          'focus': 'full_body',
          'exerciseCount': baseExerciseCount,
          'duration': baseDuration,
        };
    }
  }

  List<ProgramExerciseModel> _selectExercisesForDay({
    required String workoutDayId,
    required List<Map<String, dynamic>> exercises,
    required String focusArea,
    required TrainingGoal goal,
    required int exerciseCount,
    List<String> recentExerciseIds = const [],
    Map<String, Map<String, dynamic>> exerciseHistory = const {},
  }) {
    const minExercises = 5; // Ensure minimum 5 exercises per session

    // Filter exercises by focus area
    var filtered = exercises.where((e) {
      final pattern = e['movement_pattern'] as String? ?? '';
      final muscle = e['muscle_group'] as String? ?? '';

      switch (focusArea) {
        case 'upper':
          return ['horizontal_push', 'horizontal_pull', 'vertical_push', 'vertical_pull']
              .contains(pattern);
        case 'lower':
          return ['squat', 'hinge'].contains(pattern);
        case 'push':
          return ['horizontal_push', 'vertical_push'].contains(pattern) ||
              ['chest', 'shoulders', 'triceps'].contains(muscle);
        case 'pull':
          return ['horizontal_pull', 'vertical_pull'].contains(pattern) ||
              ['back', 'biceps'].contains(muscle);
        case 'legs':
          return ['squat', 'hinge'].contains(pattern) ||
              ['quadriceps', 'hamstrings', 'glutes', 'calves'].contains(muscle);
        default:
          return true;
      }
    }).toList();

    // Fallback: if not enough exercises, expand to include all exercises
    if (filtered.length < minExercises) {
      filtered = List.from(exercises);
    }

    // Separate exercises into fresh (not in recent) and recent
    final freshExercises = filtered.where((e) =>
        !recentExerciseIds.contains(e['id'] as String)).toList();
    final recentButAvailable = filtered.where((e) =>
        recentExerciseIds.contains(e['id'] as String)).toList();

    // Select exercises ensuring variety, preferring fresh exercises
    final selected = <ProgramExerciseModel>[];
    final usedPatterns = <String>{};
    final usedIds = <String>{};

    final targetCount = exerciseCount < minExercises ? minExercises : exerciseCount;

    // For full_body, track upper/lower balance
    const upperPatterns = {'horizontal_push', 'horizontal_pull', 'vertical_push', 'vertical_pull'};
    const lowerPatterns = {'squat', 'hinge'};

    for (int i = 0; i < targetCount && (freshExercises.isNotEmpty || recentButAvailable.isNotEmpty); i++) {
      // For full_body: check if we need to force upper or lower body selection
      List<String>? requiredPatterns;
      if (focusArea == 'full_body' && selected.length >= 2 && selected.length <= 4) {
        final hasUpper = usedPatterns.any((p) => upperPatterns.contains(p));
        final hasLower = usedPatterns.any((p) => lowerPatterns.contains(p));

        if (!hasLower) {
          // Force lower body exercises
          requiredPatterns = lowerPatterns.toList();
        } else if (!hasUpper) {
          // Force upper body exercises
          requiredPatterns = upperPatterns.toList();
        }
      }

      // Helper to check if exercise matches required patterns (if any)
      bool matchesRequired(Map<String, dynamic> e) {
        if (requiredPatterns == null) return true;
        final pattern = e['movement_pattern'] as String? ?? '';
        return requiredPatterns.contains(pattern);
      }

      // 1. Fresh exercises with unique patterns (filtered by required if full_body needs balance)
      var available = freshExercises.where((e) {
        final pattern = e['movement_pattern'] as String? ?? '';
        final id = e['id'] as String;
        return !usedIds.contains(id) &&
               (!usedPatterns.contains(pattern) || usedPatterns.length >= 4) &&
               matchesRequired(e);
      }).toList();

      // 2. Recent exercises with unique patterns (NEW - try unique from all sources first)
      if (available.isEmpty) {
        available = recentButAvailable.where((e) {
          final pattern = e['movement_pattern'] as String? ?? '';
          final id = e['id'] as String;
          return !usedIds.contains(id) &&
                 (!usedPatterns.contains(pattern) || usedPatterns.length >= 4) &&
                 matchesRequired(e);
        }).toList();
      }

      // 3. Any fresh exercise matching required patterns
      if (available.isEmpty) {
        available = freshExercises.where((e) {
          final id = e['id'] as String;
          return !usedIds.contains(id) && matchesRequired(e);
        }).toList();
      }

      // 4. Any recent exercise matching required patterns (after 3 selected or if required)
      if (available.isEmpty && (selected.length >= 3 || requiredPatterns != null)) {
        available = recentButAvailable.where((e) {
          final id = e['id'] as String;
          return !usedIds.contains(id) && matchesRequired(e);
        }).toList();
      }

      // 5. Last resort: any remaining exercise (ignore required patterns)
      if (available.isEmpty) {
        available = filtered.where((e) {
          final id = e['id'] as String;
          return !usedIds.contains(id);
        }).toList();
      }

      if (available.isEmpty) break;

      final exercise = available[i % available.length];
      final exerciseId = exercise['id'] as String;
      final pattern = exercise['movement_pattern'] as String? ?? '';
      usedPatterns.add(pattern);
      usedIds.add(exerciseId);

      // Determine sets and reps based on goal
      final setsReps = _getSetsRepsForGoal(goal);

      // Calculate target weight based on history or estimate
      final targetWeight = _calculateTargetWeight(
        exerciseId: exerciseId,
        exercise: exercise,
        goal: goal,
        exerciseHistory: exerciseHistory,
        targetReps: setsReps['reps'] as String,
      );

      // Generate context-aware reasoning (include weight source info)
      final reasoning = _generateExerciseReasoning(
        exercise: exercise,
        goal: goal,
        orderIndex: i,
        focusArea: focusArea,
        hasHistory: exerciseHistory.containsKey(exerciseId),
      );

      selected.add(ProgramExerciseModel(
        id: _uuid.v4(),
        workoutDayId: workoutDayId,
        exerciseId: exerciseId,
        exerciseName: exercise['name'] as String,
        exerciseNameKo: exercise['name_ko'] as String?,
        orderIndex: i,
        targetSets: setsReps['sets'] as int,
        targetReps: setsReps['reps'] as String,
        targetWeight: targetWeight,
        targetRpe: setsReps['rpe'] as int?,
        restSeconds: setsReps['rest'] as int,
        aiReasoningJson: reasoning,
      ));
    }

    return selected;
  }

  /// Generate context-aware reasoning for exercise selection
  Map<String, dynamic> _generateExerciseReasoning({
    required Map<String, dynamic> exercise,
    required TrainingGoal goal,
    required int orderIndex,
    required String focusArea,
    bool hasHistory = false,
  }) {
    final reasons = <Map<String, dynamic>>[];
    final pattern = exercise['movement_pattern'] as String? ?? '';
    final equipment = exercise['equipment'] as String? ?? '';

    // 1. Goal alignment reason (always include)
    reasons.add(_getGoalAlignmentReasonMap(goal, pattern));

    // 2. Movement pattern reason
    reasons.add(_getMovementPatternReasonMap(pattern));

    // 3. Weight/progression reason based on history
    if (hasHistory) {
      reasons.add({
        'category': 'progressive_overload',
        'explanation': 'Weight recommendation based on your previous performance with progressive overload',
        'explanation_ko': '이전 운동 기록을 바탕으로 점진적 과부하 적용',
        'confidence': 0.92,
      });
    } else if (orderIndex < 3) {
      reasons.add({
        'category': 'progressive_overload',
        'explanation': 'Compound movement placed early for maximum strength output',
        'explanation_ko': '최대 근력 발휘를 위해 복합 운동을 초반에 배치',
        'confidence': 0.88,
      });
    } else {
      reasons.add({
        'category': 'time_efficiency',
        'explanation': 'Accessory work to target specific muscles after compounds',
        'explanation_ko': '복합 운동 후 특정 근육 집중 자극',
        'confidence': 0.82,
      });
    }

    // 4. Equipment-based reason (if applicable)
    if (equipment.isNotEmpty && equipment != 'bodyweight') {
      reasons.add(_getEquipmentReasonMap(equipment));
    }

    return {
      'reasons': reasons.take(3).toList(),
      'overall_score': hasHistory ? 0.92 : 0.85,
      'weight_source': hasHistory ? 'history' : 'estimated',
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getGoalAlignmentReasonMap(TrainingGoal goal, String pattern) {
    final goalReasons = {
      TrainingGoal.strength: {
        'explanation': 'Heavy compound movement optimal for maximal strength gains',
        'explanation_ko': '최대 근력 향상에 최적화된 고중량 복합 운동',
      },
      TrainingGoal.hypertrophy: {
        'explanation': 'Time under tension promotes muscle hypertrophy',
        'explanation_ko': '근육 성장을 촉진하는 긴장 시간 확보',
      },
      TrainingGoal.endurance: {
        'explanation': 'High rep range builds muscular endurance',
        'explanation_ko': '고반복으로 근지구력 향상',
      },
      TrainingGoal.weightLoss: {
        'explanation': 'Compound movements maximize caloric expenditure',
        'explanation_ko': '복합 운동으로 칼로리 소모 극대화',
      },
      TrainingGoal.generalFitness: {
        'explanation': 'Balanced training for overall fitness improvement',
        'explanation_ko': '전반적인 체력 향상을 위한 균형 잡힌 훈련',
      },
      TrainingGoal.rehabilitation: {
        'explanation': 'Controlled movement for safe recovery',
        'explanation_ko': '안전한 회복을 위한 통제된 동작',
      },
      TrainingGoal.athletic: {
        'explanation': 'Explosive power development for athletic performance',
        'explanation_ko': '운동 능력 향상을 위한 폭발적 파워 개발',
      },
    };

    final reason = goalReasons[goal] ?? {
      'explanation': 'Selected for goal alignment',
      'explanation_ko': '목표에 적합한 운동',
    };

    return {
      'category': 'goal_alignment',
      'explanation': reason['explanation'],
      'explanation_ko': reason['explanation_ko'],
      'confidence': 0.90,
    };
  }

  Map<String, dynamic> _getMovementPatternReasonMap(String pattern) {
    final patternReasons = {
      'horizontal_push': {
        'explanation': 'Develops chest and anterior deltoid strength',
        'explanation_ko': '가슴과 전면 어깨 근력 발달',
      },
      'horizontal_pull': {
        'explanation': 'Strengthens back muscles and improves posture',
        'explanation_ko': '등 근력 강화 및 자세 개선',
      },
      'vertical_push': {
        'explanation': 'Builds shoulder stability and overhead strength',
        'explanation_ko': '어깨 안정성 및 오버헤드 근력 향상',
      },
      'vertical_pull': {
        'explanation': 'Develops lat width and upper back strength',
        'explanation_ko': '광배근 발달 및 상부 등 근력 강화',
      },
      'squat': {
        'explanation': 'Fundamental lower body compound for leg development',
        'explanation_ko': '하체 발달을 위한 기본 복합 운동',
      },
      'hinge': {
        'explanation': 'Targets posterior chain - glutes and hamstrings',
        'explanation_ko': '둔근과 햄스트링 등 후면 사슬 타겟',
      },
      'carry': {
        'explanation': 'Builds core stability and grip strength',
        'explanation_ko': '코어 안정성 및 악력 강화',
      },
      'rotation': {
        'explanation': 'Develops rotational power and core strength',
        'explanation_ko': '회전력 및 코어 근력 발달',
      },
    };

    final reason = patternReasons[pattern] ?? {
      'explanation': 'Effective movement for muscle activation',
      'explanation_ko': '근육 활성화에 효과적인 동작',
    };

    return {
      'category': 'history_based',
      'explanation': reason['explanation'],
      'explanation_ko': reason['explanation_ko'],
      'confidence': 0.85,
    };
  }

  Map<String, dynamic> _getEquipmentReasonMap(String equipment) {
    final equipmentReasons = {
      'barbell': {
        'explanation': 'Allows heavy loading for maximal strength development',
        'explanation_ko': '최대 근력 발달을 위한 고중량 가능',
      },
      'dumbbell': {
        'explanation': 'Provides unilateral training and range of motion',
        'explanation_ko': '단측 훈련 및 넓은 가동 범위 제공',
      },
      'cable': {
        'explanation': 'Constant tension throughout the movement',
        'explanation_ko': '동작 전 과정에서 일정한 장력 유지',
      },
      'machine': {
        'explanation': 'Guided movement pattern for safety and isolation',
        'explanation_ko': '안전하고 고립된 가이드 동작',
      },
      'kettlebell': {
        'explanation': 'Dynamic loading for power and conditioning',
        'explanation_ko': '파워 및 컨디셔닝을 위한 동적 부하',
      },
      'band': {
        'explanation': 'Variable resistance for accommodating strength curve',
        'explanation_ko': '근력 곡선에 맞는 가변 저항',
      },
    };

    final reason = equipmentReasons[equipment] ?? {
      'explanation': 'Equipment suitable for exercise execution',
      'explanation_ko': '운동 수행에 적합한 장비',
    };

    return {
      'category': 'equipment',
      'explanation': reason['explanation'],
      'explanation_ko': reason['explanation_ko'],
      'confidence': 0.80,
    };
  }

  Map<String, dynamic> _getSetsRepsForGoal(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return {'sets': 5, 'reps': '3-5', 'rpe': 8, 'rest': 180};
      case TrainingGoal.hypertrophy:
        return {'sets': 4, 'reps': '8-12', 'rpe': 7, 'rest': 90};
      case TrainingGoal.endurance:
        return {'sets': 3, 'reps': '15-20', 'rpe': 6, 'rest': 60};
      case TrainingGoal.weightLoss:
        return {'sets': 3, 'reps': '12-15', 'rpe': 7, 'rest': 45};
      case TrainingGoal.generalFitness:
        return {'sets': 3, 'reps': '10-12', 'rpe': 7, 'rest': 60};
      case TrainingGoal.rehabilitation:
        return {'sets': 2, 'reps': '12-15', 'rpe': 5, 'rest': 90};
      case TrainingGoal.athletic:
        return {'sets': 4, 'reps': '6-8', 'rpe': 8, 'rest': 120};
    }
  }

  /// Calculate target weight based on exercise history or estimate for new exercises
  /// Returns null for bodyweight exercises or when estimation isn't applicable
  double? _calculateTargetWeight({
    required String exerciseId,
    required Map<String, dynamic> exercise,
    required TrainingGoal goal,
    required Map<String, Map<String, dynamic>> exerciseHistory,
    required String targetReps,
  }) {
    final equipment = exercise['equipment'] as String? ?? '';
    final category = exercise['category'] as String? ?? '';
    final pattern = exercise['movement_pattern'] as String? ?? '';

    // Skip weight for bodyweight, cardio, and mobility exercises
    if (equipment == 'bodyweight' ||
        category == 'cardio' ||
        category == 'mobility' ||
        category == 'warmup' ||
        category == 'cooldown') {
      return null;
    }

    // Check if we have history for this exercise
    if (exerciseHistory.containsKey(exerciseId)) {
      final history = exerciseHistory[exerciseId]!;
      final lastWeight = history['lastWeight'] as double? ?? 0;
      final avgRpe = history['avgRpe'] as double?;

      if (lastWeight > 0) {
        // Apply progressive overload based on goal and previous RPE
        double progressionFactor = 1.0;

        // If previous RPE was too easy (< 6), suggest weight increase
        // If previous RPE was too hard (> 8), suggest same or slight decrease
        if (avgRpe != null) {
          if (avgRpe < 6) {
            progressionFactor = 1.05; // +5% for easy sessions
          } else if (avgRpe > 8) {
            progressionFactor = 0.98; // -2% for hard sessions
          } else {
            progressionFactor = 1.025; // +2.5% for appropriate challenge
          }
        } else {
          // No RPE data, apply small progression based on goal
          progressionFactor = goal == TrainingGoal.strength ? 1.025 : 1.0;
        }

        // Round to nearest 2.5kg for practical loading
        final calculatedWeight = lastWeight * progressionFactor;
        return (calculatedWeight / 2.5).round() * 2.5;
      }
    }

    // No history - estimate based on exercise type, pattern, and equipment
    return _estimateDefaultWeight(
      pattern: pattern,
      equipment: equipment,
      category: category,
      goal: goal,
    );
  }

  /// Estimate default weight for exercises without history
  /// Based on typical beginner-intermediate weights for each exercise type
  double? _estimateDefaultWeight({
    required String pattern,
    required String equipment,
    required String category,
    required TrainingGoal goal,
  }) {
    // Base weights by movement pattern (in kg) for intermediate level
    final Map<String, double> baseWeights = {
      // Compound movements
      'squat': 40.0,
      'hinge': 50.0, // Deadlift variations
      'horizontal_push': 30.0, // Bench press variations
      'horizontal_pull': 35.0, // Row variations
      'vertical_push': 20.0, // Overhead press
      'vertical_pull': 30.0, // Pulldown/Pull-up (assisted)
      // Isolation
      'isolation': 10.0,
      'carry': 20.0,
      'rotation': 8.0,
    };

    // Get base weight for pattern
    double? baseWeight = baseWeights[pattern];
    if (baseWeight == null) {
      // Fallback based on category
      if (category == 'isolation') {
        baseWeight = 10.0;
      } else if (category == 'compound') {
        baseWeight = 30.0;
      } else {
        return null; // Can't estimate
      }
    }

    // Equipment adjustment factor
    double equipmentFactor = 1.0;
    switch (equipment) {
      case 'barbell':
        equipmentFactor = 1.0; // Base is calibrated for barbell
        break;
      case 'dumbbell':
        equipmentFactor = 0.4; // Per dumbbell is roughly 40% of barbell
        break;
      case 'kettlebell':
        equipmentFactor = 0.35;
        break;
      case 'cable':
        equipmentFactor = 0.6;
        break;
      case 'machine':
        equipmentFactor = 0.8;
        break;
      case 'smith':
        equipmentFactor = 0.9;
        break;
      case 'band':
        return null; // Band resistance varies too much
      default:
        equipmentFactor = 0.5;
    }

    // Goal adjustment - lighter for endurance/rehab, heavier for strength
    double goalFactor = 1.0;
    switch (goal) {
      case TrainingGoal.strength:
        goalFactor = 1.2; // Start heavier for strength focus
        break;
      case TrainingGoal.hypertrophy:
        goalFactor = 1.0;
        break;
      case TrainingGoal.endurance:
        goalFactor = 0.7; // Lighter for high reps
        break;
      case TrainingGoal.weightLoss:
        goalFactor = 0.8;
        break;
      case TrainingGoal.generalFitness:
        goalFactor = 0.9;
        break;
      case TrainingGoal.rehabilitation:
        goalFactor = 0.5; // Much lighter for rehab
        break;
      case TrainingGoal.athletic:
        goalFactor = 1.0;
        break;
    }

    // Calculate and round to nearest 2.5kg
    final calculatedWeight = baseWeight * equipmentFactor * goalFactor;
    return (calculatedWeight / 2.5).round() * 2.5;
  }

  String _generateProgramName(TrainingGoal goal, int weeks) {
    return '${goal.nameKo} $weeks주 프로그램';
  }

  String _generateProgramDescription(TrainingGoal goal, int sessionsPerWeek) {
    return '주 $sessionsPerWeek회 ${goal.nameKo} 훈련 프로그램';
  }

  String _generateSessionName(TrainingGoal goal) {
    final date = DateTime.now();
    final formattedDate = '${date.month}/${date.day}';
    return '${goal.nameKo} 세션 ($formattedDate)';
  }

  String _generateSessionDescription(TrainingGoal goal) {
    return '${goal.nameKo} 목표 AI 생성 훈련 세션';
  }

  String _getGoalAlignmentReason(
    Map<String, dynamic> exercise,
    TrainingGoal goal,
  ) {
    final name = exercise['name'] as String;
    switch (goal) {
      case TrainingGoal.strength:
        return 'Optimal compound movement for building maximal strength';
      case TrainingGoal.hypertrophy:
        return 'Effective for muscle growth with appropriate time under tension';
      case TrainingGoal.endurance:
        return 'Suitable for high-rep endurance training';
      default:
        return 'Well-suited for $name development';
    }
  }

  String _getGoalAlignmentReasonKo(
    Map<String, dynamic> exercise,
    TrainingGoal goal,
  ) {
    switch (goal) {
      case TrainingGoal.strength:
        return '최대 근력 향상을 위한 최적의 복합 동작';
      case TrainingGoal.hypertrophy:
        return '적절한 근육 긴장 시간으로 근비대에 효과적';
      case TrainingGoal.endurance:
        return '고반복 지구력 훈련에 적합';
      default:
        return '목표 달성에 적합한 운동';
    }
  }
}
