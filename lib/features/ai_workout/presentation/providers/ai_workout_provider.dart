import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../data/datasources/ai_workout_remote_datasource.dart';
import '../../data/repositories/ai_workout_repository_impl.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/alternative_exercise.dart';
import '../../domain/repositories/ai_workout_repository.dart';

/// Provider for Supabase client
final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for AI workout remote datasource
final _aiWorkoutDataSourceProvider = Provider<AIWorkoutRemoteDataSource>((ref) {
  return AIWorkoutRemoteDataSource(ref.read(_supabaseClientProvider));
});

/// Provider for AI workout repository
final aiWorkoutRepositoryProvider = Provider<AIWorkoutRepository>((ref) {
  return AIWorkoutRepositoryImpl(ref.read(_aiWorkoutDataSourceProvider));
});

/// State for program creation (new simplified structure)
class ProgramCreationState {
  final WorkoutProgramEntity? program;
  final bool isLoading;
  final String? error;

  const ProgramCreationState({
    this.program,
    this.isLoading = false,
    this.error,
  });

  ProgramCreationState copyWith({
    WorkoutProgramEntity? program,
    bool? isLoading,
    String? error,
  }) {
    return ProgramCreationState(
      program: program ?? this.program,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for program creation
/// Programs are now training DIRECTIONS with client preferences
/// Goals come from client's account (accounts.fitness_goals)
/// Programs store preferences: training split, focus areas, movement patterns
class ProgramCreationNotifier extends StateNotifier<ProgramCreationState> {
  final AIWorkoutRepository _repository;

  ProgramCreationNotifier(this._repository)
      : super(const ProgramCreationState());

  /// Create a new training program (direction with preferences) and generate exercises
  /// Flow: Save program → Generate exercises → Update program → Return with exercises
  /// Goals are fetched from client's account, not passed here
  Future<void> createProgram({
    required String clientId,
    required String trainerId,
    required String name,
    String? description,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    debugPrint('🟢 [PROVIDER] createProgram started');
    debugPrint('🟢 [PROVIDER] clientId: $clientId, trainerId: $trainerId');
    debugPrint('🟢 [PROVIDER] name: $name, trainingSplit: ${trainingSplit.id}');
    debugPrint('🟢 [PROVIDER] focusAreas: $focusAreas');
    debugPrint('🟢 [PROVIDER] preferredMovementGroups: $preferredMovementGroups');

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('🟢 [PROVIDER] State set to loading');

    try {
      // Step 1: Create program (save preferences)
      debugPrint('🟢 [PROVIDER] Step 1: Calling repository.createProgram...');
      final createResult = await _repository.createProgram(
        clientId: clientId,
        trainerId: trainerId,
        name: name,
        description: description,
        trainingSplit: trainingSplit,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );

      await createResult.fold(
        (failure) async {
          debugPrint('🔴 [PROVIDER] Program creation FAILED: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (program) async {
          debugPrint('🟢 [PROVIDER] Program created: ${program.id}');

          // Step 2: Generate exercises by calling AI edge function
          // Creates session in database with AI-recommended exercises
          // Edge function fetches client's goals from accounts table
          debugPrint('🟢 [PROVIDER] Step 2: Calling AI to generate exercises...');
          final exercisesResult = await _repository.generateExercisesForProgram(
            clientId: clientId,
            programId: program.id,
            trainerId: trainerId,
            trainingSplit: trainingSplit,
            focusAreas: focusAreas,
            preferredMovementGroups: preferredMovementGroups,
          );

          await exercisesResult.fold(
            (failure) async {
              debugPrint('🔴 [PROVIDER] Exercise generation FAILED: ${failure.message}');
              // Still return program even if exercise generation fails
              state = state.copyWith(
                program: program,
                isLoading: false,
                error: 'Program created but exercise generation failed: ${failure.message}',
              );
            },
            (sessionData) async {
              debugPrint('🟢 [PROVIDER] Generated ${sessionData.exercises.length} exercises');

              // Keep exercises in memory (NOT saved to DB)
              // Exercises will be passed to session_exercises when session starts
              final programWithExercises = program.copyWith(
                generatedExercises: sessionData.exercises,
              );

              debugPrint('🟢 [PROVIDER] Program updated in memory with ${sessionData.exercises.length} exercises');
              state = state.copyWith(
                program: programWithExercises,
                isLoading: false,
              );
              debugPrint('🟢 [PROVIDER] State updated with program and exercises');
            },
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 [PROVIDER] EXCEPTION: $e');
      debugPrint('🔴 [PROVIDER] STACK: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load an existing program
  Future<void> loadProgram(String programId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getProgram(programId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (program) {
        state = state.copyWith(
          program: program,
          isLoading: false,
        );
      },
    );
  }

  /// Update program status
  Future<void> updateStatus(ProgramStatus status) async {
    if (state.program == null) return;

    final result = await _repository.updateProgramStatus(
      programId: state.program!.id,
      status: status,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => loadProgram(state.program!.id),
    );
  }

  /// Delete program
  Future<bool> deleteProgram(String programId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.deleteProgram(programId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (_) {
        state = const ProgramCreationState();
        return true;
      },
    );
  }

  /// Update an existing program preferences and regenerate exercises
  Future<void> updateProgram({
    required String programId,
    required String clientId,
    required String trainerId,
    String? name,
    String? description,
    TrainingSplit? trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    debugPrint('🟢 [PROVIDER] updateProgram started');
    debugPrint('🟢 [PROVIDER] programId: $programId');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Update program preferences
      debugPrint('🟢 [PROVIDER] Step 1: Updating program preferences...');
      final updateResult = await _repository.updateProgram(
        programId: programId,
        name: name,
        description: description,
        trainingSplit: trainingSplit,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );

      await updateResult.fold(
        (failure) async {
          debugPrint('🔴 [PROVIDER] Program update FAILED: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (program) async {
          debugPrint('🟢 [PROVIDER] Program updated: ${program.id}');

          // Step 2: Generate new exercises based on updated preferences
          // Edge function fetches client's goals from accounts table
          debugPrint('🟢 [PROVIDER] Step 2: Regenerating exercises...');
          final exercisesResult = await _repository.generateExercisesForProgram(
            clientId: clientId,
            programId: program.id,
            trainerId: trainerId,
            trainingSplit: trainingSplit ?? program.trainingSplit,
            focusAreas: focusAreas ?? program.focusAreas,
            preferredMovementGroups: preferredMovementGroups ?? program.preferredMovementGroups,
          );

          await exercisesResult.fold(
            (failure) async {
              debugPrint('🔴 [PROVIDER] Exercise regeneration FAILED: ${failure.message}');
              state = state.copyWith(
                program: program,
                isLoading: false,
                error: 'Program updated but exercise generation failed: ${failure.message}',
              );
            },
            (sessionData) async {
              debugPrint('🟢 [PROVIDER] Regenerated ${sessionData.exercises.length} exercises');

              final programWithExercises = program.copyWith(
                generatedExercises: sessionData.exercises,
              );

              state = state.copyWith(
                program: programWithExercises,
                isLoading: false,
              );
              debugPrint('🟢 [PROVIDER] State updated with updated program and exercises');
            },
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 [PROVIDER] EXCEPTION: $e');
      debugPrint('🔴 [PROVIDER] STACK: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save program preferences only (without generating exercises)
  /// Used when user just wants to save the program direction/options
  Future<bool> saveProgramPreferencesOnly({
    required String clientId,
    required String trainerId,
    required String name,
    String? description,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
    String? existingProgramId, // If provided, update instead of create
  }) async {
    debugPrint('🟢 [PROVIDER] saveProgramPreferencesOnly started');
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (existingProgramId != null) {
        // Update existing program
        final result = await _repository.updateProgram(
          programId: existingProgramId,
          name: name,
          description: description,
          trainingSplit: trainingSplit,
          focusAreas: focusAreas,
          preferredMovementGroups: preferredMovementGroups,
        );

        return result.fold(
          (failure) {
            debugPrint('🔴 [PROVIDER] Program update FAILED: ${failure.message}');
            state = state.copyWith(isLoading: false, error: failure.message);
            return false;
          },
          (program) {
            debugPrint('🟢 [PROVIDER] Program preferences saved: ${program.id}');
            state = state.copyWith(program: program, isLoading: false);
            return true;
          },
        );
      } else {
        // Create new program
        final result = await _repository.createProgram(
          clientId: clientId,
          trainerId: trainerId,
          name: name,
          description: description,
          trainingSplit: trainingSplit,
          focusAreas: focusAreas,
          preferredMovementGroups: preferredMovementGroups,
        );

        return result.fold(
          (failure) {
            debugPrint('🔴 [PROVIDER] Program creation FAILED: ${failure.message}');
            state = state.copyWith(isLoading: false, error: failure.message);
            return false;
          },
          (program) {
            debugPrint('🟢 [PROVIDER] Program preferences saved: ${program.id}');
            state = state.copyWith(program: program, isLoading: false);
            return true;
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [PROVIDER] EXCEPTION: $e');
      debugPrint('🔴 [PROVIDER] STACK: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Clear current program
  void clear() {
    state = const ProgramCreationState();
  }

  /// Update program's lastSessionFocus after session completion
  Future<void> updateProgramLastSessionFocus({
    required String programId,
    required String lastSessionFocus,
  }) async {
    debugPrint('🟢 [PROVIDER] updateProgramLastSessionFocus: $lastSessionFocus');
    try {
      await _repository.updateProgramLastSessionFocus(
        programId: programId,
        lastSessionFocus: lastSessionFocus,
      );
      debugPrint('🟢 [PROVIDER] lastSessionFocus updated successfully');
    } catch (e) {
      debugPrint('🔴 [PROVIDER] Failed to update lastSessionFocus: $e');
    }
  }
}

/// Provider for program creation
final programCreationProvider =
    StateNotifierProvider<ProgramCreationNotifier, ProgramCreationState>(
  (ref) => ProgramCreationNotifier(ref.read(aiWorkoutRepositoryProvider)),
);

/// Backward compatibility alias for programGenerationProvider
/// TODO: Remove after all usages are migrated to programCreationProvider
final programGenerationProvider = programCreationProvider;

/// State alias for backward compatibility
typedef ProgramGenerationState = ProgramCreationState;

/// Provider for client programs list
final clientProgramsProvider = FutureProvider.family<
    List<WorkoutProgramEntity>, String>(
  (ref, clientId) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getClientPrograms(clientId);
    return result.fold((_) => [], (programs) => programs);
  },
);

/// Provider for active program
final activeProgramProvider = FutureProvider.family<
    WorkoutProgramEntity?, String>(
  (ref, clientId) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getActiveProgram(clientId);
    return result.fold((_) => null, (program) => program);
  },
);

/// Direct method to check for active program (bypasses provider caching)
Future<WorkoutProgramEntity?> checkActiveProgram(
  AIWorkoutRepository repository,
  String clientId,
) async {
  final result = await repository.getActiveProgram(clientId);
  return result.fold(
    (failure) {
      debugPrint('🔴 [checkActiveProgram] Failure: ${failure.message}');
      return null;
    },
    (program) {
      debugPrint('🟢 [checkActiveProgram] Success: ${program?.id}');
      return program;
    },
  );
}

/// Provider for AI exercise reasoning
final exerciseReasoningProvider = FutureProvider.family<
    AIExerciseReasoning?,
    ({String exerciseId, String clientId, TrainingGoal goal})>(
  (ref, params) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getExerciseReasoning(
      exerciseId: params.exerciseId,
      clientId: params.clientId,
      goal: params.goal,
    );
    return result.fold((_) => null, (reasoning) => reasoning);
  },
);

/// State for session difficulty feedback
class SessionFeedbackState {
  final DifficultyFeedback? currentFeedback;
  final List<SessionAlternative> alternatives;
  final bool isLoading;
  final String? error;

  const SessionFeedbackState({
    this.currentFeedback,
    this.alternatives = const [],
    this.isLoading = false,
    this.error,
  });

  SessionFeedbackState copyWith({
    DifficultyFeedback? currentFeedback,
    List<SessionAlternative>? alternatives,
    bool? isLoading,
    String? error,
  }) {
    return SessionFeedbackState(
      currentFeedback: currentFeedback ?? this.currentFeedback,
      alternatives: alternatives ?? this.alternatives,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for session feedback
/// Handles real-time difficulty feedback and alternative suggestions during sessions
class SessionFeedbackNotifier extends StateNotifier<SessionFeedbackState> {
  final AIWorkoutRepository _repository;

  SessionFeedbackNotifier(this._repository)
      : super(const SessionFeedbackState());

  /// Record difficulty feedback and get alternatives
  Future<void> recordFeedback({
    required String sessionExerciseId,
    required String exerciseId,
    required String clientId,
    required DifficultyFeedback feedback,
  }) async {
    state = state.copyWith(
      isLoading: true,
      currentFeedback: feedback,
      error: null,
    );

    // Record feedback
    await _repository.recordDifficultyFeedback(
      sessionExerciseId: sessionExerciseId,
      exerciseId: exerciseId,
      feedback: feedback,
    );

    // Get alternatives if not "just right"
    if (feedback != DifficultyFeedback.justRight) {
      final result = await _repository.getSessionAlternatives(
        exerciseId: exerciseId,
        clientId: clientId,
        feedback: feedback,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (alternatives) => state = state.copyWith(
          alternatives: alternatives,
          isLoading: false,
        ),
      );
    } else {
      state = state.copyWith(isLoading: false, alternatives: []);
    }
  }

  /// Clear feedback state
  void clear() {
    state = const SessionFeedbackState();
  }
}

/// Provider for session feedback (per-exercise state)
/// Each exercise has its own feedback state keyed by exerciseId
final sessionFeedbackProvider = StateNotifierProvider.family<
    SessionFeedbackNotifier, SessionFeedbackState, String>(
  (ref, exerciseId) => SessionFeedbackNotifier(
    ref.read(aiWorkoutRepositoryProvider),
  ),
);

/// Provider for fetching similar exercises based on movement pattern
/// Returns up to 6 exercises with similar movement patterns for swapping
final similarExercisesProvider = FutureProvider.family<
    List<ExerciseEntity>, String>(
  (ref, exerciseId) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getSimilarExercises(
      exerciseId: exerciseId,
      limit: 6,
    );
    return result.fold(
      (_) => <ExerciseEntity>[],
      (exercises) => exercises,
    );
  },
);

/// Provider for client's previously done exercises matching a movement group
/// Parameters: ({String clientId, String exerciseId})
final clientPreviousExercisesProvider = FutureProvider.family<
    List<SessionAlternative>,
    ({String clientId, String exerciseId})>(
  (ref, params) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getClientPreviousExercises(
      clientId: params.clientId,
      exerciseId: params.exerciseId,
    );
    return result.fold(
      (_) => <SessionAlternative>[],
      (exercises) => exercises,
    );
  },
);

/// Provider for alternative exercises (equipment + pattern variations)
/// Returns exercises grouped by:
/// 1. Different equipment (same movement pattern)
/// 2. Same equipment (pattern variations)
final alternativeExercisesProvider = FutureProvider.family<
    AlternativeExercisesResult, String>(
  (ref, exerciseId) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getAlternativeExercises(
      exerciseId: exerciseId,
    );
    return result.fold(
      (_) => AlternativeExercisesResult.empty(),
      (data) => data,
    );
  },
);
