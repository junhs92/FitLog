import '../../../../shared/models/result.dart';
import '../entities/sleep_log_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to log sleep data
class LogSleep {
  final LifestyleRepository _repository;

  LogSleep(this._repository);

  /// Log sleep data
  Future<Result<SleepLogEntity>> call({
    required String clientId,
    required DateTime date,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) {
    return _repository.logSleep(
      clientId: clientId,
      date: date,
      bedtime: bedtime,
      wakeTime: wakeTime,
      quality: quality,
      notes: notes,
    );
  }

  /// Update sleep log
  Future<Result<SleepLogEntity>> update({
    required String sleepId,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
  }) {
    return _repository.updateSleep(
      sleepId: sleepId,
      bedtime: bedtime,
      wakeTime: wakeTime,
      quality: quality,
      notes: notes,
    );
  }

  /// Get sleep for a date
  Future<Result<SleepLogEntity?>> get({
    required String clientId,
    required DateTime date,
  }) {
    return _repository.getSleep(
      clientId: clientId,
      date: date,
    );
  }

  /// Get sleep history
  Future<Result<List<SleepLogEntity>>> getHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _repository.getSleepHistory(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
