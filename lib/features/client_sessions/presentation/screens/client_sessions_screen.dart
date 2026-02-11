import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/session_entity.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../providers/client_session_provider.dart';
import '../widgets/client_session_card.dart';
import '../widgets/session_summary_card.dart';

/// Client sessions screen with calendar view and session list
class ClientSessionsScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientSessionsScreen({required this.clientId, super.key});

  @override
  ConsumerState<ClientSessionsScreen> createState() => _ClientSessionsScreenState();
}

class _ClientSessionsScreenState extends ConsumerState<ClientSessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(clientSessionsCalendarProvider);
    final sessionsAsync = ref.watch(clientAllSessionsProvider(widget.clientId));
    final selectedDaySessions = ref.watch(clientSelectedDaySessionsProvider(widget.clientId));
    final packageAsync = ref.watch(clientSessionPackageSummaryProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          // Today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              ref.read(clientSessionsCalendarProvider.notifier).goToToday();
            },
          ),
          // View mode selector
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_module),
            tooltip: 'View mode',
            onSelected: (mode) {
              ref.read(clientSessionsCalendarProvider.notifier).setViewMode(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarViewMode.month,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_month,
                      color: calendarState.viewMode == CalendarViewMode.month
                          ? AppColors.primary
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Month'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarViewMode.week,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      color: calendarState.viewMode == CalendarViewMode.week
                          ? AppColors.primary
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Week'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Session summary card
          packageAsync.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SessionSummaryCard(summary: summary),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Calendar view
          _ClientCalendarView(
            clientId: widget.clientId,
            calendarState: calendarState,
          ),

          // Divider
          const Divider(height: 1),

          // Loading indicator
          if (sessionsAsync.isLoading) const LinearProgressIndicator(),

          // Error message
          if (sessionsAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Error loading sessions: ${sessionsAsync.error}',
                style: TextStyle(color: AppColors.error),
              ),
            ),

          // Agenda section
          Expanded(
            child: _buildAgendaSection(
              context,
              calendarState.selectedDay,
              selectedDaySessions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaSection(
    BuildContext context,
    DateTime? selectedDay,
    List<SessionEntity> sessions,
  ) {
    final displayDate = selectedDay ?? DateTime.now();
    final isToday = _isSameDay(displayDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(displayDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isToday) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
            ],
          ),
        ),

        // Session list
        Expanded(
          child: sessions.isEmpty
              ? NoSessionsForDay(date: displayDate)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ClientSessionCard(
                      session: session,
                      onTap: () => _showSessionDetails(context, session),
                      onViewReport: () => _navigateToReport(context, session),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showSessionDetails(BuildContext context, SessionEntity session) {
    // For completed sessions with report, go to report
    // Otherwise, show session details sheet
    if (session.status == SessionStatus.completed) {
      _navigateToReport(context, session);
    } else {
      _showSessionDetailsSheet(context, session);
    }
  }

  void _navigateToReport(BuildContext context, SessionEntity session) {
    // Navigate to session report screen - it will load the report by session ID
    context.push('/client/session-report/${session.id}');
  }

  void _showSessionDetailsSheet(BuildContext context, SessionEntity session) {
    final sessionDate = session.scheduledAt ?? session.startedAt ?? session.createdAt;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Session info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PT Session',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        session.status.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(session.status),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Date and time
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMMM d, yyyy').format(sessionDate.toLocal()),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              context,
              Icons.access_time,
              'Time',
              DateFormat('h:mm a').format(sessionDate.toLocal()),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.neutral600),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return AppColors.primary;
      case SessionStatus.active:
        return AppColors.secondary;
      case SessionStatus.completed:
        return AppColors.success;
      case SessionStatus.cancelled:
        return AppColors.neutral500;
      case SessionStatus.noShow:
        return AppColors.error;
    }
  }
}

/// Calendar view widget for client sessions
class _ClientCalendarView extends ConsumerWidget {
  final String clientId;
  final ClientSessionsCalendarState calendarState;

  const _ClientCalendarView({
    required this.clientId,
    required this.calendarState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsByDay = ref.watch(clientSessionsByDayProvider(clientId));

    return TableCalendar<SessionEntity>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: calendarState.focusedDay,
      selectedDayPredicate: (day) {
        return calendarState.selectedDay != null &&
            isSameDay(calendarState.selectedDay, day);
      },
      calendarFormat: _mapViewModeToFormat(calendarState.viewMode),
      eventLoader: (day) {
        final dayKey = DateTime(day.year, day.month, day.day);
        return sessionsByDay[dayKey] ?? [];
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        // Today styling
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
        // Selected styling
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: AppColors.neutralWhite,
          fontWeight: FontWeight.bold,
        ),
        // Default styling
        defaultTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
        outsideTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
        ),
        // Markers
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersAnchor: 0.7,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: AppColors.primary,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: AppColors.primary,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral600,
            ),
        weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral500,
            ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(clientSessionsCalendarProvider.notifier).setSelectedDay(selectedDay);
        ref.read(clientSessionsCalendarProvider.notifier).setFocusedDay(focusedDay);
      },
      onPageChanged: (focusedDay) {
        ref.read(clientSessionsCalendarProvider.notifier).setFocusedDay(focusedDay);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return _buildMarkers(events);
        },
      ),
    );
  }

  CalendarFormat _mapViewModeToFormat(CalendarViewMode viewMode) {
    switch (viewMode) {
      case CalendarViewMode.month:
        return CalendarFormat.month;
      case CalendarViewMode.week:
        return CalendarFormat.week;
      case CalendarViewMode.day:
        return CalendarFormat.week;
    }
  }

  Widget _buildMarkers(List<SessionEntity> events) {
    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: events.take(3).map((event) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(event.status),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return AppColors.primary;
      case SessionStatus.active:
        return AppColors.secondary;
      case SessionStatus.completed:
        return AppColors.success;
      case SessionStatus.cancelled:
        return AppColors.neutral500;
      case SessionStatus.noShow:
        return AppColors.error;
    }
  }
}
