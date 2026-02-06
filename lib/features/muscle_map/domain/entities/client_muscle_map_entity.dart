import 'muscle_group.dart';
import 'muscle_activity_entity.dart';

/// Aggregated muscle activity data for a client over a time period
class ClientMuscleMapEntity {
  /// The client ID this data belongs to
  final String clientId;

  /// When this data was calculated
  final DateTime calculatedAt;

  /// Number of days included in the calculation (7, 14, 30), null = all time
  final int? dayRange;

  /// Activity data for each muscle group
  final Map<MuscleGroup, MuscleActivityEntity> activities;

  const ClientMuscleMapEntity({
    required this.clientId,
    required this.calculatedAt,
    this.dayRange,
    required this.activities,
  });

  /// Creates an empty muscle map with all muscles inactive
  factory ClientMuscleMapEntity.empty(String clientId, {int? dayRange}) {
    final activities = <MuscleGroup, MuscleActivityEntity>{};
    for (final group in MuscleGroup.values) {
      if (group != MuscleGroup.fullBody) {
        activities[group] = MuscleActivityEntity.inactive(group);
      }
    }
    return ClientMuscleMapEntity(
      clientId: clientId,
      calculatedAt: DateTime.now(),
      dayRange: dayRange,
      activities: activities,
    );
  }

  /// Get activity for a specific muscle group
  MuscleActivityEntity? getActivity(MuscleGroup group) => activities[group];

  /// Get intensity for a specific muscle group (0.0 if not found)
  double getIntensity(MuscleGroup group) => activities[group]?.intensity ?? 0.0;

  /// Get all muscles that need attention (5+ days since worked)
  List<MuscleActivityEntity> get musclesNeedingAttention {
    return activities.values
        .where((a) => a.needsAttention)
        .toList()
      ..sort((a, b) => (b.daysSinceWorked ?? 999).compareTo(a.daysSinceWorked ?? 999));
  }

  /// Get all muscles worked recently (within 2 days)
  List<MuscleActivityEntity> get recentlyWorkedMuscles {
    return activities.values
        .where((a) => a.isRecent)
        .toList()
      ..sort((a, b) => b.intensity.compareTo(a.intensity));
  }

  /// Get muscles sorted by intensity (highest first)
  List<MuscleActivityEntity> get sortedByIntensity {
    return activities.values.toList()
      ..sort((a, b) => b.intensity.compareTo(a.intensity));
  }

  /// Get muscles sorted by days since worked (most neglected first)
  List<MuscleActivityEntity> get sortedByNeglect {
    return activities.values.toList()
      ..sort((a, b) {
        final aDays = a.daysSinceWorked ?? 999;
        final bDays = b.daysSinceWorked ?? 999;
        return bDays.compareTo(aDays);
      });
  }

  /// Get the maximum intensity across all muscles
  double get maxIntensity {
    if (activities.isEmpty) return 0.0;
    return activities.values
        .map((a) => a.intensity)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get total session count across all muscles
  int get totalSessions {
    return activities.values
        .map((a) => a.sessionCount)
        .fold(0, (a, b) => a + b);
  }

  /// Get front-view muscle activities
  Map<MuscleGroup, MuscleActivityEntity> get frontViewActivities {
    return Map.fromEntries(
      activities.entries.where((e) => e.key.isFrontView),
    );
  }

  /// Get back-view muscle activities
  Map<MuscleGroup, MuscleActivityEntity> get backViewActivities {
    return Map.fromEntries(
      activities.entries.where((e) => !e.key.isFrontView),
    );
  }

  ClientMuscleMapEntity copyWith({
    String? clientId,
    DateTime? calculatedAt,
    int? dayRange,
    Map<MuscleGroup, MuscleActivityEntity>? activities,
  }) {
    return ClientMuscleMapEntity(
      clientId: clientId ?? this.clientId,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      dayRange: dayRange ?? this.dayRange,
      activities: activities ?? this.activities,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientMuscleMapEntity &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          dayRange == other.dayRange;

  @override
  int get hashCode => clientId.hashCode ^ (dayRange?.hashCode ?? 0);
}

/// Muscle activity data for a single session
class SessionMuscleActivity {
  /// Session ID
  final String sessionId;

  /// Session date
  final DateTime sessionDate;

  /// Muscles worked in this session with their volume
  final Map<MuscleGroup, int> muscleVolumes;

  /// Total number of sets per muscle
  final Map<MuscleGroup, int> muscleSets;

  const SessionMuscleActivity({
    required this.sessionId,
    required this.sessionDate,
    required this.muscleVolumes,
    required this.muscleSets,
  });

  /// Get all muscle groups worked in this session
  List<MuscleGroup> get musclesWorked => muscleVolumes.keys.toList();

  /// Get total volume for this session
  int get totalVolume => muscleVolumes.values.fold(0, (a, b) => a + b);

  /// Get total sets for this session
  int get totalSets => muscleSets.values.fold(0, (a, b) => a + b);
}
