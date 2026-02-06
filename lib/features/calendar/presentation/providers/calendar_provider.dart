import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trainer_home/presentation/providers/trainer_home_provider.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/datasources/session_package_remote_datasource.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../data/repositories/session_package_repository_impl.dart';
import '../../domain/entities/schedule_entry.dart';
import '../../domain/entities/schedule_filter.dart';
import '../../domain/entities/session_package.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/session_package_repository.dart';

/// View modes for the calendar display
enum CalendarViewMode {
  month,
  week,
  day,
}

/// Immutable state for the calendar feature
class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarViewMode viewMode;
  final ScheduleFilter filter;
  final bool isLoading;
  final String? error;

  CalendarState({
    DateTime? focusedDay,
    this.selectedDay,
    this.viewMode = CalendarViewMode.month,
    this.filter = const ScheduleFilter(),
    this.isLoading = false,
    this.error,
  }) : focusedDay = focusedDay ?? DateTime.now();

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarViewMode? viewMode,
    ScheduleFilter? filter,
    bool? isLoading,
    String? error,
    bool clearSelectedDay = false,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      viewMode: viewMode ?? this.viewMode,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// State notifier for calendar interactions
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(selectedDay: DateTime.now()));

  /// Set the focused day (when navigating months)
  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  /// Set the selected day (when tapping a date)
  void setSelectedDay(DateTime? day) {
    if (day == null) {
      state = state.copyWith(clearSelectedDay: true);
    } else {
      state = state.copyWith(selectedDay: day);
    }
  }

  /// Change view mode
  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Update filter
  void setFilter(ScheduleFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filter: const ScheduleFilter());
  }

  /// Toggle client in filter
  void toggleClientFilter(String clientId) {
    final currentIds = List<String>.from(state.filter.clientIds);
    if (currentIds.contains(clientId)) {
      currentIds.remove(clientId);
    } else {
      currentIds.add(clientId);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(clientIds: currentIds),
    );
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Navigate to today
  void goToToday() {
    final today = DateTime.now();
    state = state.copyWith(
      focusedDay: today,
      selectedDay: today,
    );
  }
}

// ============================================================================
// Dependency Providers
// ============================================================================

/// Provider for ScheduleRemoteDataSource
final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ScheduleRemoteDataSource(client);
});

/// Provider for SessionPackageRemoteDataSource
final sessionPackageRemoteDataSourceProvider = Provider<SessionPackageRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SessionPackageRemoteDataSource(client);
});

/// Provider for current trainer ID (accounts.id, not auth.uid)
final currentTrainerIdProvider = Provider<String?>((ref) {
  // Use trainerIdProvider which correctly fetches accounts.id
  final trainerIdAsync = ref.watch(trainerIdProvider);
  return trainerIdAsync.valueOrNull;
});

/// Provider for ScheduleRepository
final scheduleRepositoryProvider = Provider<ScheduleRepository?>((ref) {
  final trainerId = ref.watch(currentTrainerIdProvider);
  if (trainerId == null) return null;

  final scheduleDataSource = ref.watch(scheduleRemoteDataSourceProvider);
  final packageDataSource = ref.watch(sessionPackageRemoteDataSourceProvider);

  return ScheduleRepositoryImpl(
    scheduleDataSource: scheduleDataSource,
    packageDataSource: packageDataSource,
    trainerId: trainerId,
  );
});

/// Provider for SessionPackageRepository
final sessionPackageRepositoryProvider = Provider<SessionPackageRepository?>((ref) {
  final trainerId = ref.watch(currentTrainerIdProvider);
  if (trainerId == null) return null;

  final dataSource = ref.watch(sessionPackageRemoteDataSourceProvider);

  return SessionPackageRepositoryImpl(
    dataSource: dataSource,
    trainerId: trainerId,
  );
});

// ============================================================================
// State Providers
// ============================================================================

/// Calendar state provider
final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});

/// Calculate date range based on focused day and view mode
DateTimeRange _calculateDateRange(DateTime focusedDay, CalendarViewMode viewMode) {
  switch (viewMode) {
    case CalendarViewMode.month:
      // Include surrounding weeks for calendar display
      final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
      final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
      // Extend to include partial weeks
      final start = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
      final end = lastDayOfMonth.add(Duration(days: 6 - (lastDayOfMonth.weekday % 7)));
      return DateTimeRange(start: start, end: end);

    case CalendarViewMode.week:
      final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday % 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(start: startOfWeek, end: endOfWeek);

    case CalendarViewMode.day:
      return DateTimeRange(start: focusedDay, end: focusedDay);
  }
}

