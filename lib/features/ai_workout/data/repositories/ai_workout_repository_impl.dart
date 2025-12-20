import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/workout_program.dart';
import '../../domain/entities/session_feedback.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/repositories/ai_workout_repository.dart';
import '../datasources/ai_workout_remote_datasource.dart';

/// Implementation of AI workout repository
class AIWorkoutRepositoryImpl implements AIWorkoutRepository {
  final AIWorkoutRemoteDataSource _remoteDataSource;

  AIWorkoutRepositoryImpl(this._remoteDataSource);

  @override
  Future<TrainingGoal?> getPreviousGoal(String clientId) async {
    return _remoteDataSource.getPreviousGoal(clientId);
  }

  @override
  Future<Either<Failure, WorkoutProgramEntity>> generateProgram({
    required String clientId,
    required String trainerId,
    required TrainingGoal primaryGoal,
    TrainingGoal? secondaryGoal,
    int? durationWeeks,
    int? sessionsPerWeek,
    List<String>? excludedExerciseIds,
    List<String>? preferredEquipment,
  }) async {
    try {
      final program = await _remoteDataSource.generateProgram(
        clientId: clientId,
        trainerId: trainerId,
        primaryGoal: primaryGoal,
        secondaryGoal: secondaryGoal,
        excludedExerciseIds: excludedExerciseIds,
        preferredEquipment: preferredEquipment,
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
      return Right(program);
    } catch (e) {
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
  Future<Either<Failure, ProgramExerciseEntity>> swapExercise({
    required String programExerciseId,
    required String newExerciseId,
    String? reason,
  }) async {
    try {
      final exercise = await _remoteDataSource.swapExercise(
        programExerciseId: programExerciseId,
        newExerciseId: newExerciseId,
        reason: reason,
      );
      return Right(exercise.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExerciseAlternative>>> getAlternatives({
    required String exerciseId,
    required String clientId,
    DifficultyFeedback? feedbackHint,
  }) async {
    try {
      final alternatives = await _remoteDataSource.getAlternatives(
        exerciseId: exerciseId,
        clientId: clientId,
        feedbackHint: feedbackHint,
      );
      return Right(alternatives);
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
}
