import '../../../ai_workout/domain/entities/workout_program.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';

/// Unified data transfer object for session exercise creation.
///
/// Normalizes data from all 3 session start flows into consistent format:
/// - AI flow: [fromAI] factory extracts from [GeneratedProgramExercise]
/// - Previous flow: [fromPrevious] factory computes from historical [SessionExerciseEntity]
/// - Empty flow: No exercises needed (add during session)
class SessionExerciseInput {
  final String exerciseId;
  final String name;
  final int orderIndex;
  final int? targetSets;
  final String? targetReps; // Can be "8-12" range
  final double? targetWeight;
  final int? targetRpe;
  final int? restSeconds;
  final String? aiReasoning; // Only for AI flow

  const SessionExerciseInput({
    required this.exerciseId,
    required this.name,
    required this.orderIndex,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.targetRpe,
    this.restSeconds,
    this.aiReasoning,
  });

  /// Factory: Create from AI-generated exercise
  factory SessionExerciseInput.fromAI(GeneratedProgramExercise e, int index) {
    return SessionExerciseInput(
      exerciseId: e.exerciseId,
      name: e.name,
      orderIndex: index,
      targetSets: e.targetSets,
      targetReps: e.targetReps,
      targetRpe: e.targetRpe ?? 6, // Use prescribed RPE or default to 6
      restSeconds: e.restSeconds,
      aiReasoning: e.aiReasoning,
    );
  }

  /// Factory: Create from previous session exercise (with historical data)
  ///
  /// Computes targets from actual workout data:
  /// - targetSets: Count of working sets (excludes warmup)
  /// - targetReps: Average reps from working sets
  /// - targetWeight: Best weight from top set
  factory SessionExerciseInput.fromPrevious(
    SessionExerciseEntity e,
    int index,
  ) {
    // Extract working sets (exclude warmup)
    final workingSets = e.sets
        .where((s) => !s.tags.contains(SetTag.warmup))
        .toList();

    // Compute target sets from historical data
    final setsCount = workingSets.isNotEmpty
        ? workingSets.length
        : e.targetSets ?? 3;

    // Compute average reps from working sets
    String? avgReps;
    if (workingSets.isNotEmpty) {
      final repsValues = workingSets
          .where((s) => s.reps != null)
          .map((s) => s.reps!);
      if (repsValues.isNotEmpty) {
        final avg = repsValues.reduce((a, b) => a + b) / repsValues.length;
        avgReps = avg.round().toString();
      }
    }
    avgReps ??= e.targetReps;

    // Best weight from top set
    final bestWeight = e.topSet?.weight ?? e.targetWeight;

    return SessionExerciseInput(
      exerciseId: e.exercise.id,
      name: e.exercise.name,
      orderIndex: index,
      targetSets: setsCount,
      targetReps: avgReps,
      targetWeight: bestWeight,
      targetRpe: e.targetRpe,
      restSeconds: e.restSeconds,
    );
  }

  /// Convert to database insert format (consistent snake_case)
  Map<String, dynamic> toInsertMap(String sessionId) {
    return {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      // AI reasoning stored in notes column
      if (aiReasoning != null) 'notes': aiReasoning,
    };
  }

  @override
  String toString() {
    return 'SessionExerciseInput('
        'exerciseId: $exerciseId, '
        'name: $name, '
        'order: $orderIndex, '
        'sets: $targetSets, '
        'reps: $targetReps, '
        'weight: $targetWeight'
        ')';
  }
}
