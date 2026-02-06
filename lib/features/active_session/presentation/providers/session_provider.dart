import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/result.dart';
import '../../data/datasources/session_remote_datasource.dart';
import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../data/models/session_exercise_input.dart';
import '../../data/models/user_preference_model.dart';
import '../../data/models/exercise_relation_model.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/set_comment.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import '../../domain/services/session_generation_service.dart';
import '../../domain/services/achievement_detection_service.dart';
import '../../domain/entities/generated_session.dart';
import '../../domain/entities/auto_achievement.dart';
import '../../domain/entities/detected_achievement.dart';
import '../../../client_management/presentation/providers/client_provider.dart';
import '../../../ai_workout/presentation/providers/ai_workout_provider.dart';
import '../../../ai_workout/domain/entities/workout_program.dart';

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for session remote datasource
final sessionRemoteDataSourceProvider = Provider<SessionRemoteDataSource>((ref) {
  return SessionRemoteDataSource(ref.read(supabaseClientProvider));
});

/// Provider for session repository
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(ref.read(sessionRemoteDataSourceProvider));
});

/// Provider for recommendation remote datasource
final recommendationRemoteDataSourceProvider = Provider<RecommendationRemoteDataSource>((ref) {
  return RecommendationRemoteDataSource(ref.read(supabaseClientProvider));
});

/// Provider for recommendation repository
final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(ref.read(recommendationRemoteDataSourceProvider));
});

/// Provider for recommendation weights (cached)
/// Fetches weights from database with fallback to defaults
final recommendationWeightsProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.read(recommendationRepositoryProvider);
  return repository.getWeightMapWithFallback();
});

/// Provider for user preferences (cached)
/// Fetches user's equipment & injury preferences for recommendation filtering
final userPreferencesProvider = FutureProvider<UserPreferenceModel?>((ref) async {
  final repository = ref.read(recommendationRepositoryProvider);
  final result = await repository.getUserPreferences();
  return result.fold((_) => null, (prefs) => prefs);
});

/// Provider for exercise relations (indexed by fromExerciseId)
/// Fetches all complementary and supplementary relations for recommendation boosting
final exerciseRelationsProvider = FutureProvider<Map<String, List<ExerciseRelationModel>>>((ref) async {
  final repository = ref.read(recommendationRepositoryProvider);

  // Fetch complementary and supplementary relations in parallel
  final complementaryFuture = repository.getRelationsByType(ExerciseRelationType.complementary);
  final supplementaryFuture = repository.getRelationsByType(ExerciseRelationType.supplementary);

  final results = await Future.wait([complementaryFuture, supplementaryFuture]);
  final complementary = results[0].fold((_) => <ExerciseRelationModel>[], (r) => r);
  final supplementary = results[1].fold((_) => <ExerciseRelationModel>[], (r) => r);

  // Index by fromExerciseId for O(1) lookup
  final map = <String, List<ExerciseRelationModel>>{};
  for (final r in [...complementary, ...supplementary]) {
    map.putIfAbsent(r.fromExerciseId, () => []).add(r);
  }

  debugPrint('🔵 [exerciseRelationsProvider] Loaded ${map.length} exercise relations');
  return map;
});

/// Current active session state
class ActiveSessionState {
  final SessionEntity? session;
  final int currentExerciseIndex;
  final bool isLoading;
  final String? error;

  // Current set being logged
  final double currentWeight;
  final int currentReps;
  final double? currentRpe;
  final List<SetTag> currentTags;
  final List<SetComment> currentComments;
  final Map<SetComment, String> currentCommentDetails;

  // Last logged set for "Repeat Last Set" feature
  final ExerciseSetEntity? lastLoggedSet;

  // Exercise history for PR display
  final ExerciseSetEntity? exercisePR;
  final List<ExerciseSetEntity> lastSessionSets;

  // Timer mode state (for isometric exercises)
  final bool isTimerMode;
  final Duration currentDuration;
  final Duration countdownRemaining;
  final bool isCountdownRunning;

  // Exercise-level comment persistence
  final Map<String, List<SetComment>> exerciseComments;
  final Map<String, Map<SetComment, String>> exerciseCommentDetails;

  const ActiveSessionState({
    this.session,
    this.currentExerciseIndex = 0,
    this.isLoading = false,
    this.error,
    this.currentWeight = 20.0,
    this.currentReps = 10,
    this.currentRpe = 7.0,
    this.currentTags = const [],
    this.currentComments = const [],
    this.currentCommentDetails = const {},
    this.lastLoggedSet,
    this.exercisePR,
    this.lastSessionSets = const [],
    this.isTimerMode = false,
    this.currentDuration = const Duration(seconds: 30),
    this.countdownRemaining = const Duration(seconds: 30),
    this.isCountdownRunning = false,
    this.exerciseComments = const {},
    this.exerciseCommentDetails = const {},
  });

  bool get hasActiveSession => session != null && session!.isInProgress;

  SessionExerciseEntity? get currentExercise {
    if (session == null || session!.exercises.isEmpty) return null;
    if (currentExerciseIndex >= session!.exercises.length) return null;
    return session!.exercises[currentExerciseIndex];
  }

  int get currentSetNumber {
    final exercise = currentExercise;
    if (exercise == null) return 1;
    return exercise.sets.length + 1;
  }

  /// Check if repeat last set is available
  bool get canRepeatLastSet {
    final exercise = currentExercise;
    if (exercise == null) return false;
    return exercise.sets.isNotEmpty;
  }

  /// Get last set of current exercise for repeat functionality
  ExerciseSetEntity? get lastSetOfCurrentExercise {
    final exercise = currentExercise;
    if (exercise == null || exercise.sets.isEmpty) return null;
    return exercise.sets.last;
  }

  ActiveSessionState copyWith({
    SessionEntity? session,
    int? currentExerciseIndex,
    bool? isLoading,
    String? error,
    double? currentWeight,
    int? currentReps,
    double? currentRpe,
    List<SetTag>? currentTags,
    List<SetComment>? currentComments,
    Map<SetComment, String>? currentCommentDetails,
    ExerciseSetEntity? lastLoggedSet,
    ExerciseSetEntity? exercisePR,
    bool clearExercisePR = false,
    List<ExerciseSetEntity>? lastSessionSets,
    bool? isTimerMode,
    Duration? currentDuration,
    Duration? countdownRemaining,
    bool? isCountdownRunning,
    Map<String, List<SetComment>>? exerciseComments,
    Map<String, Map<SetComment, String>>? exerciseCommentDetails,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentWeight: currentWeight ?? this.currentWeight,
      currentReps: currentReps ?? this.currentReps,
      currentRpe: currentRpe ?? this.currentRpe,
      currentTags: currentTags ?? this.currentTags,
      currentComments: currentComments ?? this.currentComments,
      currentCommentDetails: currentCommentDetails ?? this.currentCommentDetails,
      lastLoggedSet: lastLoggedSet ?? this.lastLoggedSet,
      exercisePR: clearExercisePR ? null : (exercisePR ?? this.exercisePR),
      lastSessionSets: lastSessionSets ?? this.lastSessionSets,
      isTimerMode: isTimerMode ?? this.isTimerMode,
      currentDuration: currentDuration ?? this.currentDuration,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
      isCountdownRunning: isCountdownRunning ?? this.isCountdownRunning,
      exerciseComments: exerciseComments ?? this.exerciseComments,
      exerciseCommentDetails: exerciseCommentDetails ?? this.exerciseCommentDetails,
    );
  }
}

