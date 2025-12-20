import 'package:equatable/equatable.dart';

/// Mood level enumeration
enum MoodLevel {
  veryLow,
  low,
  neutral,
  good,
  excellent,
}

/// Energy level enumeration
enum EnergyLevel {
  exhausted,
  tired,
  normal,
  energetic,
  veryEnergetic,
}

/// Entity representing a mood/energy log entry
class MoodLogEntity extends Equatable {
  final String id;
  final String clientId;
  final DateTime logDate;
  final MoodLevel? mood;
  final EnergyLevel? energy;
  final int? stressLevel; // 1-10 scale
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MoodLogEntity({
    required this.id,
    required this.clientId,
    required this.logDate,
    this.mood,
    this.energy,
    this.stressLevel,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Mood display name
  String? get moodName {
    switch (mood) {
      case MoodLevel.veryLow:
        return 'Very Low';
      case MoodLevel.low:
        return 'Low';
      case MoodLevel.neutral:
        return 'Neutral';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.excellent:
        return 'Excellent';
      case null:
        return null;
    }
  }

  /// Mood emoji
  String? get moodEmoji {
    switch (mood) {
      case MoodLevel.veryLow:
        return '😢';
      case MoodLevel.low:
        return '😕';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.excellent:
        return '😄';
      case null:
        return null;
    }
  }

  /// Energy display name
  String? get energyName {
    switch (energy) {
      case EnergyLevel.exhausted:
        return 'Exhausted';
      case EnergyLevel.tired:
        return 'Tired';
      case EnergyLevel.normal:
        return 'Normal';
      case EnergyLevel.energetic:
        return 'Energetic';
      case EnergyLevel.veryEnergetic:
        return 'Very Energetic';
      case null:
        return null;
    }
  }

  /// Energy emoji
  String? get energyEmoji {
    switch (energy) {
      case EnergyLevel.exhausted:
        return '🪫';
      case EnergyLevel.tired:
        return '😴';
      case EnergyLevel.normal:
        return '⚡';
      case EnergyLevel.energetic:
        return '💪';
      case EnergyLevel.veryEnergetic:
        return '🔥';
      case null:
        return null;
    }
  }

  /// Mood numeric value (1-5)
  int? get moodValue {
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
      case null:
        return null;
    }
  }

  /// Energy numeric value (1-5)
  int? get energyValue {
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
      case null:
        return null;
    }
  }

  MoodLogEntity copyWith({
    String? id,
    String? clientId,
    DateTime? logDate,
    MoodLevel? mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodLogEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      logDate: logDate ?? this.logDate,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      stressLevel: stressLevel ?? this.stressLevel,
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
        mood,
        energy,
        stressLevel,
        notes,
        createdAt,
        updatedAt,
      ];
}
