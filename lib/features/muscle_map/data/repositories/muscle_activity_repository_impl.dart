import 'package:dartz/dartz.dart';
import '../../../../shared/models/result.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/repositories/muscle_activity_repository.dart';
import '../datasources/muscle_activity_remote_datasource.dart';

/// Implementation of MuscleActivityRepository
class MuscleActivityRepositoryImpl implements MuscleActivityRepository {
  final MuscleActivityRemoteDataSource _remoteDataSource;

  MuscleActivityRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<ClientMuscleMapEntity>> getClientMuscleMap({
    required String clientId,
    int? dayRange,
  }) async {
    try {
      final result = await _remoteDataSource.getClientMuscleMap(
        clientId: clientId,
        dayRange: dayRange,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionMuscleActivity>> getSessionMuscleActivity({
    required String sessionId,
  }) async {
    try {
      final result = await _remoteDataSource.getSessionMuscleActivity(
        sessionId: sessionId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<SessionMuscleActivity>>> getMuscleHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final result = await _remoteDataSource.getMuscleHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getExerciseIdsByMuscleGroup({
    required MuscleGroup muscleGroup,
  }) async {
    try {
      final result = await _remoteDataSource.getExerciseIdsByMuscleGroup(
        muscleGroup: muscleGroup,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
