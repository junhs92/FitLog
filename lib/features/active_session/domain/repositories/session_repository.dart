import '../../../../shared/models/result.dart';
import '../../data/models/session_exercise_input.dart';
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
  /// If programId is provided, the session will be linked to the training program
  /// If exercises are provided, they will be added to session_exercises
  /// If aiReasoning is provided, it will be saved as session-level AI description
  Future<Result<SessionEntity>> startSession({
    required String clientId,
    String? sessionType,
    String? notes,
    String? programId,
    List<Map<String, dynamic>>? exercises,
    String? aiReasoning,
  });

  /// Activate an existing session (created by AI edge function)
  /// Updates status from 'scheduled' to 'active' and creates session_exercises from the list
  /// If exercises list is provided, session_exercises will be created from it
  @Deprecated('Use createSession instead')
  Future<Result<SessionEntity>> activateSession({
    required String sessionId,
    List<Map<String, dynamic>>? exercises,
  });

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

  /// Add an exercise to the session by ID (for swap operations)
  Future<Result<SessionExerciseEntity>> addExerciseToSessionById({
    required String sessionId,
    required String exerciseId,
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
    List<String> comments,
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

  /// Update session exercise notes (for storing trainer comments)
  Future<Result<void>> updateSessionExerciseNotes({
    required String sessionExerciseId,
    required String notes,
  });

  /// Get exercise library
  Future<Result<List<ExerciseEntity>>> getExercises({
    String? category,
    String? movementGroup,
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
