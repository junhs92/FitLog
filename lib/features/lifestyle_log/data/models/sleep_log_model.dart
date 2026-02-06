import '../../domain/entities/sleep_log_entity.dart';

/// Data model for sleep logs with JSON serialization
class SleepLogModel extends SleepLogEntity {
  const SleepLogModel({
    required super.id,
    required super.clientId,
    required super.logDate,
    super.bedtime,
    super.wakeTime,
    super.quality,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON map
  factory SleepLogModel.fromJson(Map<String, dynamic> json) {
    return SleepLogModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      bedtime: json['bedtime'] != null
          ? DateTime.parse(json['bedtime'] as String)
          : null,
      wakeTime: json['wake_time'] != null
          ? DateTime.parse(json['wake_time'] as String)
          : null,
      quality: json['quality'] != null
          ? _qualityFromInt(json['quality'] as int)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'bedtime': bedtime?.toIso8601String(),
      'wake_time': wakeTime?.toIso8601String(),
      'quality': quality != null ? _qualityToInt(quality!) : null,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from entity
  factory SleepLogModel.fromEntity(SleepLogEntity entity) {
    return SleepLogModel(
      id: entity.id,
      clientId: entity.clientId,
      logDate: entity.logDate,
      bedtime: entity.bedtime,
      wakeTime: entity.wakeTime,
      quality: entity.quality,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert integer (1-4) to SleepQuality enum
  static SleepQuality _qualityFromInt(int value) {
    switch (value) {
      case 1:
        return SleepQuality.poor;
      case 2:
        return SleepQuality.fair;
      case 3:
        return SleepQuality.good;
      case 4:
        return SleepQuality.excellent;
      default:
        return SleepQuality.fair;
    }
  }

  /// Convert SleepQuality enum to integer (1-4)
  static int _qualityToInt(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return 1;
      case SleepQuality.fair:
        return 2;
      case SleepQuality.good:
        return 3;
      case SleepQuality.excellent:
        return 4;
    }
  }
}
