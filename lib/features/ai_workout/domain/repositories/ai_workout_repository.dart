import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../entities/workout_program.dart';
import '../entities/session_feedback.dart';
import '../entities/ai_reasoning.dart';
import '../entities/alternative_exercise.dart';

/// Repository interface for AI workout operations
abstract class AIWorkoutRepository {
  /// Create a new training program (direction) for a client
  /// Programs store client preferences (focus areas, movement groups) for AI exercise selection
  /// Fitness goals come from the client's account, not the program
  Future<Either<Failure, WorkoutProgramEntity>> createProgram({
    required String clientId,
    required String trainerId,
    required String name,
    String? description,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
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

  /// Update program preferences (split, focus areas, movement groups)
  Future<Either<Failure, WorkoutProgramEntity>> updateProgram({
    required String programId,
    String? name,
    String? description,
    TrainingSplit? trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  });

  /// Update program's lastSessionFocus after session completion
  Future<Either<Failure, void>> updateProgramLastSessionFocus({
    required String programId,
    required String lastSessionFocus,
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

  /// Generate exercises for a program by calling the AI edge function
  /// This creates a session in the database with AI-recommended exercises
  /// Goals come from client's account (accounts.fitness_goals)
  /// Program provides preferences (training split, focus areas, movement groups)
  Future<Either<Failure, GeneratedSessionData>> generateExercisesForProgram({
    required String clientId,
    required String programId,
    required String trainerId,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  });

  /// Get similar exercises based on movement pattern for exercise swapping
  /// Returns up to 6 exercises with the same movement pattern
  Future<Either<Failure, List<ExerciseEntity>>> getSimilarExercises({
    required String exerciseId,
    int limit = 6,
  });

  /// Get alternative exercises grouped by equipment and pattern
  /// Returns exercises with same movement group/detail but different equipment
  /// and exercises with same movement group/detail and same equipment (variations)
  Future<Either<Failure, AlternativeExercisesResult>> getAlternativeExercises({
    required String exerciseId,
  });

  /// Get exercises the client has previously done in the same movement group
  Future<Either<Failure, List<SessionAlternative>>>
      getClientPreviousExercises({
    required String clientId,
    required String exerciseId,
  });
}
