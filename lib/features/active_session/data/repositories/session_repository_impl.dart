import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/result.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../models/session_exercise_input.dart';

/// Implementation of SessionRepository
class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remoteDataSource;

  SessionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<SessionEntity>>> getSessions({
    String? clientId,
    SessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    bool asClient = false,
  }) async {
    try {
      final sessions = await _remoteDataSource.getSessions(
        clientId: clientId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        asClient: asClient,
      );
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity>> getSessionById(String sessionId) async {
    try {
      final session = await _remoteDataSource.getSessionById(sessionId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity?>> getActiveSession(String clientId) async {
    try {
      final session = await _remoteDataSource.getActiveSession(clientId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity>> startSession({
    required String clientId,
    String? sessionType,
    String? notes,
    String? programId,
    List<Map<String, dynamic>>? exercises,
    String? aiReasoning,
  }) async {
    try {
      final session = await _remoteDataSource.startSession(
        clientId: clientId,
        sessionType: sessionType,
        notes: notes,
        programId: programId,
        exercises: exercises,
        aiReasoning: aiReasoning,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity>> activateSession({
    required String sessionId,
    List<Map<String, dynamic>>? exercises,
  }) async {
    try {
      final session = await _remoteDataSource.activateSession(
        sessionId: sessionId,
        exercises: exercises,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity>> createSession({
    required String clientId,
    List<SessionExerciseInput>? exercises,
    String? programId,
    String? existingSessionId,
    String? aiReasoning,
  }) async {
    try {
      final session = await _remoteDataSource.createSession(
        clientId: clientId,
        exercises: exercises,
        programId: programId,
        existingSessionId: existingSessionId,
        aiReasoning: aiReasoning,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionEntity>> completeSession({
    required String sessionId,
    int? overallRating,
    String? trainerFeedback,
  }) async {
    try {
      final session = await _remoteDataSource.completeSession(
        sessionId: sessionId,
        overallRating: overallRating,
        trainerFeedback: trainerFeedback,
      );
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> cancelSession(String sessionId) async {
    try {
      await _remoteDataSource.cancelSession(sessionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionExerciseEntity>> addExerciseToSession({
    required String sessionId,
    required ExerciseEntity exercise,
    int? order,
  }) async {
    try {
      final sessionExercise = await _remoteDataSource.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exercise.id,
        order: order,
      );
      return Right(sessionExercise);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionExerciseEntity>> addExerciseToSessionById({
    required String sessionId,
    required String exerciseId,
    int? order,
  }) async {
    try {
      final sessionExercise = await _remoteDataSource.addExerciseToSession(
        sessionId: sessionId,
        exerciseId: exerciseId,
        order: order,
      );
      return Right(sessionExercise);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeExerciseFromSession(
      String sessionExerciseId) async {
    try {
      await _remoteDataSource.removeExerciseFromSession(sessionExerciseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> reorderExercises({
    required String sessionId,
    required List<String> exerciseIds,
  }) async {
    try {
      await _remoteDataSource.reorderExercises(
        sessionId: sessionId,
        exerciseIds: exerciseIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ExerciseSetEntity>> logSet({
    required String sessionExerciseId,
    required int setNumber,
    double? weight,
    int? reps,
    double? rpe,
    Duration? duration,
    double? distance,
    List<SetTag> tags = const [],
    List<String> comments = const [],
    String? notes,
  }) async {
    try {
      final tagStrings = tags.map(_tagToString).toList();
      final set = await _remoteDataSource.logSet(
        sessionExerciseId: sessionExerciseId,
        setNumber: setNumber,
        weight: weight,
        reps: reps,
        rpe: rpe,
        durationSeconds: duration?.inSeconds,
        distance: distance,
        tags: tagStrings,
        comments: comments,
        notes: notes,
      );
      return Right(set);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final tagStrings = tags?.map(_tagToString).toList();
      final set = await _remoteDataSource.updateSet(
        setId: setId,
        sessionExerciseId: sessionExerciseId,
        weight: weight,
        reps: reps,
        rpe: rpe,
        durationSeconds: duration?.inSeconds,
        distance: distance,
        tags: tagStrings,
        notes: notes,
      );
      return Right(set);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteSet({
    required String setId,
    required String sessionExerciseId,
  }) async {
    try {
      await _remoteDataSource.deleteSet(
        setId: setId,
        sessionExerciseId: sessionExerciseId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> completeExercise(String sessionExerciseId) async {
    try {
      await _remoteDataSource.completeExercise(sessionExerciseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    try {
      await _remoteDataSource.updateSessionNotes(
        sessionId: sessionId,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateSessionExerciseNotes({
    required String sessionExerciseId,
    required String notes,
  }) async {
    try {
      await _remoteDataSource.updateSessionExerciseNotes(
        sessionExerciseId: sessionExerciseId,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ExerciseEntity>>> getExercises({
    String? category,
    String? movementGroup,
    String? searchQuery,
  }) async {
    try {
      final exercises = await _remoteDataSource.getExercises(
        category: category,
        movementGroup: movementGroup,
        searchQuery: searchQuery,
      );
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ExerciseEntity>>> getRecentExercises({
    required String clientId,
    int limit = 10,
  }) async {
    try {
      final exercises = await _remoteDataSource.getRecentExercises(
        clientId: clientId,
        limit: limit,
      );
      return Right(exercises);
    } catch (e) {
      debugPrint('🔴 [SessionRepo] getRecentExercises error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ExerciseSetEntity>>> getExerciseHistory({
    required String clientId,
    required String exerciseId,
    int limit = 10,
  }) async {
    try {
      final sets = await _remoteDataSource.getExerciseHistory(
        clientId: clientId,
        exerciseId: exerciseId,
        limit: limit,
      );
      return Right(sets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _tagToString(SetTag tag) {
    switch (tag) {
      case SetTag.pr:
        return 'pr';
      case SetTag.formIssue:
        return 'form_issue';
      case SetTag.pain:
        return 'pain';
      case SetTag.fatigue:
        return 'fatigue';
      case SetTag.goodCondition:
        return 'good_condition';
      case SetTag.warmup:
        return 'warmup';
      case SetTag.dropSet:
        return 'drop_set';
      case SetTag.failureSet:
        return 'failure_set';
    }
  }
}
