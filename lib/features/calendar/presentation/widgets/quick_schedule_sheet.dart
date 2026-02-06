import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../client_management/domain/entities/client_entity.dart';
import '../../../client_management/presentation/providers/client_provider.dart';
import '../../domain/entities/session_package.dart';
import '../providers/calendar_provider.dart';

/// Bottom sheet for quickly scheduling an appointment
class QuickScheduleSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialClientId;

  const QuickScheduleSheet({
    this.initialDate,
    this.initialClientId,
    super.key,
  });

  @override
  ConsumerState<QuickScheduleSheet> createState() => _QuickScheduleSheetState();
}

class _QuickScheduleSheetState extends ConsumerState<QuickScheduleSheet> {
  ClientEntity? _selectedClient;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _selectedDuration = 60;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    final now = DateTime.now();
    _selectedTime = TimeOfDay(hour: now.hour, minute: 0);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

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
                'Schedule Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Client selection
              Text(
                'Client *',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              clientsAsync.when(
                data: (clients) => _buildClientDropdown(clients),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),

              // Remaining sessions display
              if (_selectedClient != null) _buildRemainingSessions(),

              const SizedBox(height: AppSpacing.lg),

              // Date selection
              Text(
                'Date *',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDateSelector(),
              const SizedBox(height: AppSpacing.lg),

              // Time selection
              Text(
                'Time *',
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

              // Submit button
              FilledButton(
                onPressed: _isSubmitting || _selectedClient == null
                    ? null
                    : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Schedule'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientDropdown(List<ClientEntity> clients) {
    // Initialize with initial client if provided
    if (widget.initialClientId != null && _selectedClient == null) {
      final initial = clients.where((c) => c.id == widget.initialClientId).firstOrNull;
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _selectedClient = initial);
        });
      }
    }

    return DropdownButtonFormField<ClientEntity>(
      value: _selectedClient,
      decoration: const InputDecoration(
        hintText: 'Select client...',
        border: OutlineInputBorder(),
      ),
      items: clients.map((client) {
        return DropdownMenuItem(
          value: client,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: client.profilePhotoUrl != null
                    ? NetworkImage(client.profilePhotoUrl!)
                    : null,
                child: client.profilePhotoUrl == null
                    ? Text(
                        client.initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(client.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (client) {
        setState(() => _selectedClient = client);
      },
    );
  }

  Widget _buildRemainingSessions() {
    final clientId = _selectedClient!.id;
    final remainingSessions = ref.watch(clientSessionsRemainingProvider(clientId));

    // Determine color based on remaining sessions
    final Color color;
    final IconData icon;
    if (remainingSessions == 0) {
      color = AppColors.error;
      icon = Icons.warning_amber;
    } else if (remainingSessions <= 2) {
      color = AppColors.warning;
      icon = Icons.warning_amber;
    } else {
      color = AppColors.primary;
      icon = Icons.confirmation_number_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '남은 세션: $remainingSessions회',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
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
    if (_selectedClient == null) return;

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

    // Check for trainer schedule conflict (any client at this time)
    final conflictResult = await repository.getTrainerScheduleConflict(
      scheduledAt: scheduledAt,
      durationMinutes: _selectedDuration,
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

    final result = await repository.createSchedule(
      clientId: _selectedClient!.id,
      scheduledAt: scheduledAt,
      durationMinutes: _selectedDuration,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

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
            const SnackBar(content: Text('Appointment scheduled successfully')),
          );
        },
      );
    }
  }
}

/// Show the quick schedule bottom sheet
Future<bool?> showQuickScheduleSheet(
  BuildContext context, {
  DateTime? initialDate,
  String? initialClientId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => QuickScheduleSheet(
      initialDate: initialDate,
      initialClientId: initialClientId,
    ),
  );
}
