import '../../../../shared/models/result.dart';
import '../entities/exercise_set_entity.dart';
import '../repositories/session_repository.dart';

/// Parameters for logging a set
class LogSetParams {
  final String sessionExerciseId;
  final int setNumber;
  final double? weight;
  final int? reps;
  final double? rpe;
  final Duration? duration;
  final double? distance;
  final List<SetTag> tags;
  final String? notes;

  const LogSetParams({
    required this.sessionExerciseId,
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.duration,
    this.distance,
    this.tags = const [],
    this.notes,
  });
}

/// Use case for logging an exercise set
class LogSetUseCase {
  final SessionRepository _repository;

  LogSetUseCase(this._repository);

  Future<Result<ExerciseSetEntity>> call(LogSetParams params) {
    return _repository.logSet(
      sessionExerciseId: params.sessionExerciseId,
      setNumber: params.setNumber,
      weight: params.weight,
      reps: params.reps,
      rpe: params.rpe,
      duration: params.duration,
      distance: params.distance,
      tags: params.tags,
      notes: params.notes,
    );
  }
}
