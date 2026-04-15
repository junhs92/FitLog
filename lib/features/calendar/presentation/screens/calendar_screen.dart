import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/calendar_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/edit_schedule_sheet.dart';
import '../widgets/quick_schedule_sheet.dart';
import '../widgets/schedule_card.dart';

/// Main calendar screen for trainers to manage appointments
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _hasCheckedNoShows = false;

  @override
  void initState() {
    super.initState();
    // Check for no-shows on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNoShows();
    });
  }

  Future<void> _checkForNoShows() async {
    if (_hasCheckedNoShows) return;
    _hasCheckedNoShows = true;

    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) return;

    final result = await repository.checkAndMarkNoShows();
    result.fold(
      (_) {}, // Ignore errors silently
      (count) {
        if (count > 0 && mounted) {
          // Refresh schedules to show updated statuses
          ref.invalidate(schedulesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count appointment(s) marked as no-show'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final schedulesAsync = ref.watch(schedulesProvider);
    final selectedDaySchedules = ref.watch(selectedDaySchedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          // Today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              ref.read(calendarProvider.notifier).goToToday();
            },
          ),
          // View mode selector
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_module),
            tooltip: 'View mode',
            onSelected: (mode) {
              ref.read(calendarProvider.notifier).setViewMode(mode);
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
          // Calendar view
          const CalendarView(),

          // Divider
          const Divider(height: 1),

          // Loading indicator
          if (schedulesAsync.isLoading)
            const LinearProgressIndicator(),

          // Error message
          if (schedulesAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Error loading schedules: ${schedulesAsync.error}',
                style: TextStyle(color: AppColors.error),
              ),
            ),

          // Agenda section
          Expanded(
            child: _buildAgendaSection(
              context,
              ref,
              calendarState.selectedDay,
              selectedDaySchedules,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickSchedule(context, calendarState.selectedDay),
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
    );
  }

  Widget _buildAgendaSection(
    BuildContext context,
    WidgetRef ref,
    DateTime? selectedDay,
    List<ScheduleEntry> schedules,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                '${schedules.length} appointment${schedules.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
            ],
          ),
        ),

        // Schedule list
        Expanded(
          child: schedules.isEmpty
              ? _buildEmptyState(context, displayDate)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return ScheduleCard(
                      schedule: schedule,
                      onTap: () => context.push('/trainer/clients/${schedule.clientId}'),
                      onStatusChange: (status) => _updateScheduleStatus(
                        ref,
                        schedule,
                        status,
                      ),
                      onDelete: () => _deleteSchedule(context, ref, schedule),
                      onEdit: () => _showEditSchedule(context, schedule),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime date) {
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_available,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isPast ? 'No appointments recorded' : 'No appointments scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.neutral600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isPast
                  ? 'Past appointments will appear here'
                  : 'Tap the button below to schedule an appointment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showQuickSchedule(BuildContext context, DateTime? selectedDay) {
    showQuickScheduleSheet(
      context,
      initialDate: selectedDay,
    );
  }

  void _showScheduleDetails(BuildContext context, ScheduleEntry schedule) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ScheduleDetailSheet(schedule: schedule),
    );
  }

  void _showEditSchedule(BuildContext context, ScheduleEntry schedule) {
    showEditScheduleSheet(context, schedule: schedule);
  }

  Future<void> _updateScheduleStatus(
    WidgetRef ref,
    ScheduleEntry schedule,
    ScheduleStatus status,
  ) async {
    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) return;

    final result = switch (status) {
      ScheduleStatus.completed => await repository.markAsCompleted(schedule.id),
      ScheduleStatus.noShow => await repository.markAsNoShow(schedule.id),
      ScheduleStatus.cancelled => await repository.markAsCancelled(schedule.id),
      ScheduleStatus.scheduled => await repository.updateSchedule(
          scheduleId: schedule.id,
          status: status,
        ),
    };

    result.fold(
      (failure) {
        // Error handling done via snackbar in the widget
      },
      (_) {
        // Refresh schedules
        ref.invalidate(schedulesProvider);
      },
    );
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    ScheduleEntry schedule,
  ) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
          'Are you sure you want to delete the appointment with ${schedule.clientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) return;

    final result = await repository.deleteSchedule(schedule.id);

    if (context.mounted) {
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${failure.message}')),
          );
        },
        (_) {
          ref.invalidate(schedulesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted')),
          );
        },
      );
    }
  }
}

/// Bottom sheet showing schedule details
class _ScheduleDetailSheet extends StatelessWidget {
  final ScheduleEntry schedule;

  const _ScheduleDetailSheet({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Client info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: schedule.clientPhotoUrl != null
                    ? NetworkImage(schedule.clientPhotoUrl!)
                    : null,
                child: schedule.clientPhotoUrl == null
                    ? Text(
                        schedule.clientName.isNotEmpty
                            ? schedule.clientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.clientName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      schedule.status.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getStatusColor(schedule.status),
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
            DateFormat('EEEE, MMMM d, yyyy').format(schedule.scheduledAt.toLocal()),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            context,
            Icons.access_time,
            'Time',
            DateFormat('h:mm a').format(schedule.scheduledAt.toLocal()),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            context,
            Icons.timelapse,
            'Duration',
            schedule.durationDisplay,
          ),

          // Notes
          if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
              context,
              Icons.note,
              'Notes',
              schedule.notes!,
            ),
          ],

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
