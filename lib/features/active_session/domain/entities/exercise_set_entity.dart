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

/// PR type for tracking different types of personal records
enum PrType {
  weight,
  volume,
  reps,
}

extension PrTypeExtension on PrType {
  String get displayName {
    switch (this) {
      case PrType.weight:
        return 'Weight PR';
      case PrType.volume:
        return 'Volume PR';
      case PrType.reps:
        return 'Reps PR';
    }
  }

  String get id {
    switch (this) {
      case PrType.weight:
        return 'weight';
      case PrType.volume:
        return 'volume';
      case PrType.reps:
        return 'reps';
    }
  }

  static PrType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'weight':
        return PrType.weight;
      case 'volume':
        return PrType.volume;
      case 'reps':
        return PrType.reps;
      default:
        return null;
    }
  }
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
  final PrType? prType;
  final String? notes;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.prType,
    this.notes,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
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
    PrType? prType,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      prType: prType ?? this.prType,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
