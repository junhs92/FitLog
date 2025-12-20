import '../../../../shared/models/result.dart';
import '../entities/exercise_entity.dart';
import '../entities/exercise_set_entity.dart';
import '../entities/session_entity.dart';
import '../entities/session_exercise_entity.dart';

/// Repository interface for session operations
abstract class SessionRepository {
  /// Get all sessions for the current trainer
  Future<Result<List<SessionEntity>>> getSessions({
    String? clientId,
    SessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get a specific session by ID
  Future<Result<SessionEntity>> getSessionById(String sessionId);

  /// Get active session for a client (if any)
  Future<Result<SessionEntity?>> getActiveSession(String clientId);

  /// Start a new session for a client
  /// If programId and workoutDayId are provided, exercises will be auto-populated
  Future<Result<SessionEntity>> startSession({
    required String clientId,
    String? sessionType,
    String? notes,
    String? programId,
    String? workoutDayId,
  });

  /// Complete an active session
  Future<Result<SessionEntity>> completeSession({
    required String sessionId,
    int? overallRating,
    String? trainerFeedback,
  });

  /// Cancel a session
  Future<Result<void>> cancelSession(String sessionId);

  /// Add an exercise to the session
  Future<Result<SessionExerciseEntity>> addExerciseToSession({
    required String sessionId,
    required ExerciseEntity exercise,
    int? order,
  });

  /// Remove an exercise from session
  Future<Result<void>> removeExerciseFromSession(String sessionExerciseId);

  /// Reorder exercises in session
  Future<Result<void>> reorderExercises({
    required String sessionId,
    required List<String> exerciseIds,
  });

  /// Log a set for an exercise
  Future<Result<ExerciseSetEntity>> logSet({
    required String sessionExerciseId,
    required int setNumber,
    double? weight,
    int? reps,
    double? rpe,
    Duration? duration,
    double? distance,
    List<SetTag> tags,
    String? notes,
  });

  /// Update a logged set
  Future<Result<ExerciseSetEntity>> updateSet({
    required String setId,
    required String sessionExerciseId,
    double? weight,
    int? reps,
    double? rpe,
    Duration? duration,
    double? distance,
    List<SetTag>? tags,
    String? notes,
  });

  /// Delete a logged set
  Future<Result<void>> deleteSet({
    required String setId,
    required String sessionExerciseId,
  });

  /// Complete an exercise in the session
  Future<Result<void>> completeExercise(String sessionExerciseId);

  /// Update session notes
  Future<Result<void>> updateSessionNotes({
    required String sessionId,
    required String notes,
  });

  /// Get exercise library
  Future<Result<List<ExerciseEntity>>> getExercises({
    String? category,
    String? movementPattern,
    String? searchQuery,
  });

  /// Get recent exercises for quick selection
  Future<Result<List<ExerciseEntity>>> getRecentExercises({
    required String clientId,
    int limit = 10,
  });

  /// Get client's exercise history for specific exercise
  Future<Result<List<ExerciseSetEntity>>> getExerciseHistory({
    required String clientId,
    required String exerciseId,
    int limit = 10,
  });
}
