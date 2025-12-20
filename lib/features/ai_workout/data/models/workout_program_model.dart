import '../../domain/entities/workout_program.dart';
import '../../domain/entities/ai_reasoning.dart';
import '../../domain/entities/exercise_difficulty.dart';

/// Data model for workout program
class WorkoutProgramModel extends WorkoutProgramEntity {
  const WorkoutProgramModel({
    required super.id,
    required super.clientId,
    required super.trainerId,
    required super.name,
    super.description,
    required super.primaryGoal,
    super.secondaryGoal,
    required super.durationWeeks,
    required super.sessionsPerWeek,
    required super.status,
    required super.workoutDays,
    required super.createdAt,
    super.startedAt,
    super.completedAt,
    super.isAiGenerated,
    super.customizationCount,
    super.aiModelVersion,
  });

  factory WorkoutProgramModel.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      primaryGoal: TrainingGoal.fromString(json['primary_goal'] as String),
      secondaryGoal: json['secondary_goal'] != null
          ? TrainingGoal.fromString(json['secondary_goal'] as String)
          : null,
      durationWeeks: json['duration_weeks'] as int,
      sessionsPerWeek: json['sessions_per_week'] as int,
      status: ProgramStatus.fromString(json['status'] as String),
      workoutDays: (json['workout_days'] as List<dynamic>?)
              ?.map((e) =>
                  WorkoutDayModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isAiGenerated: json['is_ai_generated'] as bool? ?? true,
      customizationCount: json['customization_count'] as int? ?? 0,
      aiModelVersion: json['ai_model_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'trainer_id': trainerId,
      'name': name,
      'description': description,
      'primary_goal': primaryGoal.id,
      'secondary_goal': secondaryGoal?.id,
      'duration_weeks': durationWeeks,
      'sessions_per_week': sessionsPerWeek,
      'status': status.id,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_ai_generated': isAiGenerated,
      'customization_count': customizationCount,
      'ai_model_version': aiModelVersion,
    };
  }

  factory WorkoutProgramModel.fromEntity(WorkoutProgramEntity entity) {
    return WorkoutProgramModel(
      id: entity.id,
      clientId: entity.clientId,
      trainerId: entity.trainerId,
      name: entity.name,
      description: entity.description,
      primaryGoal: entity.primaryGoal,
      secondaryGoal: entity.secondaryGoal,
      durationWeeks: entity.durationWeeks,
      sessionsPerWeek: entity.sessionsPerWeek,
      status: entity.status,
      workoutDays: entity.workoutDays,
      createdAt: entity.createdAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      isAiGenerated: entity.isAiGenerated,
      customizationCount: entity.customizationCount,
      aiModelVersion: entity.aiModelVersion,
    );
  }
}

/// Data model for workout day
class WorkoutDayModel {
  final String id;
  final String programId;
  final int dayNumber;
  final String name;
  final String? focusArea;
  final List<ProgramExerciseModel> exercises;
  final int estimatedDurationMinutes;

  const WorkoutDayModel({
    required this.id,
    required this.programId,
    required this.dayNumber,
    required this.name,
    this.focusArea,
    required this.exercises,
    required this.estimatedDurationMinutes,
  });

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    return WorkoutDayModel(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      dayNumber: json['day_number'] as int,
      name: json['name'] as String,
      focusArea: json['focus_area'] as String?,
      exercises: (json['program_exercises'] as List<dynamic>?)
              ?.map((e) => ProgramExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 45,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program_id': programId,
      'day_number': dayNumber,
      'name': name,
      'focus_area': focusArea,
      'estimated_duration_minutes': estimatedDurationMinutes,
    };
  }

  WorkoutDayEntity toEntity() {
    return WorkoutDayEntity(
      id: id,
      programId: programId,
      dayNumber: dayNumber,
      name: name,
      focusArea: focusArea,
      exercises: exercises.map((e) => e.toEntity()).toList(),
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }
}

/// Data model for program exercise
class ProgramExerciseModel {
  final String id;
  final String workoutDayId;
  final String exerciseId;
  final String exerciseName;
  final String? exerciseNameKo;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final double? targetWeight;
  final int? targetRpe;
  final int restSeconds;
  final String? notes;
  final Map<String, dynamic>? aiReasoningJson;
  final List<Map<String, dynamic>>? alternativesJson;
  final String? originalExerciseId;
  final bool isSwapped;

