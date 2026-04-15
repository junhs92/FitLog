import '../../domain/entities/session_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';
import 'session_exercise_model.dart';

/// Data model for Session
class SessionModel extends SessionEntity {
  const SessionModel({
    required super.id,
    required super.trainerId,
    required super.clientId,
    super.clientName,
    super.programId,
    required super.status,
    super.sessionType,
    super.exercises,
    super.notes,
    super.overallRating,
    super.trainerFeedback,
    super.scheduledAt,
    super.startedAt,
    super.completedAt,
    super.duration,
    required super.createdAt,
    super.sessionNumber,
    super.focusArea,
    super.daysSinceLast,
    super.aiReasoning,
    super.savedTotalExercises,
    super.savedTotalSets,
    super.savedTotalVolume,
    super.savedAvgReps,
    super.savedAvgRpe,
    super.restSeconds,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    // Parse session status
    SessionStatus status;
    final statusStr = json['status'] as String? ?? 'scheduled';
    switch (statusStr.toLowerCase()) {
      case 'active':
        status = SessionStatus.active;
        break;
      case 'completed':
        status = SessionStatus.completed;
        break;
      case 'cancelled':
        status = SessionStatus.cancelled;
        break;
      case 'no_show':
        status = SessionStatus.noShow;
        break;
      default:
        status = SessionStatus.scheduled;
    }

    // Parse exercises if available and sort by order
    // Explicitly create List<SessionExerciseEntity> to avoid runtime type issues
    final exercisesData = json['session_exercises'] ?? json['exercises'] ?? [];
    final List<SessionExerciseEntity> exercises = <SessionExerciseEntity>[
      for (final e in exercisesData as List)
        SessionExerciseModel.fromJson(e as Map<String, dynamic>),
    ]..sort((a, b) => a.order.compareTo(b.order));

    // Parse duration
    Duration? duration;
    if (json['duration_seconds'] != null) {
      duration = Duration(seconds: json['duration_seconds'] as int);
    }

    // Get client name from nested accounts object if available
    String? clientName;
    if (json['accounts'] is Map<String, dynamic>) {
      clientName = json['accounts']['full_name'] as String?;
    } else {
      clientName = json['client_name'] as String?;
    }

    return SessionModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      clientName: clientName,
      programId: json['program_id'] as String?,
      status: status,
      sessionType: json['session_type'] as String?,
      exercises: exercises,
      notes: json['notes'] as String?,
      overallRating: json['overall_rating'] as int?,
      trainerFeedback: json['trainer_feedback'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      duration: duration,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      sessionNumber: json['session_number'] as int?,
      focusArea: json['focus_area'] as String?,
      daysSinceLast: json['days_since_last'] as int?,
      aiReasoning: json['ai_reasoning'] as String?,
      savedTotalExercises: json['total_exercises'] as int?,
      savedTotalSets: json['total_sets'] as int?,
      savedTotalVolume: (json['total_volume'] as num?)?.toDouble(),
      savedAvgReps: (json['avg_reps'] as num?)?.toDouble(),
      savedAvgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      restSeconds: json['rest_timer_seconds'] as int? ?? 90,
    );
  }

  static String _statusToString(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return 'scheduled';
      case SessionStatus.active:
        return 'active';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.cancelled:
        return 'cancelled';
      case SessionStatus.noShow:
        return 'no_show';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
      'program_id': programId,
      'status': _statusToString(status),
      'session_type': sessionType,
      'notes': notes,
      'overall_rating': overallRating,
      'trainer_feedback': trainerFeedback,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_seconds': duration?.inSeconds,
      'created_at': createdAt.toIso8601String(),
      'session_number': sessionNumber,
      'focus_area': focusArea,
      'days_since_last': daysSinceLast,
      'ai_reasoning': aiReasoning,
      'total_exercises': savedTotalExercises,
      'total_sets': savedTotalSets,
      'total_volume': savedTotalVolume,
      'avg_reps': savedAvgReps,
      'avg_rpe': savedAvgRpe,
      'rest_timer_seconds': restSeconds,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'trainer_id': trainerId,
      'client_id': clientId,
      'program_id': programId,
      'status': _statusToString(status),
      'session_type': sessionType,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
      'session_number': sessionNumber,
      'focus_area': focusArea,
      'days_since_last': daysSinceLast,
      'ai_reasoning': aiReasoning,
    };
  }

  factory SessionModel.fromEntity(SessionEntity entity) {
    return SessionModel(
      id: entity.id,
      trainerId: entity.trainerId,
      clientId: entity.clientId,
      clientName: entity.clientName,
      programId: entity.programId,
      status: entity.status,
      sessionType: entity.sessionType,
      exercises: entity.exercises,
      notes: entity.notes,
      overallRating: entity.overallRating,
      trainerFeedback: entity.trainerFeedback,
      scheduledAt: entity.scheduledAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      duration: entity.duration,
      createdAt: entity.createdAt,
      sessionNumber: entity.sessionNumber,
      focusArea: entity.focusArea,
      daysSinceLast: entity.daysSinceLast,
      aiReasoning: entity.aiReasoning,
      savedTotalExercises: entity.savedTotalExercises,
      savedTotalSets: entity.savedTotalSets,
      savedTotalVolume: entity.savedTotalVolume,
      savedAvgReps: entity.savedAvgReps,
      savedAvgRpe: entity.savedAvgRpe,
      restSeconds: entity.restSeconds,
    );
  }

  SessionEntity toEntity() => this;
}
