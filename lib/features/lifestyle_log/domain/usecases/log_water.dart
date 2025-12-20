import '../../../../shared/models/result.dart';
import '../entities/water_log_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to log water intake
class LogWater {
  final LifestyleRepository _repository;

  LogWater(this._repository);

  /// Log water intake
  Future<Result<WaterLogEntity>> call({
    required String clientId,
    required DateTime date,
    required int amountMl,
  }) {
    return _repository.logWater(
      clientId: clientId,
      date: date,
      amountMl: amountMl,
    );
  }

  /// Delete water log entry
  Future<Result<void>> delete(String waterLogId) {
    return _repository.deleteWater(waterLogId);
  }

  /// Get water summary for a date
  Future<Result<DailyWaterSummary>> getSummary({
    required String clientId,
    required DateTime date,
    int goalMl = 2500,
  }) {
    return _repository.getWaterSummary(
      clientId: clientId,
      date: date,
      goalMl: goalMl,
    );
  }

  /// Get water history
  Future<Result<List<DailyWaterSummary>>> getHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
    int goalMl = 2500,
  }) {
    return _repository.getWaterHistory(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
      goalMl: goalMl,
    );
  }
}
