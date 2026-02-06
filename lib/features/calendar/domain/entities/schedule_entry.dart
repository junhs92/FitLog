import 'package:equatable/equatable.dart';

/// Schedule status representing the current state of an appointment
enum ScheduleStatus {
  scheduled,
  completed,
  cancelled,
  noShow,
}

extension ScheduleStatusExtension on ScheduleStatus {
  String get displayName {
    switch (this) {
      case ScheduleStatus.scheduled:
        return 'Scheduled';
      case ScheduleStatus.completed:
        return 'Completed';
      case ScheduleStatus.cancelled:
        return 'Cancelled';
      case ScheduleStatus.noShow:
        return 'No Show';
    }
  }

  /// Convert to database value (snake_case)
  String get dbValue {
    switch (this) {
      case ScheduleStatus.scheduled:
        return 'scheduled';
      case ScheduleStatus.completed:
        return 'completed';
      case ScheduleStatus.cancelled:
        return 'cancelled';
      case ScheduleStatus.noShow:
        return 'no_show';
    }
  }

  /// Parse from database value
  static ScheduleStatus fromDbValue(String value) {
    switch (value) {
      case 'scheduled':
        return ScheduleStatus.scheduled;
      case 'completed':
        return ScheduleStatus.completed;
      case 'cancelled':
        return ScheduleStatus.cancelled;
      case 'no_show':
        return ScheduleStatus.noShow;
      default:
        return ScheduleStatus.scheduled;
    }
  }

  bool get isScheduled => this == ScheduleStatus.scheduled;
  bool get isCompleted => this == ScheduleStatus.completed;
  bool get isCancelled => this == ScheduleStatus.cancelled;
  bool get isNoShow => this == ScheduleStatus.noShow;
}

/// Pure domain entity for a scheduled appointment
class ScheduleEntry extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final DateTime scheduledAt;
  final int durationMinutes;
  final ScheduleStatus status;
  final String? notes;
  final DateTime createdAt;

  const ScheduleEntry({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  /// Get the end time of the appointment
  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));

  /// Check if the appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  /// Check if the appointment is in the past
  bool get isPast => scheduledAt.isBefore(DateTime.now());

  /// Check if the appointment is upcoming (scheduled and not past)
  bool get isUpcoming => status == ScheduleStatus.scheduled && !isPast;

  /// Get formatted duration string
  String get durationDisplay {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${durationMinutes}m';
  }

  ScheduleEntry copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? clientName,
    String? clientPhotoUrl,
    DateTime? scheduledAt,
    int? durationMinutes,
    ScheduleStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhotoUrl: clientPhotoUrl ?? this.clientPhotoUrl,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trainerId,
        clientId,
        scheduledAt,
        status,
      ];
}
