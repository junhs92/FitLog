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
          ? _moodFromString(json['mood'] as String)
          : null,
      energy: json['energy'] != null
          ? _energyFromString(json['energy'] as String)
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
      'mood': mood != null ? _moodToString(mood!) : null,
      'energy': energy != null ? _energyToString(energy!) : null,
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

  static MoodLevel _moodFromString(String value) {
    switch (value) {
      case 'very_low':
        return MoodLevel.veryLow;
      case 'low':
        return MoodLevel.low;
      case 'neutral':
        return MoodLevel.neutral;
      case 'good':
        return MoodLevel.good;
      case 'excellent':
        return MoodLevel.excellent;
      default:
        return MoodLevel.neutral;
    }
  }

  static String _moodToString(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return 'very_low';
      case MoodLevel.low:
        return 'low';
      case MoodLevel.neutral:
        return 'neutral';
      case MoodLevel.good:
        return 'good';
      case MoodLevel.excellent:
        return 'excellent';
    }
  }

  static EnergyLevel _energyFromString(String value) {
    switch (value) {
      case 'exhausted':
        return EnergyLevel.exhausted;
      case 'tired':
        return EnergyLevel.tired;
      case 'normal':
        return EnergyLevel.normal;
      case 'energetic':
        return EnergyLevel.energetic;
      case 'very_energetic':
        return EnergyLevel.veryEnergetic;
      default:
        return EnergyLevel.normal;
    }
  }

  static String _energyToString(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.exhausted:
        return 'exhausted';
      case EnergyLevel.tired:
        return 'tired';
      case EnergyLevel.normal:
        return 'normal';
      case EnergyLevel.energetic:
        return 'energetic';
      case EnergyLevel.veryEnergetic:
        return 'very_energetic';
    }
  }
}