/// Schedules for current visible range
final schedulesProvider = FutureProvider<List<ScheduleEntry>>((ref) async {
  final calendarState = ref.watch(calendarProvider);
  final repository = ref.watch(scheduleRepositoryProvider);

  if (repository == null) return [];

  final range = _calculateDateRange(
    calendarState.focusedDay,
    calendarState.viewMode,
  );

  final result = await repository.getSchedulesForRange(
    startDate: range.start,
    endDate: range.end,
    clientIds: calendarState.filter.clientIds.isEmpty
        ? null
        : calendarState.filter.clientIds,
    statuses: calendarState.filter.statuses.isEmpty
        ? null
        : calendarState.filter.statuses,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (schedules) => schedules,
  );
});

/// Group schedules by day for calendar markers
final schedulesByDayProvider = Provider<Map<DateTime, List<ScheduleEntry>>>((ref) {
  final schedulesAsync = ref.watch(schedulesProvider);

  return schedulesAsync.when(
    data: (schedules) {
      final map = <DateTime, List<ScheduleEntry>>{};
      for (final schedule in schedules) {
        final localTime = schedule.scheduledAt.toLocal();
        final dayKey = DateTime(localTime.year, localTime.month, localTime.day);
        map.putIfAbsent(dayKey, () => []).add(schedule);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Schedules for selected day (agenda view)
final selectedDaySchedulesProvider = Provider<List<ScheduleEntry>>((ref) {
  final selectedDay = ref.watch(calendarProvider).selectedDay;
  final schedulesByDay = ref.watch(schedulesByDayProvider);

  if (selectedDay == null) return [];

  final dayKey = DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
  );

  final schedules = schedulesByDay[dayKey] ?? [];
  // Sort by time
  schedules.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return schedules;
});

/// Client's active session package
final clientSessionPackageProvider = FutureProvider.family<SessionPackage?, String>((ref, clientId) async {
  final repository = ref.watch(sessionPackageRepositoryProvider);
  if (repository == null) return null;

  final result = await repository.getActivePackage(clientId);
  return result.fold((_) => null, (package) => package);
});

/// Quick check for remaining sessions
final clientSessionsRemainingProvider = Provider.family<int, String>((ref, clientId) {
  final packageAsync = ref.watch(clientSessionPackageProvider(clientId));
  return packageAsync.when(
    data: (package) => package?.sessionsRemaining ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============================================================================
// Session-Schedule Integration Providers
// ============================================================================

/// Parameters for finding a schedule that matches a session
class FindScheduleParams {
  final String clientId;
  final DateTime sessionStartTime;
  final int toleranceMinutes;

  const FindScheduleParams({
    required this.clientId,
    required this.sessionStartTime,
    this.toleranceMinutes = 30,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FindScheduleParams &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          sessionStartTime == other.sessionStartTime &&
          toleranceMinutes == other.toleranceMinutes;

  @override
  int get hashCode =>
      clientId.hashCode ^ sessionStartTime.hashCode ^ toleranceMinutes.hashCode;
}

/// Find a schedule that matches a session's client and time
final findScheduleForSessionProvider = FutureProvider.family<ScheduleEntry?, FindScheduleParams>(
  (ref, params) async {
    final repository = ref.watch(scheduleRepositoryProvider);
    if (repository == null) return null;

    final result = await repository.findScheduleForSession(
      clientId: params.clientId,
      sessionStartTime: params.sessionStartTime,
      toleranceMinutes: params.toleranceMinutes,
    );

    return result.fold((_) => null, (schedule) => schedule);
  },
);

/// Parameters for creating a completed schedule
class CreateCompletedScheduleParams {
  final String clientId;
  final DateTime scheduledAt;
  final int durationMinutes;

  const CreateCompletedScheduleParams({
    required this.clientId,
    required this.scheduledAt,
    this.durationMinutes = 60,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateCompletedScheduleParams &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          scheduledAt == other.scheduledAt &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode =>
      clientId.hashCode ^ scheduledAt.hashCode ^ durationMinutes.hashCode;
}

/// Create a schedule and mark it as completed (for sessions without prior schedules)
final createCompletedScheduleProvider = FutureProvider.family<ScheduleEntry?, CreateCompletedScheduleParams>(
  (ref, params) async {
    final repository = ref.watch(scheduleRepositoryProvider);
    if (repository == null) return null;

    final result = await repository.createCompletedSchedule(
      clientId: params.clientId,
      scheduledAt: params.scheduledAt,
      durationMinutes: params.durationMinutes,
    );

    return result.fold((_) => null, (schedule) => schedule);
  },
);
