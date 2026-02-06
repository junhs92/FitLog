import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../models/workout_program_model.dart';
import '../models/session_feedback_model.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/alternative_exercise.dart';

/// Client profile data for AI exercise generation
class ClientProfile {
  final String id;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final List<String> fitnessGoals;

  ClientProfile({
    required this.id,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fitnessGoals = const [],
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      fitnessGoals: (json['fitness_goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Exercise familiarity data for a client
class ExerciseFamiliarity {
  final String exerciseId;
  final int timesPerformed;
  final double? averageRpe;
  final double? bestWeight;
  final int? bestReps;
  final double familiarityScore;
  final bool isMastered;
  final bool needsCoaching;
  final DateTime? lastPerformedAt;

  ExerciseFamiliarity({
    required this.exerciseId,
    this.timesPerformed = 0,
    this.averageRpe,
    this.bestWeight,
    this.bestReps,
    this.familiarityScore = 0.0,
    this.isMastered = false,
    this.needsCoaching = false,
    this.lastPerformedAt,
  });

  factory ExerciseFamiliarity.fromJson(Map<String, dynamic> json) {
    return ExerciseFamiliarity(
      exerciseId: json['exercise_id'] as String,
      timesPerformed: json['times_performed'] as int? ?? 0,
      averageRpe: (json['average_rpe'] as num?)?.toDouble(),
      bestWeight: (json['best_weight'] as num?)?.toDouble(),
      bestReps: json['best_reps'] as int?,
      familiarityScore: (json['familiarity_score'] as num?)?.toDouble() ?? 0.0,
      isMastered: json['is_mastered'] as bool? ?? false,
      needsCoaching: json['needs_coaching'] as bool? ?? false,
      lastPerformedAt: json['last_performed_at'] != null
          ? DateTime.parse(json['last_performed_at'] as String)
          : null,
    );
  }
}

/// Internal class for tracking exercise history
class _ExerciseHistory {
  final String exerciseId;
  int sessionCount;
  int totalSets;
  double? lastWeight;
  int? lastReps;
  List<String> recentFeedback;

  _ExerciseHistory({
    required this.exerciseId,
    this.sessionCount = 0,
    this.totalSets = 0,
    this.lastWeight,
    this.lastReps,
    List<String>? recentFeedback,
  }) : recentFeedback = recentFeedback ?? [];
}

/// Internal class for scored exercise selection
class _ScoredExercise {
  final Map<String, dynamic> exercise;
  final double score;
  final ExerciseFamiliarity? familiarity;
  final _ExerciseHistory? history;

  _ScoredExercise({
    required this.exercise,
    required this.score,
    this.familiarity,
    this.history,
  });
}

/// Remote datasource for AI workout operations
/// PRD-compliant: Uses client profile, history, and familiarity for exercise generation
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

  /// Fetch client profile data for AI exercise generation
  /// PRD: Uses client data to personalize exercise selection
  Future<ClientProfile> getClientProfile(String clientId) async {
    debugPrint('🤖 [AI] Fetching client profile: $clientId');

    final response = await _client
        .from('accounts')
        .select(
            'id, full_name, date_of_birth, gender, height_cm, weight_kg, fitness_goals')
        .eq('id', clientId)
        .single();

    final profile = ClientProfile.fromJson(response);
    debugPrint('🤖 [AI] Client: ${profile.fullName}, Age: ${profile.age}, '
        'Weight: ${profile.weightKg}kg, Goals: ${profile.fitnessGoals}');

    return profile;
  }

  /// Fetch client's exercise familiarity data
  /// PRD: "Consistent squat performance over 12 sessions"
  Future<Map<String, ExerciseFamiliarity>> getClientExerciseFamiliarity(
      String clientId) async {
    debugPrint('🤖 [AI] Fetching exercise familiarity for client: $clientId');

    final response = await _client
        .from('client_exercise_familiarity')
        .select()
        .eq('client_id', clientId);

    final familiarityMap = <String, ExerciseFamiliarity>{};
    for (final item in response as List) {
      final familiarity =
          ExerciseFamiliarity.fromJson(item as Map<String, dynamic>);
      familiarityMap[familiarity.exerciseId] = familiarity;
    }

    debugPrint('🤖 [AI] Found familiarity data for ${familiarityMap.length} exercises');
    return familiarityMap;
  }

  /// Fetch client's recent session history for exercise performance context
  /// PRD: Uses history for "Client history" reasoning category
  Future<Map<String, _ExerciseHistory>> _getClientExerciseHistory(
      String clientId) async {
    debugPrint('🤖 [AI] Fetching exercise history for client: $clientId');

    // Get recent sessions for this client (last 30 days)
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    // Query completed sessions and their exercises
    // Filter by session's completed_at, not exercise's completed_at
    final response = await _client
        .from('session_exercises')
        .select('''
          exercise_id,
          sets,
          difficulty_feedback,
          sessions!inner(client_id, status, completed_at)
        ''')
        .eq('sessions.client_id', clientId)
        .eq('sessions.status', 'completed')
        .gte('sessions.completed_at', thirtyDaysAgo);

    debugPrint('🤖 [AI] Raw history response: ${(response as List).length} records');

    final historyMap = <String, _ExerciseHistory>{};

    for (final item in response) {
      final exerciseId = item['exercise_id'] as String;
      final sets = item['sets'] as List<dynamic>? ?? [];
      final feedback = item['difficulty_feedback'] as String?;

      if (!historyMap.containsKey(exerciseId)) {
        historyMap[exerciseId] = _ExerciseHistory(
          exerciseId: exerciseId,
          sessionCount: 0,
          totalSets: 0,
          lastWeight: null,
          lastReps: null,
          recentFeedback: [],
        );
      }

      final history = historyMap[exerciseId]!;
      history.sessionCount++;
      history.totalSets += sets.length;

      // Extract last weight and reps from most recent set
      if (sets.isNotEmpty && history.lastWeight == null) {
        final lastSet = sets.last as Map<String, dynamic>;
        history.lastWeight = (lastSet['weight'] as num?)?.toDouble();
        history.lastReps = lastSet['reps'] as int?;
      }

      if (feedback != null) {
        history.recentFeedback.add(feedback);
      }
    }

    debugPrint('🤖 [AI] Found history for ${historyMap.length} exercises');
    return historyMap;
  }

  /// Create a new training program (direction with client preferences)
  /// Programs store client preferences for AI exercise selection
  /// Fitness goals come from client's account (accounts.fitness_goals)
  Future<WorkoutProgramModel> createProgram({
    required String clientId,
    required String trainerId,
    required String name,
    String? description,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    // Get account ID if trainerId is empty
    final actualTrainerId = trainerId.isNotEmpty
        ? trainerId
        : await _getCurrentAccountId();

    // Default expiration to 3 months from now
    final expiresAt = DateTime.now().add(const Duration(days: 90));

    final programData = {
      'client_id': clientId,
      'trainer_id': actualTrainerId,
      'name': name,
      'description': description,
      'training_split': trainingSplit.id,
      'focus_areas': focusAreas ?? [],
      'preferred_movement_groups': preferredMovementGroups ?? [],
      'status': ProgramStatus.active.id,
      'expires_at': expiresAt.toIso8601String(),
      'is_ai_generated': true,
      'ai_model_version': 'preferences-v1',
    };

    final response = await _client
        .from('workout_programs')
        .insert(programData)
        .select()
        .single();

    return WorkoutProgramModel.fromJson(response);
  }

  /// Get a workout program by ID
  Future<WorkoutProgramModel> getProgram(String programId) async {
    final response = await _client
        .from('workout_programs')
        .select()
        .eq('id', programId)
        .single();

    return WorkoutProgramModel.fromJson(response);
  }

  /// Get all programs for a client
  Future<List<WorkoutProgramModel>> getClientPrograms(String clientId) async {
    final response = await _client
        .from('workout_programs')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => WorkoutProgramModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get active program for a client
  Future<WorkoutProgramModel?> getActiveProgram(String clientId) async {
    debugPrint('🔍 [getActiveProgram] Querying for clientId: $clientId, status: ${ProgramStatus.active.id}');
    final response = await _client
        .from('workout_programs')
        .select()
        .eq('client_id', clientId)
        .eq('status', ProgramStatus.active.id)
        .maybeSingle();

    debugPrint('🔍 [getActiveProgram] Response: ${response == null ? 'null' : response['id']}');
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
      updates['started_at'] = nowLocalIso8601();
    } else if (status == ProgramStatus.completed) {
      updates['completed_at'] = nowLocalIso8601();
    }

    await _client
        .from('workout_programs')
        .update(updates)
        .eq('id', programId);
  }

  /// Update program preferences (split, focus areas, movement patterns)
  Future<WorkoutProgramModel> updateProgram({
    required String programId,
    String? name,
    String? description,
    TrainingSplit? trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': nowLocalIso8601(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (trainingSplit != null) updates['training_split'] = trainingSplit.id;
    if (focusAreas != null) updates['focus_areas'] = focusAreas;
    if (preferredMovementGroups != null) {
      updates['preferred_movement_groups'] = preferredMovementGroups;
    }

    final response = await _client
        .from('workout_programs')
        .update(updates)
        .eq('id', programId)
        .select()
        .single();

    return WorkoutProgramModel.fromJson(response);
  }

  /// Update program's lastSessionFocus after session completion
  Future<void> updateProgramLastSessionFocus({
    required String programId,
    required String lastSessionFocus,
  }) async {
    debugPrint('🟣 [DATASOURCE] updateProgramLastSessionFocus: programId=$programId, focus=$lastSessionFocus');
    try {
      await _client
          .from('workout_programs')
          .update({
            'last_session_focus': lastSessionFocus,
            'updated_at': nowLocalIso8601(),
          })
          .eq('id', programId);
      debugPrint('🟣 [DATASOURCE] updateProgramLastSessionFocus: SUCCESS');
    } catch (e) {
      debugPrint('🔴 [DATASOURCE] updateProgramLastSessionFocus: ERROR - $e');
      rethrow;
    }
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

    // Movement group reasoning
    reasons.add(AIReasoningPoint(
      category: ReasoningCategory.progressiveOverload,
      explanation: 'Fits progression plan for ${exercise['movement_group']} group',
      explanationKo: '${exercise['movement_group']} 그룹 진행 계획에 적합',
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
      'timestamp': nowLocalIso8601(),
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
  /// PRD: Prioritize muscle_group match, then movement_pattern for biomechanical similarity
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

    final movementGroup = exercise['movement_group'] as String?;
    final muscleGroup = exercise['muscle_group'] as String?;

    debugPrint('🔄 [AI] Getting alternatives for exercise: $exerciseId');
    debugPrint('🔄 [AI] Original - muscleGroup: $muscleGroup, movementGroup: $movementGroup');

    List<Map<String, dynamic>> results = [];

    // Step 1: Try to find exercises matching BOTH muscle_group AND movement_group
    if (muscleGroup != null && movementGroup != null) {
      var query = _client
          .from('exercises')
          .select()
          .eq('muscle_group', muscleGroup)
          .eq('movement_group', movementGroup)
          .neq('id', exerciseId);

      query = _applyDifficultyFilter(query, feedback);
      final bothResults = await query.limit(5);
      results = List<Map<String, dynamic>>.from(bothResults as List);
      debugPrint('🔄 [AI] Step 1 (both match): found ${results.length} exercises');
    }

    // Step 2: If not enough results, try muscle_group only
    if (results.length < 3 && muscleGroup != null) {
      var query = _client
          .from('exercises')
          .select()
          .eq('muscle_group', muscleGroup)
          .neq('id', exerciseId);

      query = _applyDifficultyFilter(query, feedback);
      final muscleResults = await query.limit(5);

      // Add unique results
      for (final r in muscleResults as List) {
        final rMap = r as Map<String, dynamic>;
        if (!results.any((e) => e['id'] == rMap['id'])) {
          results.add(rMap);
        }
      }
      debugPrint('🔄 [AI] Step 2 (muscle_group only): total ${results.length} exercises');
    }

    // Note: No Step 3 fallback - we only recommend exercises with matching muscle_group
    // to avoid cross-muscle-group recommendations (e.g., Ab Wheel for Tricep Kickback)

    // Take top 5
    results = results.take(5).toList();

    // Map to SessionAlternativeModel with dynamic reasons
    return results.asMap().entries.map((entry) {
      final alt = entry.value;
      final isFirst = entry.key == 0;
      final altMuscle = alt['muscle_group'] as String?;
      final altGroup = alt['movement_group'] as String?;

      String reason;
      String reasonKo;
      AlternativeType type;

      if (feedback == DifficultyFeedback.struggling) {
        type = AlternativeType.easier;
        if (altMuscle == muscleGroup && altGroup == movementGroup) {
          reason = 'Same muscle group and movement group';
          reasonKo = '동일 근육군, 동일 움직임 그룹';
        } else {
          reason = 'Same muscle group, easier variation';
          reasonKo = '동일 근육군, 쉬운 변형';
        }
      } else {
        type = AlternativeType.harder;
        if (altMuscle == muscleGroup && altGroup == movementGroup) {
          reason = 'Same muscle group, increased challenge';
          reasonKo = '동일 근육군, 강도 증가';
        } else {
          reason = 'Same muscle group, harder variation';
          reasonKo = '동일 근육군, 어려운 변형';
        }
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

  /// Helper method to apply difficulty filter based on feedback
  /// Now includes same-level exercises in addition to easier/harder options
  PostgrestFilterBuilder<T> _applyDifficultyFilter<T>(
    PostgrestFilterBuilder<T> query,
    DifficultyFeedback feedback,
  ) {
    // Show all difficulty levels to include same-level alternatives
    // The UI will differentiate by showing difficulty badges
    return query;
  }

  /// Get similar exercises based on movement group for exercise swapping
  /// Returns up to 6 exercises with the same movement group
  Future<List<Map<String, dynamic>>> getSimilarExercises({
    required String exerciseId,
    int limit = 6,
  }) async {
    debugPrint('🤖 [AI] Fetching similar exercises for: $exerciseId');

    // First, get the original exercise to find its movement group
    final originalExercise = await _client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .single();

    final movementGroup = originalExercise['movement_group'] as String?;
    final muscleGroup = originalExercise['muscle_group'] as String?;

    debugPrint('🤖 [AI] Original exercise - Group: $movementGroup, MuscleGroup: $muscleGroup');

    // Query exercises with same movement group (excluding the original)
    var query = _client
        .from('exercises')
        .select()
        .neq('id', exerciseId);

    // Prioritize same movement group
    if (movementGroup != null && movementGroup.isNotEmpty) {
      query = query.eq('movement_group', movementGroup);
    } else if (muscleGroup != null && muscleGroup.isNotEmpty) {
      // Fallback to same muscle group if no movement group
      query = query.eq('muscle_group', muscleGroup);
    }

    final results = await query.limit(limit);
    final resultsList = results as List;

    debugPrint('🤖 [AI] Found ${resultsList.length} similar exercises');

    // If not enough results, also fetch by muscle group as secondary
    if (resultsList.length < limit && muscleGroup != null) {
      final additionalNeeded = limit - resultsList.length;
      final existingIds = resultsList.map((e) => e['id'] as String).toList();
      existingIds.add(exerciseId);

      final additionalResults = await _client
          .from('exercises')
          .select()
          .eq('muscle_group', muscleGroup)
          .not('id', 'in', existingIds)
          .limit(additionalNeeded);

      resultsList.addAll(additionalResults as List);
      debugPrint('🤖 [AI] Added ${(additionalResults as List).length} additional exercises by muscle group');
    }

    return resultsList.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Get alternative exercises grouped by equipment and pattern
  /// Returns exercises with:
  /// 1. Same movement_group + movement_detail, different equipment (equipment alternatives)
  /// 2. Same movement_group + movement_detail, same equipment (pattern alternatives)
  Future<AlternativeExercisesResult> getAlternativeExercises({
    required String exerciseId,
  }) async {
    debugPrint('🔄 [AI] getAlternativeExercises for: $exerciseId');

    // Step 1: Get original exercise details
    final originalExercise = await _client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .single();

    final movementGroup = originalExercise['movement_group'] as String?;
    final movementDetail = originalExercise['movement_detail'] as String?;
    final originalEquipment = originalExercise['equipment'] as String?;

    debugPrint('🔄 [AI] Original: group=$movementGroup, detail=$movementDetail, equipment=$originalEquipment');

    // If no movement group/detail, return empty result
    if (movementGroup == null || movementGroup.isEmpty) {
      debugPrint('🔄 [AI] No movement group, returning empty result');
      return AlternativeExercisesResult.empty();
    }

    // Step 2: Query for equipment alternatives (same pattern, different equipment)
    var equipmentQuery = _client
        .from('exercises')
        .select()
        .eq('movement_group', movementGroup)
        .neq('id', exerciseId);

    if (movementDetail != null && movementDetail.isNotEmpty) {
      equipmentQuery = equipmentQuery.eq('movement_detail', movementDetail);
    }

    if (originalEquipment != null && originalEquipment.isNotEmpty) {
      equipmentQuery = equipmentQuery.neq('equipment', originalEquipment);
    }

    final equipmentResults = await equipmentQuery.limit(20);
    debugPrint('🔄 [AI] Equipment alternatives found: ${(equipmentResults as List).length}');

    // Step 3: Query for pattern alternatives (same pattern, same equipment)
    List<dynamic> patternResults = [];
    if (originalEquipment != null && originalEquipment.isNotEmpty) {
      var patternQuery = _client
          .from('exercises')
          .select()
          .eq('movement_group', movementGroup)
          .eq('equipment', originalEquipment)
          .neq('id', exerciseId);

      if (movementDetail != null && movementDetail.isNotEmpty) {
        patternQuery = patternQuery.eq('movement_detail', movementDetail);
      }

      patternResults = await patternQuery.limit(10);
      debugPrint('🔄 [AI] Pattern alternatives found: ${patternResults.length}');
    }

    // Step 3b: Query for accessory exercises (isolation exercises in same movement_group)
    final accessoryQuery = _client
        .from('exercises')
        .select()
        .eq('movement_group', movementGroup)
        .eq('category', 'isolation')
        .neq('id', exerciseId);
    final accessoryResults = await accessoryQuery.limit(10);
    debugPrint('🔄 [AI] Accessory alternatives found: ${(accessoryResults as List).length}');

    // Step 4: Group equipment alternatives by equipment type
    final equipmentGroupsMap = <String, List<SessionAlternative>>{};
    for (final exercise in equipmentResults) {
      final ex = exercise as Map<String, dynamic>;
      final equipment = (ex['equipment'] as String?) ?? 'other';
      final equipmentLower = equipment.toLowerCase();

      equipmentGroupsMap.putIfAbsent(equipmentLower, () => []);
      equipmentGroupsMap[equipmentLower]!.add(SessionAlternative(
        exerciseId: ex['id'] as String,
        exerciseName: ex['name'] as String,
        exerciseNameKo: ex['name_ko'] as String?,
        type: AlternativeType.equipmentBased,
        reason: 'Same movement pattern with different equipment',
        reasonKo: '동일 패턴으로 장비 변경',
        isRecommended: equipmentGroupsMap[equipmentLower]!.isEmpty, // First in each group is recommended
      ));
    }

    // Convert to EquipmentGroup list and sort by equipment priority order
    final equipmentAlternatives = equipmentGroupsMap.entries.map((entry) {
      return EquipmentGroup(
        equipment: entry.key,
        equipmentLabel: EquipmentLabels.getLabel(entry.key),
        exercises: entry.value,
      );
    }).toList()
      ..sort((a, b) => EquipmentLabels.getPriorityIndex(a.equipment)
          .compareTo(EquipmentLabels.getPriorityIndex(b.equipment)));

    // Step 5: Map pattern alternatives
    final patternAlternatives = patternResults.asMap().entries.map((entry) {
      final ex = entry.value as Map<String, dynamic>;
      return SessionAlternative(
        exerciseId: ex['id'] as String,
        exerciseName: ex['name'] as String,
        exerciseNameKo: ex['name_ko'] as String?,
        type: AlternativeType.samePattern,
        reason: 'Same equipment, variation exercise',
        reasonKo: '같은 장비, 다른 변형',
        isRecommended: entry.key == 0, // First is recommended
      );
    }).toList();

    // Step 6: Map accessory alternatives
    final accessoryAlternatives = accessoryResults.asMap().entries.map((entry) {
      final ex = entry.value as Map<String, dynamic>;
      return SessionAlternative(
        exerciseId: ex['id'] as String,
        exerciseName: ex['name'] as String,
        exerciseNameKo: ex['name_ko'] as String?,
        type: AlternativeType.samePattern,
        reason: 'Isolation exercise in same movement group',
        reasonKo: '같은 패턴 고립 운동',
        isRecommended: entry.key == 0, // First is recommended
      );
    }).toList();

    debugPrint('🔄 [AI] Result: ${equipmentAlternatives.length} equipment groups, ${patternAlternatives.length} pattern alternatives, ${accessoryAlternatives.length} accessory exercises');

    return AlternativeExercisesResult(
      equipmentAlternatives: equipmentAlternatives,
      patternAlternatives: patternAlternatives,
      accessoryExercises: accessoryAlternatives,
    );
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
      'swapped_at': nowLocalIso8601(),
      'session_id': sessionId,
    });
  }

  /// Get swap history for a client
  Future<List<ExerciseSwapHistory>> getSwapHistory({
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

    return (results as List).map((e) {
      final json = e as Map<String, dynamic>;
      return ExerciseSwapHistory(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        trainerId: json['trainer_id'] as String,
        originalExerciseId: json['original_exercise_id'] as String,
        replacementExerciseId: json['replacement_exercise_id'] as String,
        feedbackReason: json['feedback_reason'] != null
            ? DifficultyFeedback.fromString(json['feedback_reason'] as String)
            : null,
        customReason: json['custom_reason'] as String?,
        swappedAt: DateTime.parse(json['swapped_at'] as String),
        sessionId: json['session_id'] as String?,
      );
    }).toList();
  }

  /// Generate exercises for a program by calling the AI edge function
  /// This calls the generate-workout edge function which uses OpenAI GPT-4
  /// Returns GeneratedSessionData with AI-recommended exercises
  /// Note: Edge function creates session record only, session_exercises are created when user confirms
  /// Goals come from client's account (accounts.fitness_goals), not from program
  Future<GeneratedSessionData> generateExercisesForProgram({
    required String clientId,
    required String programId,
    required String trainerId,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    debugPrint('🤖 [AI] ═══════════════════════════════════════════════════');
    debugPrint('🤖 [AI] CALLING AI EDGE FUNCTION FOR EXERCISE GENERATION');
    debugPrint('🤖 [AI] ═══════════════════════════════════════════════════');
    debugPrint('🤖 [AI] clientId: $clientId');
    debugPrint('🤖 [AI] programId: $programId');
    debugPrint('🤖 [AI] trainerId: $trainerId');
    debugPrint('🤖 [AI] trainingSplit: ${trainingSplit.id}');
    debugPrint('🤖 [AI] focusAreas: $focusAreas');
    debugPrint('🤖 [AI] preferredMovementGroups: $preferredMovementGroups');

    try {
      // Call the generate-workout edge function
      // Note: Edge function will fetch client's fitness goals from accounts table
      final response = await _client.functions.invoke(
        'generate-workout',
        body: {
          'clientId': clientId,
          'programId': programId,
          'trainerId': trainerId,
          'trainingSplit': trainingSplit.id,
          'focusAreas': focusAreas ?? [],
          'preferredMovementGroups': preferredMovementGroups ?? [],
        },
      );

      debugPrint('🤖 [AI] Edge function response status: ${response.status}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map ? errorData['error'] : 'Unknown error';
        debugPrint('🔴 [AI] Edge function error: $errorMessage');
        throw Exception('AI 운동 생성 실패: $errorMessage');
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('🤖 [AI] Received response: sessionId=${data['id']}');

      // Parse ai_recommendations from response
      // Edge function stores AI recommendations in ai_reasoning field and returns them in ai_recommendations
      final aiRecommendations = data['ai_recommendations'] as Map<String, dynamic>? ?? {};
      final recommendedExercises = aiRecommendations['exercises'] as List<dynamic>? ?? [];

      debugPrint('🤖 [AI] Received ${recommendedExercises.length} AI-recommended exercises');

      final exercises = <GeneratedProgramExercise>[];

      for (final exerciseData in recommendedExercises) {
        final exData = exerciseData as Map<String, dynamic>;

        // Parse AI reasoning from exercise data
        final aiReasoning = exData['aiReasoning'] as Map<String, dynamic>?;
        final reasons = aiReasoning?['reasons'] as List<dynamic>? ?? [];
        final historyConsideration = aiReasoning?['historyConsideration'] as String? ?? '';

        // Build reasoning string from reasons array
        final reasoningEn = reasons
            .map((r) => (r as Map<String, dynamic>)['explanation'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .join(' • ');
        final reasoningKo = reasons
            .map((r) => (r as Map<String, dynamic>)['explanationKo'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .join(' • ');

        exercises.add(GeneratedProgramExercise(
          exerciseId: exData['exerciseId'] as String,
          name: exData['exerciseName'] as String? ?? 'Unknown',
          nameKo: exData['exerciseName'] as String?, // Could add nameKo to edge function response
          orderIndex: exData['orderIndex'] as int? ?? exercises.length,
          targetSets: exData['targetSets'] as int? ?? 3,
          targetReps: exData['targetReps'] as String? ?? '10-12',
          targetRpe: exData['targetRpe'] as int?, // RPE from AI if prescribed
          restSeconds: exData['restSeconds'] as int? ?? 60,
          aiReasoning: reasoningEn.isNotEmpty ? reasoningEn : historyConsideration,
          aiReasoningKo: reasoningKo.isNotEmpty ? reasoningKo : historyConsideration,
        ));
      }

      debugPrint('🤖 [AI] ═══════════════════════════════════════════════════');
      debugPrint('🤖 [AI] AI GENERATED ${exercises.length} EXERCISES');
      debugPrint('🤖 [AI] ═══════════════════════════════════════════════════');

      // Get session description from AI recommendations
      final sessionDescription = aiRecommendations['sessionDescription'] as String? ??
          'AI-generated workout session based on your goals and history';

      return GeneratedSessionData(
        sessionId: data['id'] as String?,
        exercises: exercises,
        sessionDescription: sessionDescription,
        sessionDescriptionKo: sessionDescription,
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 [AI] Exception in generateExercisesForProgram: $e');
      debugPrint('🔴 [AI] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Helper to parse JSON string using dart:convert
  Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('🟡 [AI] JSON parse error: $e');
      return null;
    }
  }

  /// Generate session-level description explaining the workout strategy
  Map<String, String> _generateSessionDescription({
    required ClientProfile clientProfile,
    required TrainingGoal primaryGoal,
    required TrainingSplit trainingSplit,
    required List<GeneratedProgramExercise> exercises,
    required List<String> targetMuscleGroups,
  }) {
    final clientName = clientProfile.fullName ?? '고객';
    final goalNameKo = primaryGoal.nameKo;
    final goalNameEn = primaryGoal.name;
    final splitNameKo = trainingSplit.nameKo;
    final splitNameEn = trainingSplit.name;
    final exerciseCount = exercises.length;

    // Format muscle groups for display
    final muscleGroupsKo = targetMuscleGroups.map((mg) => _getMuscleGroupNameKo(mg)).join(', ');
    final muscleGroupsEn = targetMuscleGroups.join(', ');

    // Build Korean description
    final descriptionKo = StringBuffer();
    descriptionKo.write('${clientName}님의 $goalNameKo 목표에 맞춘 $splitNameKo 운동입니다. ');
    descriptionKo.write('$muscleGroupsKo을(를) 균형 있게 훈련하며, ');
    descriptionKo.write('총 $exerciseCount개의 운동으로 구성되었습니다.');

    // Build English description
    final descriptionEn = StringBuffer();
    descriptionEn.write('$splitNameEn workout tailored for ${clientName}\'s $goalNameEn goal. ');
    descriptionEn.write('Balanced training for $muscleGroupsEn, ');
    descriptionEn.write('consisting of $exerciseCount exercises.');

    return {
      'ko': descriptionKo.toString(),
      'en': descriptionEn.toString(),
    };
  }

  /// Get Korean name for muscle group
  String _getMuscleGroupNameKo(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'legs':
        return '하체';
      case 'core':
        return '코어';
      case 'biceps':
        return '이두';
      case 'triceps':
        return '삼두';
      case 'glutes':
        return '둔근';
      case 'hamstrings':
        return '햄스트링';
      case 'quadriceps':
        return '대퇴사두';
      case 'calves':
        return '종아리';
      case 'forearms':
        return '전완';
      case 'abs':
        return '복근';
      default:
        return muscleGroup;
    }
  }

  /// Score exercise based on client context (PRD: personalized selection)
  double _scoreExercise({
    required Map<String, dynamic> exercise,
    required TrainingGoal goal,
    required ClientProfile clientProfile,
    ExerciseFamiliarity? familiarity,
    _ExerciseHistory? history,
    required String targetDifficulty,
  }) {
    double score = 50.0; // Base score

    final exerciseDifficulty = exercise['difficulty'] as String? ?? 'intermediate';
    final category = exercise['category'] as String? ?? 'compound';

    // 1. Goal alignment (PRD: "Compound movement maximizes strength gains")
    if (goal == TrainingGoal.strength && category == 'compound') {
      score += 15.0;
    } else if (goal == TrainingGoal.hypertrophy) {
      score += 10.0; // All exercises good for hypertrophy
    } else if (goal == TrainingGoal.endurance && category == 'isolation') {
      score += 10.0;
    }

    // 2. Difficulty match
    if (exerciseDifficulty == targetDifficulty) {
      score += 20.0;
    } else if (_difficultyDistance(exerciseDifficulty, targetDifficulty) == 1) {
      score += 10.0;
    }

    // 3. Client familiarity (PRD: "Consistent performance over X sessions")
    if (familiarity != null) {
      if (familiarity.isMastered) {
        score += 15.0; // Mastered exercises = consistent performance
      } else if (familiarity.timesPerformed >= 5) {
        score += 10.0; // Familiar
      } else if (familiarity.needsCoaching) {
        score -= 10.0; // Needs more coaching, maybe skip
      }
    }

    // 4. Recent history performance
    if (history != null) {
      if (history.sessionCount >= 3) {
        score += 10.0; // Consistent recent usage

        // Check for struggling feedback
        final strugglingCount =
            history.recentFeedback.where((f) => f == 'struggling').length;
        if (strugglingCount > 1) {
          score -= 15.0; // Client struggled recently
        }
      }
    }

    // 5. Age-appropriate adjustments
    final age = clientProfile.age;
    if (age != null) {
      if (age >= 50 && exerciseDifficulty == 'advanced') {
        score -= 10.0; // Prefer safer exercises for older clients
      }
      if (age < 30 && exerciseDifficulty == 'beginner') {
        score -= 5.0; // Younger clients can handle more
      }
    }

    return score.clamp(0.0, 100.0);
  }

  /// Generate PRD-compliant reasoning with 3 categories
  /// PRD: Goal alignment, Client history, Movement groups
  Map<String, String> _generatePRDCompliantReasoning({
    required Map<String, dynamic> exercise,
    required TrainingGoal goal,
    required ClientProfile clientProfile,
    ExerciseFamiliarity? familiarity,
    _ExerciseHistory? history,
  }) {
    final muscleGroup = exercise['muscle_group'] as String;
    final movementGroup = exercise['movement_group'] as String? ?? 'other';
    final category = exercise['category'] as String? ?? 'compound';

    // Build reasoning points
    final reasonsEn = <String>[];
    final reasonsKo = <String>[];

    // 1. Goal Alignment (PRD requirement)
    final goalReason = _getGoalAlignmentReasonDetailed(goal, category, muscleGroup);
    reasonsEn.add(goalReason['en']!);
    reasonsKo.add(goalReason['ko']!);

    // 2. Client History (PRD: "Consistent squat performance over 12 sessions")
    if (history != null && history.sessionCount >= 3) {
      reasonsEn.add('Consistent performance over ${history.sessionCount} sessions');
      reasonsKo.add('${history.sessionCount}회 세션에서 일관된 수행');
    } else if (familiarity != null && familiarity.timesPerformed >= 5) {
      reasonsEn.add('Performed ${familiarity.timesPerformed} times with good form');
      reasonsKo.add('${familiarity.timesPerformed}회 수행, 좋은 폼 유지');
    } else {
      reasonsEn.add('Good progression exercise for building experience');
      reasonsKo.add('경험 쌓기에 좋은 진행 운동');
    }

    // 3. Movement Group (PRD: "Hip-dominant pattern for lower body balance")
    final groupReason = _getMovementGroupReason(movementGroup, muscleGroup);
    reasonsEn.add(groupReason['en']!);
    reasonsKo.add(groupReason['ko']!);

    return {
      'en': reasonsEn.join(' • '),
      'ko': reasonsKo.join(' • '),
    };
  }

  /// Get detailed goal alignment reason
  Map<String, String> _getGoalAlignmentReasonDetailed(
      TrainingGoal goal, String category, String muscleGroup) {
    switch (goal) {
      case TrainingGoal.strength:
        return {
          'en': category == 'compound'
              ? 'Compound movement maximizes strength gains'
              : 'Builds foundational $muscleGroup strength',
          'ko': category == 'compound'
              ? '복합 운동으로 최대 근력 향상'
              : '$muscleGroup 기초 근력 강화',
        };
      case TrainingGoal.hypertrophy:
        return {
          'en': 'Optimal time under tension for $muscleGroup growth',
          'ko': '$muscleGroup 성장을 위한 최적의 긴장 시간',
        };
      case TrainingGoal.endurance:
        return {
          'en': 'Suitable for high-rep $muscleGroup endurance',
          'ko': '$muscleGroup 고반복 지구력 훈련에 적합',
        };
      case TrainingGoal.weightLoss:
        return {
          'en': 'Engages multiple muscles to maximize caloric burn',
          'ko': '다중 근육 활성화로 칼로리 소모 극대화',
        };
      case TrainingGoal.generalFitness:
        return {
          'en': 'Balanced exercise for overall $muscleGroup fitness',
          'ko': '균형 잡힌 $muscleGroup 전반적 체력 향상',
        };
      case TrainingGoal.rehabilitation:
        return {
          'en': 'Controlled movement for safe $muscleGroup recovery',
          'ko': '안전한 $muscleGroup 회복을 위한 통제된 동작',
        };
      case TrainingGoal.athletic:
        return {
          'en': 'Develops explosive $muscleGroup power',
          'ko': '폭발적인 $muscleGroup 파워 개발',
        };
    }
  }

  /// Get movement group reason
  Map<String, String> _getMovementGroupReason(String group, String muscleGroup) {
    final groups = {
      'push': {
        'en': 'Push movement for chest, shoulder, and triceps development',
        'ko': '가슴, 어깨, 삼두근 발달을 위한 밀기 운동',
      },
      'pull': {
        'en': 'Pull movement for back and biceps synergy',
        'ko': '등과 이두근 시너지를 위한 당기기 운동',
      },
      'legs': {
        'en': 'Lower body movement for balanced leg development',
        'ko': '균형 잡힌 하체 발달을 위한 하체 운동',
      },
      'core': {
        'en': 'Core movement for trunk stability and strength',
        'ko': '코어 안정성과 근력을 위한 코어 운동',
      },
      'other': {
        'en': 'Targeted exercise for $muscleGroup focus',
        'ko': '$muscleGroup 집중을 위한 타겟 운동',
      },
    };

    return groups[group] ??
        {
          'en': 'Effective movement for $muscleGroup',
          'ko': '$muscleGroup에 효과적인 운동',
        };
  }

  /// Get target difficulty based on client profile
  String _getTargetDifficulty(
      ClientProfile profile, Map<String, ExerciseFamiliarity> familiarity) {
    // Calculate average familiarity score
    if (familiarity.isEmpty) {
      return 'beginner'; // New client
    }

    final avgFamiliarity = familiarity.values
            .map((f) => f.familiarityScore)
            .reduce((a, b) => a + b) /
        familiarity.length;

    // Consider age
    final age = profile.age ?? 30;
    final ageAdjustment = age > 50 ? -0.1 : (age < 25 ? 0.1 : 0);

    final adjustedScore = (avgFamiliarity + ageAdjustment).clamp(0.0, 1.0);

    if (adjustedScore >= 0.7) return 'advanced';
    if (adjustedScore >= 0.4) return 'intermediate';
    return 'beginner';
  }

  /// Calculate distance between difficulty levels
  int _difficultyDistance(String a, String b) {
    const levels = ['beginner', 'intermediate', 'advanced', 'expert'];
    final indexA = levels.indexOf(a);
    final indexB = levels.indexOf(b);
    if (indexA == -1 || indexB == -1) return 2;
    return (indexA - indexB).abs();
  }

  /// Get training scheme with client profile adjustments
  Map<String, dynamic> _getTrainingSchemeWithProfile(
      TrainingGoal goal, ClientProfile profile) {
    final baseScheme = _getTrainingScheme(goal);

    // Adjust based on age
    final age = profile.age;
    if (age != null && age >= 50) {
      // Reduce volume for older clients
      return {
        'sets': (baseScheme['sets'] as int) - 1,
        'reps': baseScheme['reps'],
        'rest': (baseScheme['rest'] as int) + 30, // More rest
      };
    }

    return baseScheme;
  }

  /// Get muscle groups to target based on training split
  List<String> _getMuscleGroupsForSplit(TrainingSplit split, List<String>? focusAreas) {
    // If custom focus areas provided, use them
    if (focusAreas != null && focusAreas.isNotEmpty) {
      return focusAreas;
    }

    // Default muscle groups based on split
    switch (split) {
      case TrainingSplit.fullBody:
        return ['chest', 'back', 'shoulders', 'legs', 'core'];
      case TrainingSplit.upperLower:
        return ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
      case TrainingSplit.pushPullLegs:
        return ['chest', 'shoulders', 'triceps'];
    }
  }

  /// Get training scheme (sets, reps, rest) based on goal
  Map<String, dynamic> _getTrainingScheme(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return {'sets': 5, 'reps': '3-5', 'rest': 180};
      case TrainingGoal.hypertrophy:
        return {'sets': 4, 'reps': '8-12', 'rest': 90};
      case TrainingGoal.endurance:
        return {'sets': 3, 'reps': '15-20', 'rest': 45};
      case TrainingGoal.weightLoss:
        return {'sets': 3, 'reps': '12-15', 'rest': 60};
      case TrainingGoal.generalFitness:
        return {'sets': 3, 'reps': '10-12', 'rest': 60};
      case TrainingGoal.rehabilitation:
        return {'sets': 2, 'reps': '12-15', 'rest': 90};
      case TrainingGoal.athletic:
        return {'sets': 4, 'reps': '6-8', 'rest': 120};
    }
  }

  /// Delete a program
  Future<void> deleteProgram(String programId) async {
    await _client.from('workout_programs').delete().eq('id', programId);
  }

  // Private helper methods

  String _getGoalAlignmentReason(
    Map<String, dynamic> exercise,
    TrainingGoal goal,
  ) {
    switch (goal) {
      case TrainingGoal.strength:
        return 'Optimal compound movement for building maximal strength';
      case TrainingGoal.hypertrophy:
        return 'Effective for muscle growth with appropriate time under tension';
      case TrainingGoal.endurance:
        return 'Suitable for high-rep endurance training';
      case TrainingGoal.weightLoss:
        return 'Compound movements maximize caloric expenditure';
      case TrainingGoal.generalFitness:
        return 'Balanced training for overall fitness improvement';
      case TrainingGoal.rehabilitation:
        return 'Controlled movement for safe recovery';
      case TrainingGoal.athletic:
        return 'Explosive power development for athletic performance';
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
      case TrainingGoal.weightLoss:
        return '복합 운동으로 칼로리 소모 극대화';
      case TrainingGoal.generalFitness:
        return '전반적인 체력 향상을 위한 균형 잡힌 훈련';
      case TrainingGoal.rehabilitation:
        return '안전한 회복을 위한 통제된 동작';
      case TrainingGoal.athletic:
        return '운동 능력 향상을 위한 폭발적 파워 개발';
    }
  }
}
