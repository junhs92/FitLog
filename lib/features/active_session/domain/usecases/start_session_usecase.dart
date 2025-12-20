import '../../../../shared/models/result.dart';
import '../entities/session_entity.dart';
import '../repositories/session_repository.dart';

/// Parameters for starting a new session
class StartSessionParams {
  final String clientId;
  final String? sessionType;
  final String? notes;

  const StartSessionParams({
    required this.clientId,
    this.sessionType,
    this.notes,
  });
}

/// Use case for starting a new training session
class StartSessionUseCase {
  final SessionRepository _repository;

  StartSessionUseCase(this._repository);

  Future<Result<SessionEntity>> call(StartSessionParams params) {
    return _repository.startSession(
      clientId: params.clientId,
      sessionType: params.sessionType,
      notes: params.notes,
    );
  }
}
