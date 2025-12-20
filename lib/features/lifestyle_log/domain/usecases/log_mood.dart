import '../../../../shared/models/result.dart';
import '../entities/mood_log_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to log mood and energy
class LogMood {
  final LifestyleRepository _repository;

  LogMood(this._repository);

  /// Log mood and energy
  Future<Result<MoodLogEntity>> call({
    required String clientId,
    required DateTime date,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) {
    return _repository.logMood(
      clientId: clientId,
      date: date,
      mood: mood,
      energy: energy,
      stressLevel: stressLevel,
      notes: notes,
    );
  }

  /// Update mood log
  Future<Result<MoodLogEntity>> update({
    required String moodId,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
  }) {
    return _repository.updateMood(
      moodId: moodId,
      mood: mood,
      energy: energy,
      stressLevel: stressLevel,
      notes: notes,
    );
  }

  /// Get mood for a date
  Future<Result<MoodLogEntity?>> get({
    required String clientId,
    required DateTime date,
  }) {
    return _repository.getMood(
      clientId: clientId,
      date: date,
    );
  }

  /// Get mood history
  Future<Result<List<MoodLogEntity>>> getHistory({
    required String clientId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _repository.getMoodHistory(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
