import '../../../../shared/models/result.dart';
import '../entities/daily_log_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to get daily lifestyle log
class GetDailyLog {
  final LifestyleRepository _repository;

  GetDailyLog(this._repository);

  /// Get daily log for a specific date
  Future<Result<DailyLogEntity>> call({
    required String clientId,
    required DateTime date,
  }) {
    return _repository.getDailyLog(
      clientId: clientId,
      date: date,
    );
  }

  /// Get daily logs for a date range
  Future<Result<List<DailyLogEntity>>> getRange({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _repository.getDailyLogs(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