  const ProgramExerciseModel({
    required this.id,
    required this.workoutDayId,
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseNameKo,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    this.targetRpe,
    required this.restSeconds,
    this.notes,
    this.aiReasoningJson,
    this.alternativesJson,
    this.originalExerciseId,
    this.isSwapped = false,
  });

  factory ProgramExerciseModel.fromJson(Map<String, dynamic> json) {
    // Handle nested exercise data
    final exerciseData = json['exercises'] as Map<String, dynamic>?;

    return ProgramExerciseModel(
      id: json['id'] as String,
      workoutDayId: json['workout_day_id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: exerciseData?['name'] as String? ?? json['exercise_name'] as String? ?? '',
      exerciseNameKo: exerciseData?['name_ko'] as String? ?? json['exercise_name_ko'] as String?,
      orderIndex: json['order_index'] as int,
      targetSets: json['target_sets'] as int,
      targetReps: json['target_reps'] as String,
      targetWeight: (json['target_weight'] as num?)?.toDouble(),
      targetRpe: json['target_rpe'] as int?,
      restSeconds: json['rest_seconds'] as int? ?? 90,
      notes: json['notes'] as String?,
      aiReasoningJson: json['ai_reasoning'] as Map<String, dynamic>?,
      alternativesJson: (json['alternatives'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      originalExerciseId: json['original_exercise_id'] as String?,
      isSwapped: json['is_swapped'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_day_id': workoutDayId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'notes': notes,
      'ai_reasoning': aiReasoningJson,
      'alternatives': alternativesJson,
      'original_exercise_id': originalExerciseId,
      'is_swapped': isSwapped,
    };
  }

  ProgramExerciseEntity toEntity() {
    return ProgramExerciseEntity(
      id: id,
      workoutDayId: workoutDayId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseNameKo: exerciseNameKo,
      orderIndex: orderIndex,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      targetRpe: targetRpe,
      restSeconds: restSeconds,
      notes: notes,
      aiReasoning: _parseAIReasoning(),
      alternatives: _parseAlternatives(),
      originalExerciseId: originalExerciseId,
      isSwapped: isSwapped,
    );
  }

  AIExerciseReasoning? _parseAIReasoning() {
    if (aiReasoningJson == null) return null;

    final reasons = (aiReasoningJson!['reasons'] as List<dynamic>?)
        ?.map((r) => AIReasoningPoint(
              category: ReasoningCategory.fromString(r['category'] as String),
              explanation: r['explanation'] as String,
              explanationKo: r['explanation_ko'] as String?,
              confidence: (r['confidence'] as num?)?.toDouble() ?? 0.8,
            ))
        .toList() ?? [];

    return AIExerciseReasoning(
      exerciseId: exerciseId,
      reasons: reasons,
      overallScore: (aiReasoningJson!['overall_score'] as num?)?.toDouble() ?? 0.8,
      generatedAt: aiReasoningJson!['generated_at'] != null
          ? DateTime.parse(aiReasoningJson!['generated_at'] as String)
          : DateTime.now(),
    );
  }

  List<ExerciseAlternative> _parseAlternatives() {
    if (alternativesJson == null) return [];

    return alternativesJson!.map((a) => ExerciseAlternative(
      exerciseId: a['exercise_id'] as String,
      exerciseName: a['exercise_name'] as String,
      exerciseNameKo: a['exercise_name_ko'] as String?,
      type: AlternativeType.values.firstWhere(
        (t) => t.id == a['type'],
        orElse: () => AlternativeType.samePattern,
      ),
      reason: a['reason'] as String,
      reasonKo: a['reason_ko'] as String?,
      difficulty: ExerciseDifficulty.fromString(a['difficulty'] as String? ?? 'intermediate'),
      equipment: EquipmentType.fromString(a['equipment'] as String? ?? 'other'),
    )).toList();
  }
}
