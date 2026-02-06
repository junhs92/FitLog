import 'muscle_group.dart';

/// Represents the activity level for a specific muscle group
class MuscleActivityEntity {
  /// The muscle group this activity refers to
  final MuscleGroup muscleGroup;

  /// Normalized intensity from 0.0 to 1.0
  /// 0.0 = Not worked recently
  /// 1.0 = Hot/Recently worked with high volume
  final double intensity;

  /// Total volume (weight x reps) in the date range
  final int totalVolume;

  /// Number of sessions that worked this muscle
  final int sessionCount;

  /// Number of sets performed for this muscle
  final int totalSets;

  /// Days since this muscle was last worked (null if never)
  final int? daysSinceWorked;

  /// When this muscle was last worked
  final DateTime? lastWorkedAt;

  const MuscleActivityEntity({
    required this.muscleGroup,
    required this.intensity,
    required this.totalVolume,
    required this.sessionCount,
    required this.totalSets,
    this.daysSinceWorked,
    this.lastWorkedAt,
  });

  /// Creates a default inactive activity for a muscle group
  factory MuscleActivityEntity.inactive(MuscleGroup muscleGroup) {
    return MuscleActivityEntity(
      muscleGroup: muscleGroup,
      intensity: 0.0,
      totalVolume: 0,
      sessionCount: 0,
      totalSets: 0,
      daysSinceWorked: null,
      lastWorkedAt: null,
    );
  }

  /// Whether this muscle needs attention (5+ days since worked)
  bool get needsAttention => daysSinceWorked != null && daysSinceWorked! >= 5;

  /// Whether this muscle was worked recently (within 2 days)
  bool get isRecent => daysSinceWorked != null && daysSinceWorked! <= 2;

  /// Get a status label based on activity
  String get statusLabel {
    if (daysSinceWorked == null) return 'Not worked';
    if (daysSinceWorked! == 0) return 'Today';
    if (daysSinceWorked! == 1) return 'Yesterday';
    if (daysSinceWorked! <= 2) return 'Recent';
    if (daysSinceWorked! <= 4) return 'Active';
    if (daysSinceWorked! <= 7) return 'Needs work';
    return 'Inactive';
  }

  MuscleActivityEntity copyWith({
    MuscleGroup? muscleGroup,
    double? intensity,
    int? totalVolume,
    int? sessionCount,
    int? totalSets,
    int? daysSinceWorked,
    DateTime? lastWorkedAt,
  }) {
    return MuscleActivityEntity(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      intensity: intensity ?? this.intensity,
      totalVolume: totalVolume ?? this.totalVolume,
      sessionCount: sessionCount ?? this.sessionCount,
      totalSets: totalSets ?? this.totalSets,
      daysSinceWorked: daysSinceWorked ?? this.daysSinceWorked,
      lastWorkedAt: lastWorkedAt ?? this.lastWorkedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleActivityEntity &&
          runtimeType == other.runtimeType &&
          muscleGroup == other.muscleGroup &&
          intensity == other.intensity &&
          totalVolume == other.totalVolume &&
          sessionCount == other.sessionCount &&
          totalSets == other.totalSets;

  @override
  int get hashCode =>
      muscleGroup.hashCode ^
      intensity.hashCode ^
      totalVolume.hashCode ^
      sessionCount.hashCode ^
      totalSets.hashCode;
}
