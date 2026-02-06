import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../active_session/domain/entities/session_entity.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../../../calendar/domain/entities/session_package.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../ai_report/domain/entities/session_report.dart';
import '../../../ai_report/presentation/providers/report_provider.dart';

/// State for client sessions calendar
class ClientSessionsCalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarViewMode viewMode;
  final bool isLoading;
  final String? error;

  ClientSessionsCalendarState({
    DateTime? focusedDay,
    this.selectedDay,
    this.viewMode = CalendarViewMode.month,
    this.isLoading = false,
    this.error,
  }) : focusedDay = focusedDay ?? DateTime.now();

  ClientSessionsCalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarViewMode? viewMode,
    bool? isLoading,
    String? error,
    bool clearSelectedDay = false,
  }) {
    return ClientSessionsCalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for client sessions calendar
class ClientSessionsCalendarNotifier extends StateNotifier<ClientSessionsCalendarState> {
  ClientSessionsCalendarNotifier() : super(ClientSessionsCalendarState(selectedDay: DateTime.now()));

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  void setSelectedDay(DateTime? day) {
    if (day == null) {
      state = state.copyWith(clearSelectedDay: true);
    } else {
      state = state.copyWith(selectedDay: day);
    }
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void goToToday() {
    final today = DateTime.now();
    state = state.copyWith(focusedDay: today, selectedDay: today);
  }
}

/// Provider for client sessions calendar state
final clientSessionsCalendarProvider =
    StateNotifierProvider<ClientSessionsCalendarNotifier, ClientSessionsCalendarState>((ref) {
  return ClientSessionsCalendarNotifier();
});

/// Provider for all client sessions (completed + scheduled)
final clientAllSessionsProvider = FutureProvider.family<List<SessionEntity>, String>((ref, clientId) async {
  final repository = ref.read(sessionRepositoryProvider);

  final result = await repository.getSessions(clientId: clientId);

  return result.fold(
    (failure) => <SessionEntity>[],
    (sessions) {
      // Sort by date, most recent first
      sessions.sort((a, b) {
        final dateA = a.scheduledAt ?? a.startedAt ?? a.createdAt;
        final dateB = b.scheduledAt ?? b.startedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return sessions;
    },
  );
});

/// Provider for client's scheduled sessions (upcoming)
final clientScheduledSessionsProvider = FutureProvider.family<List<SessionEntity>, String>((ref, clientId) async {
  final allSessions = await ref.watch(clientAllSessionsProvider(clientId).future);
  final now = DateTime.now();

  return allSessions.where((session) {
    // Include sessions that are scheduled (not completed or cancelled)
    if (session.status != SessionStatus.scheduled) return false;

    // Include only future sessions
    final sessionDate = session.scheduledAt ?? session.createdAt;
    return sessionDate.isAfter(now);
  }).toList();
});

/// Provider for client's completed sessions
final clientCompletedSessionsProvider = FutureProvider.family<List<SessionEntity>, String>((ref, clientId) async {
  final allSessions = await ref.watch(clientAllSessionsProvider(clientId).future);

  return allSessions.where((session) {
    return session.status == SessionStatus.completed;
  }).toList();
});

/// Provider for sessions grouped by day (for calendar markers)
final clientSessionsByDayProvider = Provider.family<Map<DateTime, List<SessionEntity>>, String>((ref, clientId) {
  final sessionsAsync = ref.watch(clientAllSessionsProvider(clientId));

  return sessionsAsync.when(
    data: (sessions) {
      final map = <DateTime, List<SessionEntity>>{};
      for (final session in sessions) {
        final sessionDate = session.scheduledAt ?? session.startedAt ?? session.createdAt;
        final localTime = sessionDate.toLocal();
        final dayKey = DateTime(localTime.year, localTime.month, localTime.day);
        map.putIfAbsent(dayKey, () => []).add(session);
      }
      // Sort each day's sessions by time
      for (final entry in map.entries) {
        entry.value.sort((a, b) {
          final timeA = a.scheduledAt ?? a.startedAt ?? a.createdAt;
          final timeB = b.scheduledAt ?? b.startedAt ?? b.createdAt;
          return timeA.compareTo(timeB);
        });
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider for sessions on selected day
final clientSelectedDaySessionsProvider = Provider.family<List<SessionEntity>, String>((ref, clientId) {
  final calendarState = ref.watch(clientSessionsCalendarProvider);
  final sessionsByDay = ref.watch(clientSessionsByDayProvider(clientId));

  if (calendarState.selectedDay == null) return [];

  final dayKey = DateTime(
    calendarState.selectedDay!.year,
    calendarState.selectedDay!.month,
    calendarState.selectedDay!.day,
  );

  return sessionsByDay[dayKey] ?? [];
});

/// Session package summary for client
class ClientSessionPackageSummary {
  final int totalSessions;
  final int completedSessions;
  final int remainingSessions;
  final DateTime? expiresAt;
  final PackageWarningLevel warningLevel;

  const ClientSessionPackageSummary({
    required this.totalSessions,
    required this.completedSessions,
    required this.remainingSessions,
    this.expiresAt,
    required this.warningLevel,
  });

  double get progressPercentage {
    if (totalSessions == 0) return 0;
    return completedSessions / totalSessions;
  }

  bool get hasPackage => totalSessions > 0;
}

/// Provider for client's session package summary
final clientSessionPackageSummaryProvider = FutureProvider.family<ClientSessionPackageSummary, String>((ref, clientId) async {
  // Try to get from session_packages table first
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('session_packages')
        .select()
        .eq('client_id', clientId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final totalSessions = response['total_sessions'] as int? ?? 0;
      final sessionsUsed = response['sessions_used'] as int? ?? 0;
      final expiresAtStr = response['expires_at'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

      final remaining = totalSessions - sessionsUsed;
      PackageWarningLevel warningLevel;

      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        warningLevel = PackageWarningLevel.expired;
      } else if (remaining <= 0) {
        warningLevel = PackageWarningLevel.critical;
      } else if (remaining <= 2) {
        warningLevel = PackageWarningLevel.low;
      } else {
        warningLevel = PackageWarningLevel.none;
      }

      return ClientSessionPackageSummary(
        totalSessions: totalSessions,
        completedSessions: sessionsUsed,
        remainingSessions: remaining,
        expiresAt: expiresAt,
        warningLevel: warningLevel,
      );
    }
  } catch (e) {
    debugPrint('Error fetching session package: $e');
  }

  // Fallback: count from completed sessions
  final completedSessions = await ref.watch(clientCompletedSessionsProvider(clientId).future);

  return ClientSessionPackageSummary(
    totalSessions: 0,
    completedSessions: completedSessions.length,
    remainingSessions: 0,
    warningLevel: PackageWarningLevel.none,
  );
});

/// Provider for report associated with a session
final sessionReportProvider = FutureProvider.family<SessionReportEntity?, String>((ref, sessionId) async {
  final repository = ref.read(reportRepositoryProvider);

  final result = await repository.getSessionReports(sessionId);

  return result.fold(
    (failure) => null,
    (reports) => reports.isNotEmpty ? reports.first : null,
  );
});

/// Provider to mark a report as viewed
final markReportViewedProvider = FutureProvider.family<void, String>((ref, reportId) async {
  final repository = ref.read(reportRepositoryProvider);
  await repository.markAsViewed(reportId);
});
