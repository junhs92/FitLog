import '../../domain/entities/workout_program.dart';

/// Data model for workout program (training direction with client preferences)
class WorkoutProgramModel extends WorkoutProgramEntity {
  const WorkoutProgramModel({
    required super.id,
    required super.clientId,
    required super.trainerId,
    required super.name,
    super.description,
    required super.trainingSplit,
    super.focusAreas,
    super.preferredMovementGroups,
    super.totalSessions,
    super.avgSessionsPerWeek,
    super.consistencyScore,
    super.lastSessionFocus,
    super.muscleGroupHistory,
    required super.status,
    required super.createdAt,
    super.expiresAt,
    super.startedAt,
    super.completedAt,
    super.isAiGenerated,
    super.aiModelVersion,
    super.generatedExercises,
  });

  factory WorkoutProgramModel.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trainingSplit: TrainingSplit.fromString(
          json['training_split'] as String? ?? 'full_body'),
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredMovementGroups: (json['preferred_movement_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalSessions: json['total_sessions'] as int? ?? 0,
      avgSessionsPerWeek:
          (json['avg_sessions_per_week'] as num?)?.toDouble() ?? 0,
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0,
      lastSessionFocus: json['last_session_focus'] as String?,
      muscleGroupHistory: (json['muscle_group_history'] as List<dynamic>?)
              ?.map((e) =>
                  MuscleGroupHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ProgramStatus.fromString(json['status'] as String? ?? 'draft'),
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isAiGenerated: json['is_ai_generated'] as bool? ?? true,
      aiModelVersion: json['ai_model_version'] as String?,
      // Note: generatedExercises is NOT stored in DB, only held in memory
      generatedExercises: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'name': name,
      'description': description,
      'training_split': trainingSplit.id,
      'focus_areas': focusAreas,
      'preferred_movement_groups': preferredMovementGroups,
      'total_sessions': totalSessions,
      'avg_sessions_per_week': avgSessionsPerWeek,
      'consistency_score': consistencyScore,
      'last_session_focus': lastSessionFocus,
      'muscle_group_history':
          muscleGroupHistory.map((e) => e.toJson()).toList(),
      'status': status.id,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_ai_generated': isAiGenerated,
      'ai_model_version': aiModelVersion,
      // Note: generatedExercises is NOT stored in DB
    };
  }

  /// JSON for inserting a new program (without id and computed fields)
  Map<String, dynamic> toInsertJson() {
    // Default expiration to 3 months from now
    final defaultExpiration = DateTime.now().add(const Duration(days: 90));

    return {
      'client_id': clientId,
      'trainer_id': trainerId,
      'name': name,
      'description': description,
      'training_split': trainingSplit.id,
      'focus_areas': focusAreas,
      'preferred_movement_groups': preferredMovementGroups,
      'status': status.id,
      'expires_at': (expiresAt ?? defaultExpiration).toIso8601String(),
      'is_ai_generated': isAiGenerated,
      'ai_model_version': aiModelVersion,
      // Note: generatedExercises is NOT stored in DB
    };
  }

  factory WorkoutProgramModel.fromEntity(WorkoutProgramEntity entity) {
    return WorkoutProgramModel(
      id: entity.id,
      clientId: entity.clientId,
      trainerId: entity.trainerId,
      name: entity.name,
      description: entity.description,
      trainingSplit: entity.trainingSplit,
      focusAreas: entity.focusAreas,
      preferredMovementGroups: entity.preferredMovementGroups,
      totalSessions: entity.totalSessions,
      avgSessionsPerWeek: entity.avgSessionsPerWeek,
      consistencyScore: entity.consistencyScore,
      lastSessionFocus: entity.lastSessionFocus,
      muscleGroupHistory: entity.muscleGroupHistory,
      status: entity.status,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      isAiGenerated: entity.isAiGenerated,
      aiModelVersion: entity.aiModelVersion,
      generatedExercises: entity.generatedExercises,
    );
  }
}
