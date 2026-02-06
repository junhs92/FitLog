import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/calendar_provider.dart';

/// Calendar view widget wrapping table_calendar
class CalendarView extends ConsumerWidget {
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;
  final void Function(DateTime focusedDay)? onPageChanged;

  const CalendarView({
    this.onDaySelected,
    this.onPageChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final schedulesByDay = ref.watch(schedulesByDayProvider);

    return TableCalendar<ScheduleEntry>(
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
        return schedulesByDay[dayKey] ?? [];
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        // Today styling
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
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
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ),
        outsideTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
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
        ref.read(calendarProvider.notifier).setSelectedDay(selectedDay);
        ref.read(calendarProvider.notifier).setFocusedDay(focusedDay);
        onDaySelected?.call(selectedDay, focusedDay);
      },
      onPageChanged: (focusedDay) {
        ref.read(calendarProvider.notifier).setFocusedDay(focusedDay);
        onPageChanged?.call(focusedDay);
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
        return CalendarFormat.week; // table_calendar doesn't have day view
    }
  }

  Widget _buildMarkers(List<ScheduleEntry> events) {
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

  Color _getStatusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.scheduled:
        return AppColors.primary;
      case ScheduleStatus.completed:
        return AppColors.success;
      case ScheduleStatus.cancelled:
        return AppColors.neutral500;
      case ScheduleStatus.noShow:
        return AppColors.warning;
    }
  }
}
