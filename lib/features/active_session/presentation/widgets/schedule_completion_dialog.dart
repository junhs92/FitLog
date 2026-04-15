import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Result from the schedule completion dialog
class ScheduleCompletionResult {
  final DateTime scheduledAt;
  final int durationMinutes;

  const ScheduleCompletionResult({
    required this.scheduledAt,
    required this.durationMinutes,
  });
}

/// Dialog that asks user if they want to add a completed session to the calendar
/// Returns ScheduleCompletionResult if user chooses to add, null if they skip
class ScheduleCompletionDialog extends StatefulWidget {
  final DateTime sessionStartTime;
  final String clientName;

  const ScheduleCompletionDialog({
    required this.sessionStartTime,
    required this.clientName,
    super.key,
  });

  /// Show the dialog and return the result
  static Future<ScheduleCompletionResult?> show(
    BuildContext context, {
    required DateTime sessionStartTime,
    required String clientName,
  }) {
    return showDialog<ScheduleCompletionResult?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleCompletionDialog(
        sessionStartTime: sessionStartTime,
        clientName: clientName,
      ),
    );
  }

  @override
  State<ScheduleCompletionDialog> createState() => _ScheduleCompletionDialogState();
}

class _ScheduleCompletionDialogState extends State<ScheduleCompletionDialog> {
  late TimeOfDay _selectedTime;
  int _durationMinutes = 60;

  static const List<int> _durationOptions = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final suggestedStart = DateTime.now().subtract(const Duration(hours: 1));
    final minute = suggestedStart.minute;
    final roundedMinute = (minute < 15) ? 0 : (minute < 45) ? 30 : 0;
    final roundedHour = (minute >= 45) ? (suggestedStart.hour + 1) % 24 : suggestedStart.hour;
    _selectedTime = TimeOfDay(hour: roundedHour, minute: roundedMinute);
  }

  DateTime get _scheduledDateTime {
    final base = DateTime(
      widget.sessionStartTime.year,
      widget.sessionStartTime.month,
      widget.sessionStartTime.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    // If rounding pushed past midnight (e.g. 23:50 → 0:00), advance to next day
    if (widget.sessionStartTime.toLocal().hour == 23 &&
        _selectedTime.hour == 0) {
      return base.add(const Duration(days: 1));
    }
    return base;
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '${hours}h ${mins}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Add to Calendar?',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No scheduled appointment was found for this session with ${widget.clientName}.',
            style: TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Would you like to add it to the calendar?',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date display
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.event, size: 18, color: AppColors.darkTextTertiary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _formatDate(widget.sessionStartTime),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Time picker
          InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.darkTextTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Duration selector
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkTextTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: _durationOptions.map((duration) {
              final isSelected = duration == _durationMinutes;
              return ChoiceChip(
                label: Text(_formatDuration(duration)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _durationMinutes = duration;
                    });
                  }
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Skip',
            style: TextStyle(color: AppColors.darkTextTertiary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(
              context,
              ScheduleCompletionResult(
                scheduledAt: _scheduledDateTime,
                durationMinutes: _durationMinutes,
              ),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add to Calendar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
