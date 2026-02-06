import 'session_exercise_entity.dart';

/// Session status enum
enum SessionStatus {
  scheduled,
  active,
  completed,
  cancelled,
}

extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.active:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == SessionStatus.active;
  bool get isCompleted => this == SessionStatus.completed;
}

/// Training session domain entity
class SessionEntity {
  final String id;
  final String trainerId;
  final String clientId;
  final String? clientName;
  final String? programId; // Associated workout program (training direction)
  final SessionStatus status;
  final String? sessionType;
  final List<SessionExerciseEntity> exercises;
  final String? notes;
  final int? overallRating;
  final String? trainerFeedback;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? duration;
  final DateTime createdAt;

  // AI session generation context
  final int? sessionNumber; // Sequential number within program
  final String? focusArea; // Primary focus (chest, pull, legs, full_body, etc.)
  final int? daysSinceLast; // Gap from previous session
  final String? aiReasoning; // AI explanation for exercise selection

  // Session summary stats (saved on completion)
  final int? savedTotalExercises;
  final int? savedTotalSets;
  final double? savedTotalVolume;
  final double? savedAvgReps;
  final double? savedAvgRpe;

  const SessionEntity({
    required this.id,
    required this.trainerId,
    required this.clientId,
    this.clientName,
    this.programId,
    required this.status,
    this.sessionType,
    this.exercises = const [],
    this.notes,
    this.overallRating,
    this.trainerFeedback,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.duration,
    required this.createdAt,
    this.sessionNumber,
    this.focusArea,
    this.daysSinceLast,
    this.aiReasoning,
    this.savedTotalExercises,
    this.savedTotalSets,
    this.savedTotalVolume,
    this.savedAvgReps,
    this.savedAvgRpe,
  });

  /// Get total exercises count
  int get exerciseCount => exercises.length;

  /// Get completed exercises count
  int get completedExerciseCount =>
      exercises.where((e) => e.isCompleted).length;

  /// Get total sets count
  int get totalSetsCount =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Get total volume across all exercises
  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolume);

  /// Get PR count in this session
  int get prCount => exercises.fold(0, (sum, e) => sum + (e.hasPR ? 1 : 0));

  /// Calculate session duration
  Duration? get calculatedDuration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Get formatted duration string
  String get durationDisplay {
    final dur = duration ?? calculatedDuration;
    if (dur == null) return '-';
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Check if session is in progress
  bool get isInProgress => status == SessionStatus.active;

  /// Get progress percentage
  double get progress {
    if (exercises.isEmpty) return 0;
    return completedExerciseCount / exerciseCount;
  }

  SessionEntity copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? clientName,
    String? programId,
    SessionStatus? status,
    String? sessionType,
    List<SessionExerciseEntity>? exercises,
    String? notes,
    int? overallRating,
    String? trainerFeedback,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? duration,
    DateTime? createdAt,
    int? sessionNumber,
    String? focusArea,
    int? daysSinceLast,
    String? aiReasoning,
    int? savedTotalExercises,
    int? savedTotalSets,
    double? savedTotalVolume,
    double? savedAvgReps,
    double? savedAvgRpe,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      programId: programId ?? this.programId,
      status: status ?? this.status,
      sessionType: sessionType ?? this.sessionType,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      overallRating: overallRating ?? this.overallRating,
      trainerFeedback: trainerFeedback ?? this.trainerFeedback,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      focusArea: focusArea ?? this.focusArea,
      daysSinceLast: daysSinceLast ?? this.daysSinceLast,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      savedTotalExercises: savedTotalExercises ?? this.savedTotalExercises,
      savedTotalSets: savedTotalSets ?? this.savedTotalSets,
      savedTotalVolume: savedTotalVolume ?? this.savedTotalVolume,
      savedAvgReps: savedAvgReps ?? this.savedAvgReps,
      savedAvgRpe: savedAvgRpe ?? this.savedAvgRpe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
