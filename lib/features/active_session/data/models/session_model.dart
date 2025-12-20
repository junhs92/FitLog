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
      default:
        status = SessionStatus.scheduled;
    }

    // Parse exercises if available
    final exercisesData = json['session_exercises'] ?? json['exercises'] ?? [];
    final List<SessionExerciseEntity> exercises = (exercisesData as List)
        .map((e) => SessionExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();

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
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'client_id': clientId,
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
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'trainer_id': trainerId,
      'client_id': clientId,
      'status': _statusToString(status),
      'session_type': sessionType,
      'notes': notes,
      'started_at': startedAt?.toIso8601String(),
    };
  }

  factory SessionModel.fromEntity(SessionEntity entity) {
    return SessionModel(
      id: entity.id,
      trainerId: entity.trainerId,
      clientId: entity.clientId,
      clientName: entity.clientName,
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
    );
  }

  SessionEntity toEntity() => this;
}
