import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/workout_program.dart';
import '../entities/session_feedback.dart';
import '../entities/ai_reasoning.dart';

/// Repository interface for AI workout operations
abstract class AIWorkoutRepository {
  /// Get previous training goal for a client (for pre-filling)
  Future<TrainingGoal?> getPreviousGoal(String clientId);

  /// Generate a new single workout session using AI
  Future<Either<Failure, WorkoutProgramEntity>> generateProgram({
    required String clientId,
    required String trainerId,
    required TrainingGoal primaryGoal,
    TrainingGoal? secondaryGoal,
    int? durationWeeks, // Ignored - always 1 session
    int? sessionsPerWeek, // Ignored - always 1 session
    List<String>? excludedExerciseIds,
    List<String>? preferredEquipment,
  });

  /// Get a workout program by ID
  Future<Either<Failure, WorkoutProgramEntity>> getProgram(String programId);

  /// Get all programs for a client
  Future<Either<Failure, List<WorkoutProgramEntity>>> getClientPrograms(
    String clientId,
  );

  /// Get active program for a client
  Future<Either<Failure, WorkoutProgramEntity?>> getActiveProgram(
    String clientId,
  );

  /// Update program status
  Future<Either<Failure, void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  });

  /// Swap an exercise in a program
  Future<Either<Failure, ProgramExerciseEntity>> swapExercise({
    required String programExerciseId,
    required String newExerciseId,
    String? reason,
  });

  /// Get alternatives for an exercise
  Future<Either<Failure, List<ExerciseAlternative>>> getAlternatives({
    required String exerciseId,
    required String clientId,
    DifficultyFeedback? feedbackHint,
  });

  /// Get AI reasoning for an exercise selection
  Future<Either<Failure, AIExerciseReasoning>> getExerciseReasoning({
    required String exerciseId,
    required String clientId,
    required TrainingGoal goal,
  });

  /// Record difficulty feedback during session
  Future<Either<Failure, SessionExerciseFeedback>> recordDifficultyFeedback({
    required String sessionExerciseId,
    required String exerciseId,
    required DifficultyFeedback feedback,
  });

  /// Get session alternatives based on feedback
  Future<Either<Failure, List<SessionAlternative>>> getSessionAlternatives({
    required String exerciseId,
    required String clientId,
    required DifficultyFeedback feedback,
  });

  /// Record exercise swap history for ML learning
  Future<Either<Failure, void>> recordSwapHistory({
    required String clientId,
    required String trainerId,
    required String originalExerciseId,
    required String replacementExerciseId,
    DifficultyFeedback? feedbackReason,
    String? customReason,
    String? sessionId,
  });

  /// Get swap history for a client
  Future<Either<Failure, List<ExerciseSwapHistory>>> getSwapHistory({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Delete a program
  Future<Either<Failure, void>> deleteProgram(String programId);
}
