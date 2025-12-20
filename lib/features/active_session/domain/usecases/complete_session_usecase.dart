import '../../../../shared/models/result.dart';
import '../entities/session_entity.dart';
import '../repositories/session_repository.dart';

/// Parameters for completing a session
class CompleteSessionParams {
  final String sessionId;
  final int? overallRating;
  final String? trainerFeedback;

  const CompleteSessionParams({
    required this.sessionId,
    this.overallRating,
    this.trainerFeedback,
  });
}

/// Use case for completing a training session
class CompleteSessionUseCase {
  final SessionRepository _repository;

  CompleteSessionUseCase(this._repository);

  Future<Result<SessionEntity>> call(CompleteSessionParams params) {
    return _repository.completeSession(
      sessionId: params.sessionId,
      overallRating: params.overallRating,
      trainerFeedback: params.trainerFeedback,
    );
  }
}
