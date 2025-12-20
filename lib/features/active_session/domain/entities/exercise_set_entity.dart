/// Quick tags that can be applied to sets
enum SetTag {
  pr,
  formIssue,
  pain,
  fatigue,
  goodCondition,
  warmup,
  dropSet,
  failureSet,
}

extension SetTagExtension on SetTag {
  String get displayName {
    switch (this) {
      case SetTag.pr:
        return 'PR';
      case SetTag.formIssue:
        return 'Form Issue';
      case SetTag.pain:
        return 'Pain';
      case SetTag.fatigue:
        return 'Fatigue';
      case SetTag.goodCondition:
        return 'Good';
      case SetTag.warmup:
        return 'Warmup';
      case SetTag.dropSet:
        return 'Drop Set';
      case SetTag.failureSet:
        return 'Failure';
    }
  }

  String get emoji {
    switch (this) {
      case SetTag.pr:
        return '🏆';
      case SetTag.formIssue:
        return '⚠️';
      case SetTag.pain:
        return '🤕';
      case SetTag.fatigue:
        return '😓';
      case SetTag.goodCondition:
        return '💪';
      case SetTag.warmup:
        return '🔥';
      case SetTag.dropSet:
        return '⬇️';
      case SetTag.failureSet:
        return '💀';
    }
  }
}

/// Individual exercise set within a session
class ExerciseSetEntity {
  final String id;
  final String sessionExerciseId;
  final int setNumber;
  final double? weight;
  final int? reps;
  final double? rpe;
  final Duration? duration;
  final double? distance;
  final List<SetTag> tags;
  final String? notes;
  final DateTime completedAt;

  const ExerciseSetEntity({
    required this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.duration,
    this.distance,
    this.tags = const [],
    this.notes,
    required this.completedAt,
  });

  /// Calculate estimated 1RM using Epley formula
  double? get estimated1RM {
    if (weight == null || reps == null || reps! <= 0) return null;
    if (reps == 1) return weight;
    return weight! * (1 + reps! / 30);
  }

  /// Calculate volume (weight * reps)
  double? get volume {
    if (weight == null || reps == null) return null;
    return weight! * reps!;
  }

  /// Check if this is a PR set
  bool get isPR => tags.contains(SetTag.pr);

  /// Check if this is a warmup set
  bool get isWarmup => tags.contains(SetTag.warmup);

  /// Get RPE display string
  String get rpeDisplay {
    if (rpe == null) return '-';
    return rpe!.toStringAsFixed(rpe! % 1 == 0 ? 0 : 1);
  }

  ExerciseSetEntity copyWith({
    String? id,
    String? sessionExerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    Duration? duration,
    double? distance,
    List<SetTag>? tags,
    String? notes,
    DateTime? completedAt,
  }) {
    return ExerciseSetEntity(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
