import '../../../../shared/models/result.dart';
import '../entities/client_muscle_map_entity.dart';
import '../entities/muscle_group.dart';

/// Repository interface for muscle activity operations
abstract class MuscleActivityRepository {
  /// Get aggregated muscle activity for a client over a date range
  ///
  /// [clientId] - The client to get data for
  /// [dayRange] - Number of days to include (null = all time)
  Future<Result<ClientMuscleMapEntity>> getClientMuscleMap({
    required String clientId,
    int? dayRange,
  });

  /// Get muscle activity for a single session
  ///
  /// [sessionId] - The session to get data for
  Future<Result<SessionMuscleActivity>> getSessionMuscleActivity({
    required String sessionId,
  });

  /// Get historical muscle activity data for trends
  ///
  /// [clientId] - The client to get data for
  /// [fromDate] - Start date
  /// [toDate] - End date
  Future<Result<List<SessionMuscleActivity>>> getMuscleHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  /// Get exercises filtered by muscle group
  ///
  /// [muscleGroup] - The muscle group to filter by
  Future<Result<List<String>>> getExerciseIdsByMuscleGroup({
    required MuscleGroup muscleGroup,
  });
}
