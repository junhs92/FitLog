import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/session_remote_datasource.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../../domain/repositories/session_repository.dart';

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

  // Last logged set for "Repeat Last Set" feature
  final ExerciseSetEntity? lastLoggedSet;

  const ActiveSessionState({
    this.session,
    this.currentExerciseIndex = 0,
    this.isLoading = false,
    this.error,
    this.currentWeight = 20.0,
    this.currentReps = 10,
    this.currentRpe,
    this.currentTags = const [],
    this.lastLoggedSet,
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
    ExerciseSetEntity? lastLoggedSet,
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
      lastLoggedSet: lastLoggedSet ?? this.lastLoggedSet,
    );
  }
}

/// Active session notifier
class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repository;

  ActiveSessionNotifier(this._repository) : super(const ActiveSessionState());

  /// Initialize weight/reps/rpe from the first exercise's targets
  void _initializeFromFirstExercise(SessionEntity session) {
    if (session.exercises.isEmpty) return;

    final exercise = session.exercises[0];

    // Priority: last set of this exercise > target from program > defaults
    double weight = 20.0;
    int reps = 10;
    double? rpe;

    if (exercise.sets.isNotEmpty) {
      final lastSet = exercise.sets.last;
      weight = lastSet.weight ?? exercise.recommendedWeight;
      reps = lastSet.reps ?? exercise.recommendedReps;
    } else {
      weight = exercise.recommendedWeight;
      reps = exercise.recommendedReps;
      rpe = exercise.recommendedRpe;
    }

    state = state.copyWith(
      currentWeight: weight,
      currentReps: reps,
      currentRpe: rpe,
    );
  }

  /// Start a new session
  Future<void> startSession({
    required String clientId,
    String? sessionType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.startSession(
      clientId: clientId,
      sessionType: sessionType,
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
  }

  /// Start a new session with exercises from a program
  /// Returns the session if successful, null otherwise
  Future<SessionEntity?> startSessionWithProgram({
    required String clientId,
    required String programId,
    required String workoutDayId,
    String? sessionType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.startSession(
      clientId: clientId,
      sessionType: sessionType ?? 'training',
      programId: programId,
      workoutDayId: workoutDayId,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return null;
      },
      (session) {
        state = state.copyWith(
          session: session,
          isLoading: false,
          currentExerciseIndex: 0,
        );
        _initializeFromFirstExercise(session);
        return session;
      },
    );
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
          currentExerciseIndex: updatedExercises.length - 1,
        );
      },
    );
  }

  /// Log current set and return true if successful
  Future<bool> logSet() async {
    debugPrint('🟢 logSet: Starting...');
    final currentExercise = state.currentExercise;
    if (currentExercise == null) {
      debugPrint('🔴 logSet: No current exercise!');
      return false;
    }

    debugPrint('🟢 logSet: Exercise ID: ${currentExercise.id}');
    debugPrint('🟢 logSet: Set #${state.currentSetNumber}, Weight: ${state.currentWeight}, Reps: ${state.currentReps}');

    state = state.copyWith(isLoading: true);

    final result = await _repository.logSet(
      sessionExerciseId: currentExercise.id,
      setNumber: state.currentSetNumber,
      weight: state.currentWeight,
      reps: state.currentReps,
      rpe: state.currentRpe,
      tags: state.currentTags,
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
        debugPrint('🟢 logSet: SUCCESS - Set logged: ${set.weight}kg x ${set.reps}');
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

        state = state.copyWith(
          session: updatedSession,
          isLoading: false,
          currentRpe: null,
          currentTags: [],
          lastLoggedSet: set,
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

    final exercise = state.session!.exercises[index];

    // Priority: last set of this exercise > target from program > defaults
    double weight = 20.0;
    int reps = 10;
    double? rpe;

    if (exercise.sets.isNotEmpty) {
      // Use last set values if available
      final lastSet = exercise.sets.last;
      weight = lastSet.weight ?? exercise.recommendedWeight;
      reps = lastSet.reps ?? exercise.recommendedReps;
    } else {
      // Use AI-recommended target values for first set
      weight = exercise.recommendedWeight;
      reps = exercise.recommendedReps;
      rpe = exercise.recommendedRpe;
    }

    state = state.copyWith(
      currentExerciseIndex: index,
      currentWeight: weight,
      currentReps: reps,
      currentRpe: rpe,
      currentTags: [],
    );
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
    if (state.session == null) return null;

    state = state.copyWith(isLoading: true);

    final result = await _repository.completeSession(
      sessionId: state.session!.id,
      overallRating: overallRating,
      trainerFeedback: trainerFeedback,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return null;
      },
      (completedSession) {
        state = state.copyWith(
          session: completedSession,
          isLoading: false,
        );
        return completedSession;
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
  return ActiveSessionNotifier(ref.read(sessionRepositoryProvider));
});

/// Provider for exercise library
final exerciseLibraryProvider = FutureProvider.family<List<ExerciseEntity>, String?>((ref, searchQuery) async {
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getExercises(searchQuery: searchQuery);
  return result.fold((_) => <ExerciseEntity>[], (exercises) => exercises);
});

/// Provider for recent exercises
final recentExercisesProvider = FutureProvider.family<List<ExerciseEntity>, String>((ref, clientId) async {
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getRecentExercises(clientId: clientId);
  return result.fold((_) => <ExerciseEntity>[], (exercises) => exercises);
});