/// Active session notifier
class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repository;
  final Ref _ref;
  Timer? _countdownTimer;

  ActiveSessionNotifier(this._repository, this._ref) : super(const ActiveSessionState());

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Initialize weight/reps/rpe from the first exercise's targets
  void _initializeFromFirstExercise(SessionEntity session) {
    if (session.exercises.isEmpty) return;

    final exercise = session.exercises[0];
    final exerciseEntity = exercise.exercise;

    // Priority: last set of this exercise > target from program > defaults
    double weight = 20.0;
    int reps = 10;
    double rpe = 7.0; // Default RPE to 7

    if (exercise.sets.isNotEmpty) {
      final lastSet = exercise.sets.last;
      weight = lastSet.weight ?? exercise.recommendedWeight;
      reps = lastSet.reps ?? exercise.recommendedReps;
    } else {
      weight = exercise.recommendedWeight;
      reps = exercise.recommendedReps;
      rpe = exercise.recommendedRpe ?? 7.0; // Use recommendation or default to 7
    }

    // For bodyweight exercises, default weight to 0
    if (exerciseEntity.isBodyweight) {
      weight = 0.0;
    }

    // Initialize timer mode based on exercise type
    final isTimerMode = exerciseEntity.isIsometric;
    final defaultDuration = Duration(seconds: exerciseEntity.defaultDurationSeconds);

    state = state.copyWith(
      currentWeight: weight,
      currentReps: reps,
      currentRpe: rpe,
      isTimerMode: isTimerMode,
      currentDuration: defaultDuration,
      countdownRemaining: defaultDuration,
      isCountdownRunning: false,
    );

    // Load exercise history for PR display
    _loadExerciseHistory(session.clientId, exercise.exercise.id);
  }

  /// Load exercise history and compute PR and last session sets
  Future<void> _loadExerciseHistory(String clientId, String exerciseId) async {
    final result = await _repository.getExerciseHistory(
      clientId: clientId,
      exerciseId: exerciseId,
      limit: 50, // Fetch more to find PR and last session
    );

    result.fold(
      (failure) {
        // On failure, clear history state
        state = state.copyWith(
          clearExercisePR: true,
          lastSessionSets: [],
        );
      },
      (history) {
        if (history.isEmpty) {
          state = state.copyWith(
            clearExercisePR: true,
            lastSessionSets: [],
          );
          return;
        }

        // Find PR (estimated 1RM using Epley formula: weight × (1 + reps/30))
        ExerciseSetEntity? pr;
        double maxEstimated1RM = 0;
        for (final set in history) {
          final weight = set.weight ?? 0;
          final reps = set.reps ?? 0;
          final estimated1RM = weight * (1 + reps / 30);
          if (estimated1RM > maxEstimated1RM) {
            maxEstimated1RM = estimated1RM;
            pr = set;
          }
        }

        // Find last session's sets (most recent session_exercise_id)
        final lastSessionId = history.first.sessionExerciseId;
        final lastSessionSets = history
            .where((s) => s.sessionExerciseId == lastSessionId)
            .toList();

        state = state.copyWith(
          exercisePR: pr,
          lastSessionSets: lastSessionSets,
        );
      },
    );
  }

  /// Start a new session
  /// Returns Result with session if successful, or failure
  /// If exercises are provided, they will be added to session_exercises
  /// If aiReasoning is provided, it will be saved as session-level AI description
  Future<Result<SessionEntity>> startSession({
    required String clientId,
    String? sessionType,
    String? programId,
    List<Map<String, dynamic>>? exercises,
    String? aiReasoning,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.startSession(
      clientId: clientId,
      sessionType: sessionType,
      programId: programId,
      exercises: exercises,
      aiReasoning: aiReasoning,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (session) {
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        _initializeFromFirstExercise(session);
      },
    );

    return result;
  }

  /// Start a new session with AI-generated exercises from a program direction
  /// Returns Result with session if successful, or failure
  /// Exercises should be passed directly (not fetched from DB)
  Future<Result<SessionEntity>> startSessionWithProgram({
    required String trainerId,
    required String clientId,
    required String programId,
    String? sessionType,
    List<Map<String, dynamic>>? exercises,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.startSession(
      clientId: clientId,
      sessionType: sessionType ?? 'training',
      programId: programId,
      exercises: exercises,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (session) {
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        _initializeFromFirstExercise(session);
      },
    );

    return result;
  }

  /// Activate an existing session (created by AI edge function)
  /// Updates status from 'scheduled' to 'active' and creates session_exercises
  /// If exercises list is provided, session_exercises will be created from it
  Future<Result<SessionEntity>> activateExistingSession({
    required String sessionId,
    required String clientId,
    List<Map<String, dynamic>>? exercises,
  }) async {
    debugPrint('🟢 [SESSION_PROVIDER] activateExistingSession: $sessionId');
    debugPrint('🟢 [SESSION_PROVIDER] exercises to create: ${exercises?.length ?? 0}');
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.activateSession(
      sessionId: sessionId,
      exercises: exercises,
    );

    result.fold(
      (failure) {
        debugPrint('🔴 [SESSION_PROVIDER] Activation failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (session) {
        debugPrint('🟢 [SESSION_PROVIDER] Session activated: ${session.id} with ${session.exercises.length} exercises');
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        _initializeFromFirstExercise(session);
      },
    );

    return result;
  }

  /// Unified session creation method (Template Pattern)
  ///
  /// Handles all 3 session start flows:
  /// - AI: [existingSessionId] provided → activate pre-created session
  /// - Previous: [exercises] provided → create new session with exercises
  /// - Empty: no exercises → create empty session for manual entry
  Future<Result<SessionEntity>> createSession({
    required String clientId,
    List<SessionExerciseInput>? exercises,
    String? programId,
    String? existingSessionId,
    String? aiReasoning,
  }) async {
    debugPrint('🟢 [SESSION_PROVIDER] createSession: Starting unified flow...');
    debugPrint('🟢 [SESSION_PROVIDER] clientId: $clientId, existingSessionId: $existingSessionId');
    debugPrint('🟢 [SESSION_PROVIDER] exercises: ${exercises?.length ?? 0}');
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createSession(
      clientId: clientId,
      exercises: exercises,
      programId: programId,
      existingSessionId: existingSessionId,
      aiReasoning: aiReasoning,
    );

    result.fold(
      (failure) {
        debugPrint('🔴 [SESSION_PROVIDER] createSession failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (session) {
        debugPrint('🟢 [SESSION_PROVIDER] Session created: ${session.id} with ${session.exercises.length} exercises');
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        _initializeFromFirstExercise(session);
      },
    );

    return result;
  }

  /// Load existing active session
  Future<void> loadActiveSession(String clientId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getActiveSession(clientId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (session) {
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        if (session != null) {
          _initializeFromFirstExercise(session);
        }
      },
    );
  }

  /// Add exercise to session
  Future<void> addExercise(ExerciseEntity exercise) async {
    if (state.session == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.addExerciseToSession(
      sessionId: state.session!.id,
      exercise: exercise,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (sessionExercise) {
        final updatedExercises = [
          ...state.session!.exercises,
          sessionExercise,
        ];
        final updatedSession = state.session!.copyWith(
          exercises: updatedExercises,
        );
        state = state.copyWith(
          session: updatedSession,
          isLoading: false,
        );
        // Navigate to the new exercise to properly initialize all state
        // (weight, reps, RPE, tags, comments, exercise history)
        goToExercise(updatedExercises.length - 1);
      },
    );
  }

  /// Swap current exercise with a new one
  Future<bool> swapExercise({
    required String newExerciseId,
  }) async {
    final currentExercise = state.currentExercise;
    if (state.session == null || currentExercise == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final currentIndex = state.currentExerciseIndex;

      // 1. Remove old exercise from session_exercises
      await _repository.removeExerciseFromSession(currentExercise.id);

      // 2. Add new exercise at same position
      final addResult = await _repository.addExerciseToSessionById(
        sessionId: state.session!.id,
        exerciseId: newExerciseId,
        order: currentIndex,
      );

      return addResult.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (newSessionExercise) {
          // 3. Update exercises list
          final updatedExercises =
              List<SessionExerciseEntity>.from(state.session!.exercises);
          updatedExercises[currentIndex] = newSessionExercise;

          final updatedSession =
              state.session!.copyWith(exercises: updatedExercises);

          // 4. Reset weight/reps for new exercise
          state = state.copyWith(
            session: updatedSession,
            isLoading: false,
            currentWeight: newSessionExercise.recommendedWeight,
            currentReps: newSessionExercise.recommendedReps,
            currentRpe: 7.0, // Default RPE to 7
          );

          // 5. Load exercise history for new exercise
          final clientId = state.session?.clientId;
          if (clientId != null) {
            _loadExerciseHistory(clientId, newSessionExercise.exercise.id);
          }

          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Log current set and return true if successful
  Future<bool> logSet() async {
    debugPrint('🟢 logSet: Starting...');
    final currentExercise = state.currentExercise;
    if (currentExercise == null) {
      debugPrint('🔴 logSet: No current exercise!');
      return false;
    }

    // Determine what to log based on timer mode
    final isTimerMode = state.isTimerMode;
    final duration = isTimerMode ? state.currentDuration : null;
    final reps = isTimerMode ? null : state.currentReps;

    debugPrint('🟢 logSet: Exercise ID: ${currentExercise.id}');
    debugPrint('🟢 logSet: Set #${state.currentSetNumber}, Weight: ${state.currentWeight}, Reps: $reps, Duration: ${duration?.inSeconds}s, TimerMode: $isTimerMode');

    state = state.copyWith(isLoading: true);

    // Convert comments to database keys with details appended
    final commentKeys = state.currentComments.map((c) {
      final detail = state.currentCommentDetails[c];
      if (detail != null && detail.isNotEmpty) {
        return '${c.databaseKey}:$detail';
      }
      return c.databaseKey;
    }).toList();

    final result = await _repository.logSet(
      sessionExerciseId: currentExercise.id,
      setNumber: state.currentSetNumber,
      weight: state.currentWeight,
      reps: reps,
      rpe: state.currentRpe,
      duration: duration,
      tags: state.currentTags,
      comments: commentKeys,
    );
    debugPrint('🟢 logSet: Repository result received');

    return result.fold(
      (failure) {
        debugPrint('🔴 logSet: FAILED - ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (set) {
        debugPrint('🟢 logSet: SUCCESS - Set logged: ${set.weight}kg x ${set.reps ?? 'N/A'} / ${set.duration?.inSeconds ?? 'N/A'}s');
        // Update current exercise with new set
        final updatedExercise = currentExercise.copyWith(
          sets: [...currentExercise.sets, set],
        );

        // Update session exercises
        final updatedExercises = List<SessionExerciseEntity>.from(
          state.session!.exercises,
        );
        updatedExercises[state.currentExerciseIndex] = updatedExercise;

        final updatedSession = state.session!.copyWith(
          exercises: updatedExercises,
        );

        // Reset countdown after logging in timer mode
        final resetDuration = isTimerMode ? state.currentDuration : state.countdownRemaining;

        state = state.copyWith(
          session: updatedSession,
          isLoading: false,
          currentRpe: 7.0, // Reset RPE to default 7 for next set
          currentTags: [],
          // Comments persist at exercise level - not cleared after each set
          lastLoggedSet: set,
          countdownRemaining: resetDuration,
          isCountdownRunning: false,
        );
        return true;
      },
    );
  }

  /// Repeat last set (1-tap logging)
  Future<bool> repeatLastSet() async {
    final lastSet = state.lastSetOfCurrentExercise;
    if (lastSet == null) return false;

    // Set weight and reps from last set
    state = state.copyWith(
      currentWeight: lastSet.weight,
      currentReps: lastSet.reps,
    );

    // Log the set
    return logSet();
  }

  /// Prefill weight/reps from last set of current exercise
  void prefillFromLastSet() {
    final lastSet = state.lastSetOfCurrentExercise;
    if (lastSet != null) {
      state = state.copyWith(
        currentWeight: lastSet.weight,
        currentReps: lastSet.reps,
      );
    }
  }

  /// Update weight
  void setWeight(double weight) {
    state = state.copyWith(currentWeight: weight);
  }

  /// Update reps
  void setReps(int reps) {
    state = state.copyWith(currentReps: reps);
  }

  /// Update RPE
  void setRpe(double? rpe) {
    state = state.copyWith(currentRpe: rpe);
  }

  /// Update tags
  void setTags(List<SetTag> tags) {
    state = state.copyWith(currentTags: tags);
  }

  /// Update comments
  void setComments(List<SetComment> comments) {
    state = state.copyWith(currentComments: comments);
  }

  /// Update comment details (for condition comments with specifics)
  void setCommentDetails(Map<SetComment, String> details) {
    state = state.copyWith(currentCommentDetails: details);
  }

  // ============================================================
  // TIMER MODE METHODS (for isometric exercises)
  // ============================================================

  /// Toggle between reps mode and timer mode
  void toggleTimerMode() {
    state = state.copyWith(
      isTimerMode: !state.isTimerMode,
      isCountdownRunning: false,
    );
  }

  /// Set the target duration for timer mode
  void setDuration(Duration duration) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      currentDuration: duration,
      countdownRemaining: duration,
      isCountdownRunning: false,
    );
  }

  /// Start the countdown timer (runs in provider, independent of widget lifecycle)
  void startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(isCountdownRunning: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isCountdownRunning) {
        timer.cancel();
        return;
      }

      if (state.countdownRemaining.inSeconds <= 1) {
        state = state.copyWith(
          countdownRemaining: Duration.zero,
          isCountdownRunning: false,
        );
        timer.cancel();
        HapticFeedback.heavyImpact();
      } else {
        state = state.copyWith(
          countdownRemaining: Duration(seconds: state.countdownRemaining.inSeconds - 1),
        );
      }
    });
  }

  /// Pause the countdown timer
  void pauseCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(isCountdownRunning: false);
  }

  /// Update countdown remaining (for manual adjustments if needed)
  void updateCountdownRemaining(Duration remaining) {
    state = state.copyWith(countdownRemaining: remaining);
  }

  /// Reset countdown to the set duration
  void resetCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      countdownRemaining: state.currentDuration,
      isCountdownRunning: false,
    );
  }

  /// Move to next exercise
  void nextExercise() {
    if (state.currentExerciseIndex < state.session!.exercises.length - 1) {
      goToExercise(state.currentExerciseIndex + 1);
    }
  }

  /// Move to previous exercise
  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      goToExercise(state.currentExerciseIndex - 1);
    }
  }

  /// Go to specific exercise and initialize with target or last set values
  void goToExercise(int index) {
    if (index < 0 || index >= state.session!.exercises.length) return;

    // Save current exercise comments before switching
    final currentExercise = state.currentExercise;
    Map<String, List<SetComment>> updatedExerciseComments = Map.from(state.exerciseComments);
    Map<String, Map<SetComment, String>> updatedExerciseCommentDetails = Map.from(state.exerciseCommentDetails);

    if (currentExercise != null && state.currentComments.isNotEmpty) {
      updatedExerciseComments[currentExercise.id] = List.from(state.currentComments);
      updatedExerciseCommentDetails[currentExercise.id] = Map.from(state.currentCommentDetails);
    }

    final exercise = state.session!.exercises[index];
    final exerciseEntity = exercise.exercise;

    // Priority: last set of this exercise > target from program > defaults
    double weight = 20.0;
    int reps = 10;
    double rpe = 7.0; // Default RPE to 7

    if (exercise.sets.isNotEmpty) {
      // Use last set values if available
      final lastSet = exercise.sets.last;
      weight = lastSet.weight ?? exercise.recommendedWeight;
      reps = lastSet.reps ?? exercise.recommendedReps;
    } else {
      // Use AI-recommended target values for first set
      weight = exercise.recommendedWeight;
      reps = exercise.recommendedReps;
      rpe = exercise.recommendedRpe ?? 7.0; // Use recommendation or default to 7
    }

    // For bodyweight exercises, default weight to 0
    if (exerciseEntity.isBodyweight) {
      weight = 0.0;
    }

    // Initialize timer mode based on exercise type
    final isTimerMode = exerciseEntity.isIsometric;
    final defaultDuration = Duration(seconds: exerciseEntity.defaultDurationSeconds);

    // Restore comments for the target exercise (or empty if none)
    final restoredComments = updatedExerciseComments[exercise.id] ?? [];
    final restoredCommentDetails = updatedExerciseCommentDetails[exercise.id] ?? {};

    state = state.copyWith(
      currentExerciseIndex: index,
      currentWeight: weight,
      currentReps: reps,
      currentRpe: rpe,
      currentTags: [],
      currentComments: restoredComments,
      currentCommentDetails: restoredCommentDetails,
      isTimerMode: isTimerMode,
      currentDuration: defaultDuration,
      countdownRemaining: defaultDuration,
      isCountdownRunning: false,
      exerciseComments: updatedExerciseComments,
      exerciseCommentDetails: updatedExerciseCommentDetails,
    );

    // Load exercise history for PR display
    final clientId = state.session?.clientId;
    if (clientId != null) {
      _loadExerciseHistory(clientId, exercise.exercise.id);
    }
  }

  /// Complete current exercise
  Future<void> completeExercise() async {
    final currentExercise = state.currentExercise;
    if (currentExercise == null) return;

    await _repository.completeExercise(currentExercise.id);

    // Update local state
    final updatedExercise = currentExercise.copyWith(
      completedAt: DateTime.now(),
    );
    final updatedExercises = List<SessionExerciseEntity>.from(
      state.session!.exercises,
    );
    updatedExercises[state.currentExerciseIndex] = updatedExercise;

    final updatedSession = state.session!.copyWith(
      exercises: updatedExercises,
    );

    state = state.copyWith(session: updatedSession);

    // Move to next exercise if available
    nextExercise();
  }

  /// Complete session
  Future<SessionEntity?> completeSession({
    int? overallRating,
    String? trainerFeedback,
  }) async {
    debugPrint('🟢 completeSession: Starting...');

    if (state.session == null) {
      debugPrint('🔴 completeSession: No session to complete!');
      return null;
    }

    // Save current exercise comments before completing
    _saveCurrentExerciseComments();

    // CRITICAL: Save exercises BEFORE completing (state may change)
    final exercisesBeforeCompletion = List<SessionExerciseEntity>.from(state.session!.exercises);
    final clientId = state.session!.clientId;
    debugPrint('🟢 completeSession: Saved ${exercisesBeforeCompletion.length} exercises before completion');

    // Save trainer comments for all exercises to database
    await _saveExerciseCommentsToDatabase(exercisesBeforeCompletion);

    debugPrint('🟢 completeSession: Session ID: ${state.session!.id}');
    state = state.copyWith(isLoading: true);

    final result = await _repository.completeSession(
      sessionId: state.session!.id,
      overallRating: overallRating,
      trainerFeedback: trainerFeedback,
    );

    return result.fold(
      (failure) {
        debugPrint('🔴 completeSession: FAILED - ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return null;
      },
      (completedSession) {
        debugPrint('🟢 completeSession: SUCCESS - Session completed: ${completedSession.id}');
        state = state.copyWith(
          session: completedSession,
          isLoading: false,
        );

        // Update program's lastSessionFocus based on exercises worked (fire and forget)
        _updateProgramFocusAfterSession(clientId, exercisesBeforeCompletion);

        return completedSession;
      },
    );
  }

  /// Save current exercise comments to exerciseComments map
  void _saveCurrentExerciseComments() {
    final currentExercise = state.currentExercise;
    if (currentExercise == null || state.currentComments.isEmpty) return;

    final updatedExerciseComments = Map<String, List<SetComment>>.from(state.exerciseComments);
    final updatedExerciseCommentDetails = Map<String, Map<SetComment, String>>.from(state.exerciseCommentDetails);

    updatedExerciseComments[currentExercise.id] = List.from(state.currentComments);
    updatedExerciseCommentDetails[currentExercise.id] = Map.from(state.currentCommentDetails);

    state = state.copyWith(
      exerciseComments: updatedExerciseComments,
      exerciseCommentDetails: updatedExerciseCommentDetails,
    );
  }

  /// Save all exercise comments to database
  Future<void> _saveExerciseCommentsToDatabase(List<SessionExerciseEntity> exercises) async {
    debugPrint('🟢 _saveExerciseCommentsToDatabase: Saving comments for ${exercises.length} exercises');

    for (final exercise in exercises) {
      final comments = state.exerciseComments[exercise.id];
      if (comments == null || comments.isEmpty) continue;

      final commentDetails = state.exerciseCommentDetails[exercise.id] ?? {};

      // Build notes JSON with trainer comments
      final notesJson = _buildExerciseNotesJson(exercise, comments, commentDetails);

      debugPrint('🟢 Saving comments for exercise ${exercise.id}: $notesJson');

      await _repository.updateSessionExerciseNotes(
        sessionExerciseId: exercise.id,
        notes: notesJson,
      );
    }

    debugPrint('🟢 _saveExerciseCommentsToDatabase: Complete');
  }

  /// Build notes JSON with existing metadata and trainer comments
  String _buildExerciseNotesJson(
    SessionExerciseEntity exercise,
    List<SetComment> comments,
    Map<SetComment, String> commentDetails,
  ) {
    // Start with existing notes if any
    Map<String, dynamic> notesData = {};
    if (exercise.notes != null && exercise.notes!.isNotEmpty) {
      try {
        notesData = jsonDecode(exercise.notes!) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('🟡 Could not parse existing notes: ${exercise.notes}');
      }
    }

    // Add trainer comments
    final trainerComments = comments.map((c) {
      final detail = commentDetails[c];
      return {
        'key': c.databaseKey,
        'displayName': c.displayName,
        if (detail != null && detail.isNotEmpty) 'detail': detail,
      };
    }).toList();

    notesData['trainerComments'] = trainerComments;

    return jsonEncode(notesData);
  }

  /// Update program's lastSessionFocus after session completion
  Future<void> _updateProgramFocusAfterSession(
    String clientId,
    List<SessionExerciseEntity> exercises,
  ) async {
    debugPrint('🟣 [PROVIDER] _updateProgramFocusAfterSession: Starting...');
    debugPrint('🟣 [PROVIDER] clientId: $clientId, exercises: ${exercises.length}');

    if (exercises.isEmpty) {
      debugPrint('🟡 [PROVIDER] No exercises, skipping focus update');
      return;
    }

    try {
      // Get active program
      final activeProgram = await _ref.read(activeProgramProvider(clientId).future);
      if (activeProgram == null) {
        debugPrint('🟡 [PROVIDER] No active program found, skipping');
        return;
      }

      debugPrint('🟣 [PROVIDER] Active program: ${activeProgram.name}');
      debugPrint('🟣 [PROVIDER] Training split: ${activeProgram.trainingSplit}');
      debugPrint('🟣 [PROVIDER] Current lastSessionFocus: ${activeProgram.lastSessionFocus}');

      // Determine focus based on exercises
      final sessionFocus = _determineSessionFocus(exercises, activeProgram.trainingSplit);
      if (sessionFocus == null) {
        debugPrint('🟡 [PROVIDER] Could not determine session focus');
        return;
      }

      debugPrint('🟣 [PROVIDER] Determined session focus: $sessionFocus');
      debugPrint('🟣 [PROVIDER] Updating program...');

      // Update program
      await _ref.read(programCreationProvider.notifier).updateProgramLastSessionFocus(
        programId: activeProgram.id,
        lastSessionFocus: sessionFocus,
      );

      // Invalidate providers so they refetch with new data
      _ref.invalidate(activeProgramProvider(clientId));
      _ref.invalidate(exerciseRecommendationsProvider(clientId));

      debugPrint('🟣 [PROVIDER] Program focus updated to: $sessionFocus');
    } catch (e, stack) {
      debugPrint('🔴 [PROVIDER] Error updating program focus: $e');
      debugPrint('🔴 [PROVIDER] Stack: $stack');
    }
  }

  /// Determine session focus based on exercises worked
  String? _determineSessionFocus(List<SessionExerciseEntity> exercises, TrainingSplit split) {
    debugPrint('🟣 [PROVIDER] _determineSessionFocus: ${exercises.length} exercises, split: $split');

    int upperCount = 0;
    int lowerCount = 0;
    int pushCount = 0;
    int pullCount = 0;

    for (final exercise in exercises) {
      final group = exercise.exercise.movementGroup;
      final muscle = exercise.exercise.muscleGroup?.toLowerCase() ?? '';
      debugPrint('🟣 [PROVIDER] Exercise: ${exercise.exercise.name}, group: $group, muscle: $muscle');

      switch (group) {
        case MovementGroup.push:
          upperCount++;
          pushCount++;
          break;
        case MovementGroup.pull:
          upperCount++;
          pullCount++;
          break;
        case MovementGroup.legs:
          lowerCount++;
          break;
        case MovementGroup.core:
          lowerCount++;
          break;
        case MovementGroup.other:
          // Check muscle group to determine upper/lower
          if (muscle.contains('leg') || muscle.contains('quad') ||
              muscle.contains('ham') || muscle.contains('glute') ||
              muscle.contains('calf') || muscle.contains('calves')) {
            lowerCount++;
          } else {
            upperCount++;
          }
          break;
      }
    }

    debugPrint('🟣 [PROVIDER] Counts - upper: $upperCount, lower: $lowerCount, push: $pushCount, pull: $pullCount');

    switch (split) {
      case TrainingSplit.upperLower:
        return lowerCount > upperCount ? 'lower' : 'upper';
      case TrainingSplit.pushPullLegs:
        if (lowerCount > pushCount && lowerCount > pullCount) return 'legs';
        if (pushCount >= pullCount) return 'push';
        return 'pull';
      case TrainingSplit.fullBody:
        return 'full_body';
    }
  }

  /// Cancel session (discard all records)
  Future<bool> cancelSession() async {
    debugPrint('🟢 cancelSession: Starting...');

    if (state.session == null) {
      debugPrint('🔴 cancelSession: No session to cancel!');
      return false;
    }

    debugPrint('🟢 cancelSession: Session ID: ${state.session!.id}');
    state = state.copyWith(isLoading: true);

    final result = await _repository.cancelSession(state.session!.id);

    return result.fold(
      (failure) {
        debugPrint('🔴 cancelSession: FAILED - ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (_) {
        debugPrint('🟢 cancelSession: SUCCESS - Session cancelled');
        state = const ActiveSessionState(); // Reset state
        return true;
      },
    );
  }

  /// Clear session state
  void clearSession() {
    state = const ActiveSessionState();
  }
}

/// Provider for active session state
final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>((ref) {
  return ActiveSessionNotifier(ref.read(sessionRepositoryProvider), ref);
});

/// Provider for exercise library with alias search integration
/// Searches exercises by name, Korean name, AND exercise aliases for comprehensive matching
final exerciseLibraryProvider = FutureProvider.family<List<ExerciseEntity>, String?>((ref, searchQuery) async {
  final sessionRepository = ref.read(sessionRepositoryProvider);

  // Get exercises matching name/name_ko
  final result = await sessionRepository.getExercises(searchQuery: searchQuery);
  final directMatches = result.fold((_) => <ExerciseEntity>[], (exercises) => exercises);

  // If no search query, just return direct matches
  if (searchQuery == null || searchQuery.isEmpty) {
    return directMatches;
  }

  // Search aliases for additional matches
  final recommendationRepository = ref.read(recommendationRepositoryProvider);
  final aliasResult = await recommendationRepository.searchAliases(searchQuery);
  final aliasExerciseIds = aliasResult.fold(
    (_) => <String>{},
    (aliases) => aliases.map((a) => a.exerciseId).toSet(),
  );

  // If no alias matches found, return direct matches
  if (aliasExerciseIds.isEmpty) {
    return directMatches;
  }

  // Get exercise IDs already in direct matches
  final directMatchIds = directMatches.map((e) => e.id).toSet();

  // Find alias matches not already in direct matches
  final additionalIds = aliasExerciseIds.difference(directMatchIds);

  // If all alias matches are already included, return direct matches
  if (additionalIds.isEmpty) {
    return directMatches;
  }

  // Fetch additional exercises by ID (those matched only by alias)
  // Get all exercises and filter by alias match IDs
  final allExercisesResult = await sessionRepository.getExercises();
  final allExercises = allExercisesResult.fold((_) => <ExerciseEntity>[], (ex) => ex);
  final aliasMatchedExercises = allExercises.where((e) => additionalIds.contains(e.id)).toList();

  // Merge: direct matches first, then alias matches
  final merged = <ExerciseEntity>[...directMatches];
  for (final exercise in aliasMatchedExercises) {
    if (!directMatchIds.contains(exercise.id)) {
      merged.add(exercise);
    }
  }

  debugPrint('🔍 [exerciseLibraryProvider] Search "$searchQuery": ${directMatches.length} direct + ${aliasMatchedExercises.length} alias = ${merged.length} total');

  return merged;
});

/// Provider for recent exercises
final recentExercisesProvider = FutureProvider.family<List<ExerciseEntity>, String>((ref, clientId) async {
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getRecentExercises(clientId: clientId);
  return result.fold((_) => <ExerciseEntity>[], (exercises) => exercises);
});

/// Provider for client's recent completed sessions (for copying previous workouts)
final clientRecentSessionsProvider = FutureProvider.family<List<SessionEntity>, String>((ref, clientId) async {
  debugPrint('🔍 [clientRecentSessionsProvider] Fetching sessions for clientId: $clientId');
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getSessions(
    clientId: clientId,
    status: SessionStatus.completed,
  );
  return result.fold(
    (failure) {
      debugPrint('🔴 [clientRecentSessionsProvider] Error: ${failure.message}');
      return <SessionEntity>[];
    },
    (sessions) {
      debugPrint('🟢 [clientRecentSessionsProvider] Found ${sessions.length} completed sessions');
      return sessions.take(5).toList(); // Limit to 5 most recent
    },
  );
});

/// Provider for client's full session history (for History tab in Stats screen)
/// Returns all completed sessions, ordered by completion date (newest first)
final clientSessionHistoryProvider = FutureProvider.family<List<SessionEntity>, String>((ref, clientId) async {
  debugPrint('🔍 [clientSessionHistoryProvider] Fetching full session history for clientId: $clientId');
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getSessions(
    clientId: clientId,
    status: SessionStatus.completed,
  );
  return result.fold(
    (failure) {
      debugPrint('🔴 [clientSessionHistoryProvider] Error: ${failure.message}');
      return <SessionEntity>[];
    },
    (sessions) {
      debugPrint('🟢 [clientSessionHistoryProvider] Found ${sessions.length} completed sessions');
      return sessions; // Return all sessions (no limit)
    },
  );
});

/// Provider for exercise recommendation service with database weights, user preferences, and relations
final exerciseRecommendationServiceProvider = Provider<ExerciseRecommendationService>((ref) {
  // Watch weights provider for reactivity
  final weightsAsync = ref.watch(recommendationWeightsProvider);
  final weights = weightsAsync.valueOrNull;

  // Watch user preferences for filtering/boosting
  final preferencesAsync = ref.watch(userPreferencesProvider);
  final userPreferences = preferencesAsync.valueOrNull;

  // Watch exercise relations for explicit relation scoring
  final relationsAsync = ref.watch(exerciseRelationsProvider);
  final relations = relationsAsync.valueOrNull;

  // Create service with weights, preferences, and relations (or defaults if not yet loaded)
  return ExerciseRecommendationService(
    weights: weights,
    userPreferences: userPreferences,
    relations: relations,
  );
});

/// Exercise recommendations state
class ExerciseRecommendationsState {
  final List<RecommendedExercise> recommendations;
  final List<String> recommendedGroupOrder;
  final bool isLoading;
  final String? error;

  const ExerciseRecommendationsState({
    this.recommendations = const [],
    this.recommendedGroupOrder = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseRecommendationsState copyWith({
    List<RecommendedExercise>? recommendations,
    List<String>? recommendedGroupOrder,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseRecommendationsState(
      recommendations: recommendations ?? this.recommendations,
      recommendedGroupOrder: recommendedGroupOrder ?? this.recommendedGroupOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Exercise recommendations provider
/// Parameters: clientId
/// Fetches active program preferences and training split for personalized recommendations
final exerciseRecommendationsProvider = FutureProvider.family<ExerciseRecommendationsState, String>((ref, clientId) async {
  debugPrint('🟢 [exerciseRecommendationsProvider] Getting recommendations for client: $clientId');

  final service = ref.read(exerciseRecommendationServiceProvider);

  // Get client's goals
  List<String> clientGoals = ['general']; // Default if client not found
  try {
    final client = await ref.read(clientProvider(clientId).future);
    if (client.goals.isNotEmpty) {
      clientGoals = client.goals;
    }
    debugPrint('🟢 [exerciseRecommendationsProvider] Client goals: $clientGoals');
  } catch (e) {
    debugPrint('🟡 [exerciseRecommendationsProvider] Could not fetch client goals: $e');
  }

  // Get active program preferences and training split (use watch for reactivity)
  List<String>? preferredMovementGroups;
  List<String>? focusAreas;
  TrainingSplit? trainingSplit;
  String? suggestedNextFocus;
  try {
    final activeProgram = await ref.watch(activeProgramProvider(clientId).future);
    if (activeProgram != null) {
      preferredMovementGroups = activeProgram.preferredMovementGroups;
      focusAreas = activeProgram.focusAreas;
      trainingSplit = activeProgram.trainingSplit;
      suggestedNextFocus = activeProgram.suggestedNextFocus;
      debugPrint('🟢 [exerciseRecommendationsProvider] Active program: ${activeProgram.name}');
      debugPrint('🟢 [exerciseRecommendationsProvider] Training split: ${trainingSplit.displayName}');
      debugPrint('🟢 [exerciseRecommendationsProvider] Suggested next focus: $suggestedNextFocus');
      debugPrint('🟢 [exerciseRecommendationsProvider] Preferred groups: $preferredMovementGroups');
      debugPrint('🟢 [exerciseRecommendationsProvider] Focus areas: $focusAreas');
    } else {
      debugPrint('🟡 [exerciseRecommendationsProvider] No active program found');
    }
  } catch (e) {
    debugPrint('🟡 [exerciseRecommendationsProvider] Could not fetch active program: $e');
  }

  // Get recent sessions
  final recentSessions = await ref.read(clientRecentSessionsProvider(clientId).future);
  debugPrint('🟢 [exerciseRecommendationsProvider] Recent sessions: ${recentSessions.length}');

  // Get all exercises
  final exercises = await ref.read(exerciseLibraryProvider(null).future);
  debugPrint('🟢 [exerciseRecommendationsProvider] All exercises: ${exercises.length}');

  // Get current exercise group (if any)
  final sessionState = ref.read(activeSessionProvider);
  final currentGroup = sessionState.currentExercise?.exercise.movementGroup;

  // Get recommended group order (with program preferences and training split)
  final groupOrder = service.getRecommendedGroupOrder(
    recentSessions: recentSessions,
    clientGoals: clientGoals,
    currentExerciseGroup: currentGroup,
    preferredMovementGroups: preferredMovementGroups,
    focusAreas: focusAreas,
    trainingSplit: trainingSplit,
    suggestedNextFocus: suggestedNextFocus,
  );
  debugPrint('🟢 [exerciseRecommendationsProvider] Group order: ${groupOrder.take(3).join(", ")}...');

  // Get recommended exercises (with program preferences and training split)
  final recommendations = service.getRecommendedExercises(
    allExercises: exercises,
    recentSessions: recentSessions,
    clientGoals: clientGoals,
    preferredMovementGroups: preferredMovementGroups,
    focusAreas: focusAreas,
    trainingSplit: trainingSplit,
    suggestedNextFocus: suggestedNextFocus,
    limit: 10,
  );
  debugPrint('🟢 [exerciseRecommendationsProvider] Top recommendations: ${recommendations.take(3).map((r) => r.exercise.name).join(", ")}');

  return ExerciseRecommendationsState(
    recommendations: recommendations,
    recommendedGroupOrder: groupOrder,
  );
});

/// Contextual recommendations provider for exercise picker
/// Uses the last exercise in session to generate complementary + supplementary recommendations
/// Parameters: clientId
/// IMPORTANT: Uses ref.watch on activeSessionProvider for automatic refresh when exercises change
final contextualRecommendationsProvider = Provider.family<ContextualRecommendationsState, String>((ref, clientId) {
  debugPrint('🟣 [contextualRecommendationsProvider] Building for client: $clientId');

  final service = ref.read(exerciseRecommendationServiceProvider);

  // WATCH active session for reactivity (auto-refresh when exercises change)
  final sessionState = ref.watch(activeSessionProvider);
  final sessionExercises = sessionState.session?.exercises ?? [];

  debugPrint('🟣 [contextualRecommendationsProvider] Session exercises: ${sessionExercises.length}');

  // Build context from session exercises
  final lastExercise = sessionExercises.isNotEmpty
      ? sessionExercises.last.exercise
      : null;
  final secondLastExercise = sessionExercises.length >= 2
      ? sessionExercises[sessionExercises.length - 2].exercise
      : null;

  final context = RecommendationContext(
    lastExercise: lastExercise,
    secondLastExercise: secondLastExercise,
    exerciseIdsInSession: sessionExercises.map((e) => e.exercise.id).toSet(),
    sessionGoal: sessionState.session?.sessionType,
  );

  debugPrint('🟣 [contextualRecommendationsProvider] Context - lastExercise: ${lastExercise?.displayName}, exerciseIds: ${context.exerciseIdsInSession.length}');

  // No context means no recommendations (empty session)
  if (!context.hasContext) {
    debugPrint('🟣 [contextualRecommendationsProvider] No context - returning empty state');
    return const ContextualRecommendationsState();
  }

  // Get all exercises (use cached value if available)
  final exercisesAsync = ref.watch(exerciseLibraryProvider(null));
  final exercises = exercisesAsync.valueOrNull ?? [];

  if (exercises.isEmpty) {
    debugPrint('🟣 [contextualRecommendationsProvider] No exercises available');
    return const ContextualRecommendationsState();
  }

  // Get complementary recommendations (10 for expand/collapse UI)
  final complementary = service.getComplementaryRecommendations(
    allExercises: exercises,
    context: context,
    limit: 10,
  );
  debugPrint('🟣 [contextualRecommendationsProvider] Complementary: ${complementary.map((r) => r.exercise.displayName).join(", ")}');

  // Get supplementary recommendations (10 for expand/collapse UI)
  final supplementary = service.getSupplementaryRecommendations(
    allExercises: exercises,
    context: context,
    limit: 10,
  );
  debugPrint('🟣 [contextualRecommendationsProvider] Supplementary: ${supplementary.map((r) => r.exercise.displayName).join(", ")}');

  return ContextualRecommendationsState(
    complementary: complementary,
    supplementary: supplementary,
  );
});

// ============================================================
// SESSION GENERATION (Rule-Based, No LLM)
// ============================================================

/// Provider for session generation service
final sessionGenerationServiceProvider = Provider<SessionGenerationService>((ref) {
  final recommendationService = ref.read(exerciseRecommendationServiceProvider);
  return SessionGenerationService(recommendationService);
});

/// Parameters for session generation
class GenerateSessionParams {
  final String clientId;
  final List<String> clientGoals;
  final TrainingSplit trainingSplit;
  final String? suggestedNextFocus;
  final List<String>? focusAreas;
  final List<String>? preferredMovementGroups;

  const GenerateSessionParams({
    required this.clientId,
    required this.clientGoals,
    required this.trainingSplit,
    this.suggestedNextFocus,
    this.focusAreas,
    this.preferredMovementGroups,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerateSessionParams &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          trainingSplit == other.trainingSplit &&
          suggestedNextFocus == other.suggestedNextFocus;

  @override
  int get hashCode =>
      clientId.hashCode ^
      trainingSplit.hashCode ^
      suggestedNextFocus.hashCode;
}

/// Provider for generating a new session (rule-based, no LLM)
/// Returns a GeneratedSession with 6 exercises and prescriptions
final generateSessionProvider = FutureProvider.family<
    GeneratedSession,
    GenerateSessionParams
>((ref, params) async {
  debugPrint('🔷 [generateSessionProvider] Starting generation for client: ${params.clientId}');

  final service = ref.read(sessionGenerationServiceProvider);

  // Get exercise library
  final exercises = await ref.read(exerciseLibraryProvider(null).future);
  debugPrint('🔷 [generateSessionProvider] Loaded ${exercises.length} exercises');

  // Get recent sessions
  final recentSessions = await ref.read(
    clientRecentSessionsProvider(params.clientId).future,
  );
  debugPrint('🔷 [generateSessionProvider] Loaded ${recentSessions.length} recent sessions');

  // Generate session using rule-based algorithm
  final generatedSession = service.generateSession(
    exerciseLibrary: exercises,
    recentSessions: recentSessions,
    clientGoals: params.clientGoals,
    trainingSplit: params.trainingSplit,
    suggestedNextFocus: params.suggestedNextFocus,
    focusAreas: params.focusAreas,
    preferredMovementGroups: params.preferredMovementGroups,
  );

  debugPrint('🔷 [generateSessionProvider] Generated ${generatedSession.exerciseCount} exercises');
  debugPrint('🔷 [generateSessionProvider] Focus: ${generatedSession.focusArea}');

  return generatedSession;
});

/// Synchronous session generation (for immediate use without async)
/// Use this when you already have the exercise library loaded
GeneratedSession generateSessionSync({
  required SessionGenerationService service,
  required List<ExerciseEntity> exerciseLibrary,
  required List<SessionEntity> recentSessions,
  required List<String> clientGoals,
  required TrainingSplit trainingSplit,
  String? suggestedNextFocus,
  List<String>? focusAreas,
  List<String>? preferredMovementGroups,
}) {
  return service.generateSession(
    exerciseLibrary: exerciseLibrary,
    recentSessions: recentSessions,
    clientGoals: clientGoals,
    trainingSplit: trainingSplit,
    suggestedNextFocus: suggestedNextFocus,
    focusAreas: focusAreas,
    preferredMovementGroups: preferredMovementGroups,
  );
}

// ============================================================
// ACHIEVEMENT DETECTION
// ============================================================

/// Provider for achievement detection service
final achievementDetectionServiceProvider = Provider<AchievementDetectionService>((ref) {
  return AchievementDetectionService();
});

/// Provider for detected achievements for a session
/// Parameters: sessionId
/// Fetches session data, history, and exercise histories to compute achievements
final sessionAchievementsProvider = FutureProvider.family<List<DetectedAchievement>, String>((ref, sessionId) async {
  debugPrint('🏆 [sessionAchievementsProvider] Detecting achievements for session: $sessionId');

  final repository = ref.read(sessionRepositoryProvider);
  final service = ref.read(achievementDetectionServiceProvider);

  // Fetch the current session
  final sessionResult = await repository.getSessionById(sessionId);
  final currentSession = sessionResult.fold(
    (failure) {
      debugPrint('🔴 [sessionAchievementsProvider] Failed to fetch session: ${failure.message}');
      return null;
    },
    (session) => session,
  );

  if (currentSession == null) {
    debugPrint('🔴 [sessionAchievementsProvider] Session not found');
    return [];
  }

  final clientId = currentSession.clientId;

  // Fetch session history (excluding current session)
  final historyResult = await repository.getSessions(
    clientId: clientId,
    status: SessionStatus.completed,
  );
  final sessionHistory = historyResult.fold(
    (failure) => <SessionEntity>[],
    (sessions) => sessions.where((s) => s.id != sessionId).toList(),
  );
  debugPrint('🏆 [sessionAchievementsProvider] Session history: ${sessionHistory.length} sessions');

  // Fetch exercise histories for each exercise in the session
  final exerciseHistories = <String, List<ExerciseSetEntity>>{};
  for (final exercise in currentSession.exercises) {
    final exerciseId = exercise.exercise.id;
    final historyResult = await repository.getExerciseHistory(
      clientId: clientId,
      exerciseId: exerciseId,
      limit: 100,
    );
    exerciseHistories[exerciseId] = historyResult.fold(
      (failure) => <ExerciseSetEntity>[],
      (sets) => sets,
    );
  }
  debugPrint('🏆 [sessionAchievementsProvider] Loaded history for ${exerciseHistories.length} exercises');

  // Detect achievements
  final achievements = service.detectAchievements(
    currentSession: currentSession,
    sessionHistory: sessionHistory,
    exerciseHistories: exerciseHistories,
  );

  debugPrint('🏆 [sessionAchievementsProvider] Detected ${achievements.length} achievements');
  for (final a in achievements) {
    debugPrint('  - ${a.type.displayName}: ${a.description}');
  }

  return achievements;
});
