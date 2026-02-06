import '../../domain/entities/mood_log_entity.dart';

/// Data model for mood logs with JSON serialization
class MoodLogModel extends MoodLogEntity {
  const MoodLogModel({
    required super.id,
    required super.clientId,
    required super.logDate,
    super.mood,
    super.energy,
    super.stressLevel,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON map
  factory MoodLogModel.fromJson(Map<String, dynamic> json) {
    return MoodLogModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      mood: json['mood'] != null
          ? _moodFromInt(json['mood'] as int)
          : null,
      energy: json['energy'] != null
          ? _energyFromInt(json['energy'] as int)
          : null,
      stressLevel: json['stress_level'] as int?,
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
      'mood': mood != null ? _moodToInt(mood!) : null,
      'energy': energy != null ? _energyToInt(energy!) : null,
      'stress_level': stressLevel,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from entity
  factory MoodLogModel.fromEntity(MoodLogEntity entity) {
    return MoodLogModel(
      id: entity.id,
      clientId: entity.clientId,
      logDate: entity.logDate,
      mood: entity.mood,
      energy: entity.energy,
      stressLevel: entity.stressLevel,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert integer (1-5) to MoodLevel enum
  static MoodLevel _moodFromInt(int value) {
    switch (value) {
      case 1:
        return MoodLevel.veryLow;
      case 2:
        return MoodLevel.low;
      case 3:
        return MoodLevel.neutral;
      case 4:
        return MoodLevel.good;
      case 5:
        return MoodLevel.excellent;
      default:
        return MoodLevel.neutral;
    }
  }

  /// Convert MoodLevel enum to integer (1-5)
  static int _moodToInt(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return 1;
      case MoodLevel.low:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.excellent:
        return 5;
    }
  }

  /// Convert integer (1-5) to EnergyLevel enum
  static EnergyLevel _energyFromInt(int value) {
    switch (value) {
      case 1:
        return EnergyLevel.exhausted;
      case 2:
        return EnergyLevel.tired;
      case 3:
        return EnergyLevel.normal;
      case 4:
        return EnergyLevel.energetic;
      case 5:
        return EnergyLevel.veryEnergetic;
      default:
        return EnergyLevel.normal;
    }
  }

  /// Convert EnergyLevel enum to integer (1-5)
  static int _energyToInt(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.exhausted:
        return 1;
      case EnergyLevel.tired:
        return 2;
      case EnergyLevel.normal:
        return 3;
      case EnergyLevel.energetic:
        return 4;
      case EnergyLevel.veryEnergetic:
        return 5;
    }
  }
}
