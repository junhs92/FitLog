import '../../../../shared/models/result.dart';
import '../entities/schedule_entry.dart';

/// Abstract interface for schedule data operations
abstract class ScheduleRepository {
  /// Get schedules within a date range with optional filters
  Future<Result<List<ScheduleEntry>>> getSchedulesForRange({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
    List<ScheduleStatus>? statuses,
  });

  /// Create a new schedule entry
  Future<Result<ScheduleEntry>> createSchedule({
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  });

  /// Update an existing schedule
  Future<Result<ScheduleEntry>> updateSchedule({
    required String scheduleId,
    DateTime? scheduledAt,
    int? durationMinutes,
    ScheduleStatus? status,
    String? notes,
  });

  /// Delete a schedule
  Future<Result<void>> deleteSchedule(String scheduleId);

  /// Get appointment counts by day for calendar markers
  Future<Result<Map<DateTime, int>>> getScheduleCountsByDay({
    required DateTime month,
    List<String>? clientIds,
  });

  /// Mark a schedule as completed (with optional session deduction)
  Future<Result<ScheduleEntry>> markAsCompleted(String scheduleId);

  /// Mark a schedule as no-show (with session deduction)
  Future<Result<ScheduleEntry>> markAsNoShow(String scheduleId);

  /// Mark a schedule as cancelled
  Future<Result<ScheduleEntry>> markAsCancelled(String scheduleId);

  /// Check if a schedule conflicts with an existing one for the same client
  Future<Result<bool>> hasConflictingSchedule({
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  });

  /// Check if trainer has any schedule at this time (any client)
  /// Returns the conflicting client's name if found, null otherwise
  Future<Result<String?>> getTrainerScheduleConflict({
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  });

  /// Check for and mark no-shows (appointments 20+ min past with no session)
  /// Returns the number of appointments marked as no-show
  Future<Result<int>> checkAndMarkNoShows();

  /// Find a schedule that matches a session's client and time (within tolerance)
  /// Used for auto-completing schedules when sessions are completed
  Future<Result<ScheduleEntry?>> findScheduleForSession({
    required String clientId,
    required DateTime sessionStartTime,
    int toleranceMinutes = 30,
  });

  /// Create a schedule and immediately mark it as completed
  /// Used when a session is completed without a prior schedule
  Future<Result<ScheduleEntry>> createCompletedSchedule({
    required String clientId,
    required DateTime scheduledAt,
    int durationMinutes = 60,
  });
}
