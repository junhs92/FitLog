import '../../domain/entities/exercise_set_entity.dart';

/// Data model for ExerciseSet - maps to set_records table
class ExerciseSetModel extends ExerciseSetEntity {
  const ExerciseSetModel({
    required super.id,
    required super.sessionExerciseId,
    required super.setNumber,
    super.weight,
    super.reps,
    super.rpe,
    super.duration,
    super.distance,
    super.tags,
    super.prType,
    super.notes,
    required super.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Parse from set_records table row
  factory ExerciseSetModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ExerciseSetModel(
      id: json['id'] as String,
      sessionExerciseId: json['session_exercise_id'] as String,
      setNumber: json['set_number'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      rpe: (json['rpe'] as num?)?.toDouble(),
      duration: json['duration_seconds'] != null
          ? Duration(seconds: json['duration_seconds'] as int)
          : null,
      distance: (json['distance'] as num?)?.toDouble(),
      tags: _parseTags(json['tags']),
      prType: PrTypeExtension.fromString(json['pr_type'] as String?),
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : now,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : now,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : now,
    );
  }

  static List<SetTag> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return tags
          .map((t) => _parseTag(t.toString()))
          .whereType<SetTag>()
          .toList();
    }
    return [];
  }

  static SetTag? _parseTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'pr':
        return SetTag.pr;
      case 'form_issue':
        return SetTag.formIssue;
      case 'pain':
        return SetTag.pain;
      case 'fatigue':
        return SetTag.fatigue;
      case 'good_condition':
        return SetTag.goodCondition;
      case 'warmup':
        return SetTag.warmup;
      case 'drop_set':
        return SetTag.dropSet;
      case 'failure_set':
        return SetTag.failureSet;
      default:
        return null;
    }
  }

  static String _tagToString(SetTag tag) {
    switch (tag) {
      case SetTag.pr:
        return 'pr';
      case SetTag.formIssue:
        return 'form_issue';
      case SetTag.pain:
        return 'pain';
      case SetTag.fatigue:
        return 'fatigue';
      case SetTag.goodCondition:
        return 'good_condition';
      case SetTag.warmup:
        return 'warmup';
      case SetTag.dropSet:
        return 'drop_set';
      case SetTag.failureSet:
        return 'failure_set';
    }
  }

  /// Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'duration_seconds': duration?.inSeconds,
      'distance': distance,
      'tags': tags.map(_tagToString).toList(),
      'pr_type': prType?.id,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for INSERT (excludes id, created_at, updated_at - DB generates these)
  Map<String, dynamic> toInsertJson() {
    return {
      'session_exercise_id': sessionExerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'duration_seconds': duration?.inSeconds,
      'distance': distance,
      'tags': tags.map(_tagToString).toList(),
      'pr_type': prType?.id,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for UPDATE (excludes id, session_exercise_id, created_at)
  Map<String, dynamic> toUpdateJson() {
    return {
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'duration_seconds': duration?.inSeconds,
      'distance': distance,
      'tags': tags.map(_tagToString).toList(),
      'pr_type': prType?.id,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory ExerciseSetModel.fromEntity(ExerciseSetEntity entity) {
    return ExerciseSetModel(
      id: entity.id,
      sessionExerciseId: entity.sessionExerciseId,
      setNumber: entity.setNumber,
      weight: entity.weight,
      reps: entity.reps,
      rpe: entity.rpe,
      duration: entity.duration,
      distance: entity.distance,
      tags: entity.tags,
      prType: entity.prType,
      notes: entity.notes,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExerciseSetEntity toEntity() => this;
}
