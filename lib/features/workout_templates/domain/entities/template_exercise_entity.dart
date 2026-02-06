import '../../../active_session/domain/entities/exercise_entity.dart';

/// An exercise within a workout template
class TemplateExerciseEntity {
  final String id;
  final String templateId;
  final String exerciseId;
  final ExerciseEntity? exercise; // Joined from exercises table
  final int orderIndex;
  final int? targetSets;
  final String? targetReps; // Can be "8-12", "10", "AMRAP", etc.
  final double? targetWeight;
  final int? targetRpe;
  final int? restSeconds;
  final String? notes;
  final DateTime createdAt;

  const TemplateExerciseEntity({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    this.exercise,
    required this.orderIndex,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.targetRpe,
    this.restSeconds,
    this.notes,
    required this.createdAt,
  });

  /// Get display name (from joined exercise)
  String get displayName => exercise?.displayName ?? 'Unknown Exercise';

  /// Get exercise name in English
  String get name => exercise?.name ?? 'Unknown';

  /// Get exercise name in Korean
  String? get nameKo => exercise?.nameKo;

  TemplateExerciseEntity copyWith({
    String? id,
    String? templateId,
    String? exerciseId,
    ExerciseEntity? exercise,
    int? orderIndex,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    int? targetRpe,
    int? restSeconds,
    String? notes,
    DateTime? createdAt,
  }) {
    return TemplateExerciseEntity(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
      orderIndex: orderIndex ?? this.orderIndex,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRpe: targetRpe ?? this.targetRpe,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateExerciseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
