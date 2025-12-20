import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/ai_workout_remote_datasource.dart';
import '../../data/repositories/ai_workout_repository_impl.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
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

/// State for program generation
class ProgramGenerationState {
  final WorkoutProgramEntity? program;
  final bool isLoading;
  final String? error;

  const ProgramGenerationState({
    this.program,
    this.isLoading = false,
    this.error,
  });

  ProgramGenerationState copyWith({
    WorkoutProgramEntity? program,
    bool? isLoading,
    String? error,
  }) {
    return ProgramGenerationState(
      program: program ?? this.program,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for program generation
class ProgramGenerationNotifier extends StateNotifier<ProgramGenerationState> {
  final AIWorkoutRepository _repository;

  ProgramGenerationNotifier(this._repository)
      : super(const ProgramGenerationState());

  /// Generate a new single workout session
  Future<void> generateProgram({
    required String clientId,
    required String trainerId,
    required TrainingGoal primaryGoal,
    TrainingGoal? secondaryGoal,
    List<String>? excludedExerciseIds,
    List<String>? preferredEquipment,
  }) async {
    print('[ProgramGeneration] Starting program generation...');
    print('[ProgramGeneration] ClientId: $clientId, Goal: ${primaryGoal.id}');
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.generateProgram(
      clientId: clientId,
      trainerId: trainerId,
      primaryGoal: primaryGoal,
      secondaryGoal: secondaryGoal,
      excludedExerciseIds: excludedExerciseIds,
      preferredEquipment: preferredEquipment,
    );

    result.fold(
      (failure) {
        print('[ProgramGeneration] ====== FAILED ======');
        print('[ProgramGeneration] Error: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (program) {
        print('[ProgramGeneration] ====== SUCCESS ======');
        print('[ProgramGeneration] Program ID: ${program.id}');
        print('[ProgramGeneration] Program Name: ${program.name}');
        print('[ProgramGeneration] AI Model: ${program.aiModelVersion}');
        print('[ProgramGeneration] Updating state with program...');
        state = state.copyWith(
          program: program,
          isLoading: false,
        );
        print('[ProgramGeneration] State updated. Program in state: ${state.program?.id}');
      },
    );
  }

  /// Load an existing program
  Future<void> loadProgram(String programId) async {
    print('[ProgramGeneration] loadProgram called for: $programId');
    print('[ProgramGeneration] Current state has program: ${state.program?.id}');
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getProgram(programId);

    result.fold(
      (failure) {
        print('[ProgramGeneration] loadProgram FAILED: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (program) {
        print('[ProgramGeneration] loadProgram SUCCESS');
        print('[ProgramGeneration] Loaded: ${program.name} with ${program.workoutDays.length} days');
        print('[ProgramGeneration] First day has ${program.workoutDays.firstOrNull?.exercises.length ?? 0} exercises');
        state = state.copyWith(
          program: program,
          isLoading: false,
        );
      },
    );
  }

  /// Swap an exercise
  Future<void> swapExercise({
    required String programExerciseId,
    required String newExerciseId,
    String? reason,
  }) async {
    final result = await _repository.swapExercise(
      programExerciseId: programExerciseId,
      newExerciseId: newExerciseId,
      reason: reason,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        // Reload program to get updated data
        if (state.program != null) {
          loadProgram(state.program!.id);
        }
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

  /// Clear current program
  void clear() {
    state = const ProgramGenerationState();
  }
}

/// Provider for program generation
final programGenerationProvider =
    StateNotifierProvider<ProgramGenerationNotifier, ProgramGenerationState>(
  (ref) => ProgramGenerationNotifier(ref.read(aiWorkoutRepositoryProvider)),
);

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

/// Provider for exercise alternatives
final exerciseAlternativesProvider = FutureProvider.family<
    List<ExerciseAlternative>,
    ({String exerciseId, String clientId, DifficultyFeedback? feedback})>(
  (ref, params) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getAlternatives(
      exerciseId: params.exerciseId,
      clientId: params.clientId,
      feedbackHint: params.feedback,
    );
    return result.fold((_) => [], (alternatives) => alternatives);
  },
);

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

/// Provider for session feedback
final sessionFeedbackProvider =
    StateNotifierProvider<SessionFeedbackNotifier, SessionFeedbackState>(
  (ref) => SessionFeedbackNotifier(ref.read(aiWorkoutRepositoryProvider)),
);
