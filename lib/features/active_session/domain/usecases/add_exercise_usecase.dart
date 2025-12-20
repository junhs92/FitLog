import '../../../../shared/models/result.dart';
import '../entities/exercise_entity.dart';
import '../entities/session_exercise_entity.dart';
import '../repositories/session_repository.dart';

/// Parameters for adding an exercise to session
class AddExerciseParams {
  final String sessionId;
  final ExerciseEntity exercise;
  final int? order;

  const AddExerciseParams({
    required this.sessionId,
    required this.exercise,
    this.order,
  });
}

/// Use case for adding an exercise to the active session
class AddExerciseUseCase {
  final SessionRepository _repository;

  AddExerciseUseCase(this._repository);

  Future<Result<SessionExerciseEntity>> call(AddExerciseParams params) {
    return _repository.addExerciseToSession(
      sessionId: params.sessionId,
      exercise: params.exercise,
      order: params.order,
    );
  }
}
