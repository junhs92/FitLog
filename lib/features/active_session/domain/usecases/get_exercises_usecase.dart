import '../../../../shared/models/result.dart';
import '../entities/exercise_entity.dart';
import '../repositories/session_repository.dart';

/// Parameters for fetching exercises
class GetExercisesParams {
  final String? category;
  final String? movementPattern;
  final String? searchQuery;

  const GetExercisesParams({
    this.category,
    this.movementPattern,
    this.searchQuery,
  });
}

/// Use case for getting exercise library
class GetExercisesUseCase {
  final SessionRepository _repository;

  GetExercisesUseCase(this._repository);

  Future<Result<List<ExerciseEntity>>> call(GetExercisesParams params) {
    return _repository.getExercises(
      category: params.category,
      movementPattern: params.movementPattern,
      searchQuery: params.searchQuery,
    );
  }
}

/// Use case for getting recent exercises
class GetRecentExercisesUseCase {
  final SessionRepository _repository;

  GetRecentExercisesUseCase(this._repository);

  Future<Result<List<ExerciseEntity>>> call({
    required String clientId,
    int limit = 10,
  }) {
    return _repository.getRecentExercises(
      clientId: clientId,
      limit: limit,
    );
  }
}
