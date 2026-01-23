import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/alternative_exercise.dart';
import '../../domain/repositories/ai_workout_repository.dart';
import '../datasources/ai_workout_remote_datasource.dart';

/// Implementation of AI workout repository
class AIWorkoutRepositoryImpl implements AIWorkoutRepository {
  final AIWorkoutRemoteDataSource _remoteDataSource;

  AIWorkoutRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, WorkoutProgramEntity>> createProgram({
    required String clientId,
    required String trainerId,
    required String name,
    String? description,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    try {
      final program = await _remoteDataSource.createProgram(
        clientId: clientId,
        trainerId: trainerId,
        name: name,
        description: description,
        trainingSplit: trainingSplit,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );
      return Right(program);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutProgramEntity>> getProgram(
    String programId,
  ) async {
    try {
      final program = await _remoteDataSource.getProgram(programId);
      return Right(program);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutProgramEntity>>> getClientPrograms(
    String clientId,
  ) async {
    try {
      final programs = await _remoteDataSource.getClientPrograms(clientId);
      return Right(programs);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutProgramEntity?>> getActiveProgram(
    String clientId,
  ) async {
    try {
      final program = await _remoteDataSource.getActiveProgram(clientId);
      debugPrint('🔍 [Repository] getActiveProgram result: ${program?.id}');
      return Right(program);
    } catch (e, stackTrace) {
      debugPrint('🔴 [Repository] getActiveProgram error: $e');
      debugPrint('🔴 [Repository] Stack: $stackTrace');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async {
    try {
      await _remoteDataSource.updateProgramStatus(
        programId: programId,
        status: status,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutProgramEntity>> updateProgram({
    required String programId,
    String? name,
    String? description,
    TrainingSplit? trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    try {
      final program = await _remoteDataSource.updateProgram(
        programId: programId,
        name: name,
        description: description,
        trainingSplit: trainingSplit,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );
      return Right(program);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProgramLastSessionFocus({
    required String programId,
    required String lastSessionFocus,
  }) async {
    try {
      await _remoteDataSource.updateProgramLastSessionFocus(
        programId: programId,
        lastSessionFocus: lastSessionFocus,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AIExerciseReasoning>> getExerciseReasoning({
    required String exerciseId,
    required String clientId,
    required TrainingGoal goal,
  }) async {
    try {
      final reasoning = await _remoteDataSource.getExerciseReasoning(
        exerciseId: exerciseId,
        clientId: clientId,
        goal: goal,
      );
      return Right(reasoning);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionExerciseFeedback>> recordDifficultyFeedback({
    required String sessionExerciseId,
    required String exerciseId,
    required DifficultyFeedback feedback,
  }) async {
    try {
      final result = await _remoteDataSource.recordDifficultyFeedback(
        sessionExerciseId: sessionExerciseId,
        exerciseId: exerciseId,
        feedback: feedback,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SessionAlternative>>> getSessionAlternatives({
    required String exerciseId,
    required String clientId,
    required DifficultyFeedback feedback,
  }) async {
    try {
      final alternatives = await _remoteDataSource.getSessionAlternatives(
        exerciseId: exerciseId,
        clientId: clientId,
        feedback: feedback,
      );
      return Right(alternatives.map((a) => a.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordSwapHistory({
    required String clientId,
    required String trainerId,
    required String originalExerciseId,
    required String replacementExerciseId,
    DifficultyFeedback? feedbackReason,
    String? customReason,
    String? sessionId,
  }) async {
    try {
      await _remoteDataSource.recordSwapHistory(
        clientId: clientId,
        trainerId: trainerId,
        originalExerciseId: originalExerciseId,
        replacementExerciseId: replacementExerciseId,
        feedbackReason: feedbackReason,
        customReason: customReason,
        sessionId: sessionId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExerciseSwapHistory>>> getSwapHistory({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final history = await _remoteDataSource.getSwapHistory(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProgram(String programId) async {
    try {
      await _remoteDataSource.deleteProgram(programId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GeneratedSessionData>> generateExercisesForProgram({
    required String clientId,
    required String programId,
    required String trainerId,
    required TrainingSplit trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) async {
    try {
      final sessionData = await _remoteDataSource.generateExercisesForProgram(
        clientId: clientId,
        programId: programId,
        trainerId: trainerId,
        trainingSplit: trainingSplit,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );
      return Right(sessionData);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExerciseEntity>>> getSimilarExercises({
    required String exerciseId,
    int limit = 6,
  }) async {
    try {
      final exercises = await _remoteDataSource.getSimilarExercises(
        exerciseId: exerciseId,
        limit: limit,
      );
      return Right(exercises.map((json) => ExerciseEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        nameKo: json['name_ko'] as String?,
        category: json['category'] as String? ?? 'compound',
        movementGroup: json['movement_group'] as String? ?? 'other',
        movementDetail: json['movement_detail'] as String?,
        family: json['family'] as String?,
        angle: json['angle'] as String?,
        equipment: json['equipment'] as String?,
        muscleGroup: json['muscle_group'] as String?,
        description: json['description'] as String?,
        videoUrl: json['video_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        isCustom: json['is_custom'] as bool? ?? false,
        trainerId: json['trainer_id'] as String?,
      )).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AlternativeExercisesResult>> getAlternativeExercises({
    required String exerciseId,
  }) async {
    try {
      final result = await _remoteDataSource.getAlternativeExercises(
        exerciseId: exerciseId,
      );
      return Right(result);
    } catch (e) {
      debugPrint('🔴 [Repository] getAlternativeExercises error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
