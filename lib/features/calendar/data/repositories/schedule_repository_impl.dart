import 'package:dartz/dartz.dart';

import '../../../../shared/models/result.dart';
import '../../domain/entities/schedule_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';
import '../datasources/session_package_remote_datasource.dart';

/// Implementation of ScheduleRepository
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _scheduleDataSource;
  final SessionPackageRemoteDataSource _packageDataSource;
  final String _trainerId;

  ScheduleRepositoryImpl({
    required ScheduleRemoteDataSource scheduleDataSource,
    required SessionPackageRemoteDataSource packageDataSource,
    required String trainerId,
  })  : _scheduleDataSource = scheduleDataSource,
        _packageDataSource = packageDataSource,
        _trainerId = trainerId;

  @override
  Future<Result<List<ScheduleEntry>>> getSchedulesForRange({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
    List<ScheduleStatus>? statuses,
  }) async {
    try {
      final statusStrings = statuses?.map((s) => s.dbValue).toList();
      final schedules = await _scheduleDataSource.getSchedulesForRange(
        trainerId: _trainerId,
        startDate: startDate,
        endDate: endDate,
        clientIds: clientIds,
        statuses: statusStrings,
      );
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> createSchedule({
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  }) async {
    try {
      final schedule = await _scheduleDataSource.createSchedule(
        trainerId: _trainerId,
        clientId: clientId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        notes: notes,
      );
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> updateSchedule({
    required String scheduleId,
    DateTime? scheduledAt,
    int? durationMinutes,
    ScheduleStatus? status,
    String? notes,
  }) async {
    try {
      final schedule = await _scheduleDataSource.updateSchedule(
        scheduleId: scheduleId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        status: status?.dbValue,
        notes: notes,
      );
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteSchedule(String scheduleId) async {
    try {
      await _scheduleDataSource.deleteSchedule(scheduleId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<Map<DateTime, int>>> getScheduleCountsByDay({
    required DateTime month,
    List<String>? clientIds,
  }) async {
    try {
      // Get first and last day of the month with some buffer for calendar display
      final startDate = DateTime(month.year, month.month - 1, 1);
      final endDate = DateTime(month.year, month.month + 2, 0);

      final counts = await _scheduleDataSource.getScheduleCountsByDay(
        trainerId: _trainerId,
        startDate: startDate,
        endDate: endDate,
        clientIds: clientIds,
      );
      return Right(counts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> markAsCompleted(String scheduleId) async {
    try {
      // Get the schedule first to get client ID
      final schedule = await _scheduleDataSource.getScheduleById(scheduleId);

      // Try to deduct from package (if available)
      await _tryDeductSession(schedule.clientId);

      // Update status
      final updatedSchedule = await _scheduleDataSource.updateStatus(
        scheduleId: scheduleId,
        status: ScheduleStatus.completed.dbValue,
      );
      return Right(updatedSchedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> markAsNoShow(String scheduleId) async {
    try {
      // Get the schedule first to get client ID
      final schedule = await _scheduleDataSource.getScheduleById(scheduleId);

      // Try to deduct from package (if available) - no-show still deducts
      await _tryDeductSession(schedule.clientId);

      // Update status
      final updatedSchedule = await _scheduleDataSource.updateStatus(
        scheduleId: scheduleId,
        status: ScheduleStatus.noShow.dbValue,
      );
      return Right(updatedSchedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> markAsCancelled(String scheduleId) async {
    try {
      // Cancelled does NOT deduct from package
      final updatedSchedule = await _scheduleDataSource.updateStatus(
        scheduleId: scheduleId,
        status: ScheduleStatus.cancelled.dbValue,
      );
      return Right(updatedSchedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> hasConflictingSchedule({
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  }) async {
    try {
      final hasConflict = await _scheduleDataSource.hasConflictingSchedule(
        trainerId: _trainerId,
        clientId: clientId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        excludeScheduleId: excludeScheduleId,
      );
      return Right(hasConflict);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String?>> getTrainerScheduleConflict({
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeScheduleId,
  }) async {
    try {
      final conflictingClientName = await _scheduleDataSource.getTrainerScheduleConflict(
        trainerId: _trainerId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        excludeScheduleId: excludeScheduleId,
      );
      return Right(conflictingClientName);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> checkAndMarkNoShows() async {
    try {
      // Get all overdue scheduled appointments (20+ minutes past)
      final overdueSchedules = await _scheduleDataSource.getOverdueScheduledAppointments(
        trainerId: _trainerId,
      );

      int noShowCount = 0;

      // Mark each as no-show and deduct session
      for (final schedule in overdueSchedules) {
        try {
          // Deduct session from package
          await _tryDeductSession(schedule.clientId);

          // Update status to no_show
          await _scheduleDataSource.updateStatus(
            scheduleId: schedule.id,
            status: ScheduleStatus.noShow.dbValue,
          );

          noShowCount++;
        } catch (_) {
          // Continue with next schedule if one fails
        }
      }

      return Right(noShowCount);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Try to deduct a session from the client's active package
  Future<void> _tryDeductSession(String clientId) async {
    try {
      final activePackage = await _packageDataSource.getActivePackage(
        trainerId: _trainerId,
        clientId: clientId,
      );

      if (activePackage != null && activePackage.sessionsRemaining > 0) {
        await _packageDataSource.deductSession(activePackage.id);
      }
    } catch (_) {
      // Silently fail if no package - still allow status change
    }
  }

  @override
  Future<Result<ScheduleEntry?>> findScheduleForSession({
    required String clientId,
    required DateTime sessionStartTime,
    int toleranceMinutes = 30,
  }) async {
    try {
      final schedule = await _scheduleDataSource.findScheduleForSession(
        trainerId: _trainerId,
        clientId: clientId,
        sessionStartTime: sessionStartTime,
        toleranceMinutes: toleranceMinutes,
      );
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<ScheduleEntry>> createCompletedSchedule({
    required String clientId,
    required DateTime scheduledAt,
    int durationMinutes = 60,
  }) async {
    try {
      // Create the schedule
      final schedule = await _scheduleDataSource.createSchedule(
        trainerId: _trainerId,
        clientId: clientId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
      );

      // Immediately mark as completed (no session deduction since session already deducted)
      final completedSchedule = await _scheduleDataSource.updateStatus(
        scheduleId: schedule.id,
        status: ScheduleStatus.completed.dbValue,
      );

      return Right(completedSchedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
