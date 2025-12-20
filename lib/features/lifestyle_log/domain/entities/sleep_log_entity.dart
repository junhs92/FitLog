import 'package:equatable/equatable.dart';

/// Sleep quality rating
enum SleepQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Entity representing a sleep log entry
class SleepLogEntity extends Equatable {
  final String id;
  final String clientId;
  final DateTime logDate;
  final DateTime? bedtime;
  final DateTime? wakeTime;
  final SleepQuality? quality;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SleepLogEntity({
    required this.id,
    required this.clientId,
    required this.logDate,
    this.bedtime,
    this.wakeTime,
    this.quality,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate sleep duration
  Duration? get duration {
    if (bedtime == null || wakeTime == null) return null;
    return wakeTime!.difference(bedtime!);
  }

  /// Duration in hours for display
  double? get durationHours {
    final dur = duration;
    if (dur == null) return null;
    return dur.inMinutes / 60;
  }

  /// Display string for duration (e.g., "7h 30m")
  String? get durationDisplay {
    final dur = duration;
    if (dur == null) return null;
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Quality display name
  String? get qualityName {
    switch (quality) {
      case SleepQuality.poor:
        return 'Poor';
      case SleepQuality.fair:
        return 'Fair';
      case SleepQuality.good:
        return 'Good';
      case SleepQuality.excellent:
        return 'Excellent';
      case null:
        return null;
    }
  }

  /// Quality emoji
  String? get qualityEmoji {
    switch (quality) {
      case SleepQuality.poor:
        return '😫';
      case SleepQuality.fair:
        return '😐';
      case SleepQuality.good:
        return '😊';
      case SleepQuality.excellent:
        return '😴';
      case null:
        return null;
    }
  }

  /// Quality color value (for UI)
  int get qualityColorValue {
    switch (quality) {
      case SleepQuality.poor:
        return 0xFFE53935; // Red
      case SleepQuality.fair:
        return 0xFFFFA726; // Orange
      case SleepQuality.good:
        return 0xFF66BB6A; // Green
      case SleepQuality.excellent:
        return 0xFF42A5F5; // Blue
      case null:
        return 0xFF9E9E9E; // Grey
    }
  }

  SleepLogEntity copyWith({
    String? id,
    String? clientId,
    DateTime? logDate,
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepLogEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      logDate: logDate ?? this.logDate,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        logDate,
        bedtime,
        wakeTime,
        quality,
        notes,
        createdAt,
        updatedAt,
      ];
}
