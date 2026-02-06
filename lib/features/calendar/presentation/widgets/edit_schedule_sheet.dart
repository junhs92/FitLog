import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/calendar_provider.dart';

/// Bottom sheet for editing an existing appointment
class EditScheduleSheet extends ConsumerStatefulWidget {
  final ScheduleEntry schedule;

  const EditScheduleSheet({
    required this.schedule,
    super.key,
  });

  @override
  ConsumerState<EditScheduleSheet> createState() => _EditScheduleSheetState();
}

class _EditScheduleSheetState extends ConsumerState<EditScheduleSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _selectedDuration;
  late ScheduleStatus _selectedStatus;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final localTime = widget.schedule.scheduledAt.toLocal();
    _selectedDate = DateTime(localTime.year, localTime.month, localTime.day);
    _selectedTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
    _selectedDuration = widget.schedule.durationMinutes;
    _selectedStatus = widget.schedule.status;
    _notesController = TextEditingController(text: widget.schedule.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              // Title
              Text(
                'Edit Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Client info (read-only)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: widget.schedule.clientPhotoUrl != null
                          ? NetworkImage(widget.schedule.clientPhotoUrl!)
                          : null,
                      child: widget.schedule.clientPhotoUrl == null
                          ? Text(
                              widget.schedule.clientName.isNotEmpty
                                  ? widget.schedule.clientName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
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
                            widget.schedule.clientName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Client',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.neutral600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Status selection
              Text(
                'Status',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildStatusSelector(),
              const SizedBox(height: AppSpacing.xl),

              // Date selection
              Text(
                'Date',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDateSelector(),
              const SizedBox(height: AppSpacing.lg),

              // Time selection
              Text(
                'Time',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTimeSelector(),
              const SizedBox(height: AppSpacing.lg),

              // Duration selection
              Text(
                'Duration',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDurationSelector(),
              const SizedBox(height: AppSpacing.lg),

              // Notes
              Text(
                'Notes (optional)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Add notes about this appointment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          _selectedTime.format(context),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 30, label: Text('30m')),
        ButtonSegment(value: 45, label: Text('45m')),
        ButtonSegment(value: 60, label: Text('60m')),
        ButtonSegment(value: 90, label: Text('90m')),
      ],
      selected: {_selectedDuration},
      onSelectionChanged: (selection) {
        setState(() => _selectedDuration = selection.first);
      },
    );
  }

  Widget _buildStatusSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ScheduleStatus.values.map((status) {
        final isSelected = _selectedStatus == status;
        final color = _getStatusColor(status);
        return ChoiceChip(
          label: Text(status.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedStatus = status);
            }
          },
          selectedColor: color.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? color : AppColors.neutral600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? color : AppColors.neutral300,
          ),
          avatar: isSelected
              ? Icon(_getStatusIcon(status), size: 18, color: color)
              : null,
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.scheduled:
        return Icons.event;
      case ScheduleStatus.completed:
        return Icons.check_circle;
      case ScheduleStatus.cancelled:
        return Icons.cancel;
      case ScheduleStatus.noShow:
        return Icons.person_off;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
      }
      return;
    }

    // Combine date and time
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Check for trainer schedule conflict (excluding current schedule)
    final conflictResult = await repository.getTrainerScheduleConflict(
      scheduledAt: scheduledAt,
      durationMinutes: _selectedDuration,
      excludeScheduleId: widget.schedule.id,
    );

    final conflictingClientName = conflictResult.fold((_) => null, (value) => value);
    if (conflictingClientName != null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('해당 시간에 이미 $conflictingClientName님의 예약이 있습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final originalStatus = widget.schedule.status;
    final statusChanged = _selectedStatus != originalStatus;

    // First update the schedule details (date, time, duration, notes)
    var result = await repository.updateSchedule(
      scheduleId: widget.schedule.id,
      scheduledAt: scheduledAt,
      durationMinutes: _selectedDuration,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    // If status changed, handle session deduction appropriately
    if (statusChanged && result.isRight()) {
      // Statuses that have already had a session deducted (completed, noShow)
      // Statuses that have NOT had deduction (scheduled, cancelled)
      const deductedStatuses = {ScheduleStatus.completed, ScheduleStatus.noShow};

      final wasDeducted = deductedStatuses.contains(originalStatus);
      final needsDeduction = deductedStatuses.contains(_selectedStatus);

      if (!wasDeducted && needsDeduction) {
        // Changing FROM non-deducted (scheduled/cancelled) TO deducted (completed/noShow)
        // Use repository methods that handle session deduction
        result = switch (_selectedStatus) {
          ScheduleStatus.completed => await repository.markAsCompleted(widget.schedule.id),
          ScheduleStatus.noShow => await repository.markAsNoShow(widget.schedule.id),
          _ => result, // Won't happen due to needsDeduction check
        };
      } else {
        // Either already deducted, or changing to non-deducted status
        // Just update status directly without deduction
        result = await repository.updateSchedule(
          scheduleId: widget.schedule.id,
          status: _selectedStatus,
        );
      }
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${failure.message}')),
          );
        },
        (schedule) {
          // Refresh schedules
          ref.invalidate(schedulesProvider);

          // Close sheet
          Navigator.of(context).pop(true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment updated successfully')),
          );
        },
      );
    }
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

/// Show the edit schedule bottom sheet
Future<bool?> showEditScheduleSheet(
  BuildContext context, {
  required ScheduleEntry schedule,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => EditScheduleSheet(schedule: schedule),
  );
}
