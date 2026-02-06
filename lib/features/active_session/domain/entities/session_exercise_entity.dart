import 'exercise_entity.dart';
import 'exercise_set_entity.dart';

/// An exercise performed within a training session
class SessionExerciseEntity {
  final String id;
  final String sessionId;
  final ExerciseEntity exercise;
  final int order;
  final List<ExerciseSetEntity> sets;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Target values from AI recommendations
  final int? targetSets;
  final String? targetReps; // Can be "8-12" range format
  final double? targetWeight;
  final int? targetRpe;
  final int? restSeconds;

  const SessionExerciseEntity({
    required this.id,
    required this.sessionId,
    required this.exercise,
    required this.order,
    this.sets = const [],
    this.notes,
    this.startedAt,
    this.completedAt,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.targetRpe,
    this.restSeconds,
  });

  /// Get total sets count (excluding warmup)
  int get workingSetsCount => sets.where((s) => !s.isWarmup).length;

  /// Get total volume (sum of weight * reps across all sets)
  double get totalVolume {
    return sets.fold(0.0, (sum, set) => sum + (set.volume ?? 0));
  }

  /// Get top set (heaviest weight with reps)
  ExerciseSetEntity? get topSet {
    final workingSets = sets.where((s) => !s.isWarmup && s.weight != null).toList();
    if (workingSets.isEmpty) return null;
    // Use fold instead of reduce to avoid type inference issues with subclasses
    ExerciseSetEntity result = workingSets.first;
    for (final set in workingSets.skip(1)) {
      if ((set.weight ?? 0) > (result.weight ?? 0)) {
        result = set;
      }
    }
    return result;
  }

  /// Get average RPE across all sets
  double? get averageRpe {
    final setsWithRpe = sets.where((s) => s.rpe != null);
    if (setsWithRpe.isEmpty) return null;
    return setsWithRpe.map((s) => s.rpe!).reduce((a, b) => a + b) /
        setsWithRpe.length;
  }

  /// Check if any set has a PR tag
  bool get hasPR => sets.any((s) => s.isPR);

  /// Check if exercise is completed
  bool get isCompleted => completedAt != null;

  SessionExerciseEntity copyWith({
    String? id,
    String? sessionId,
    ExerciseEntity? exercise,
    int? order,
    List<ExerciseSetEntity>? sets,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    int? targetRpe,
    int? restSeconds,
  }) {
    return SessionExerciseEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exercise: exercise ?? this.exercise,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRpe: targetRpe ?? this.targetRpe,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  /// Get recommended weight (from target or last set)
  double get recommendedWeight => targetWeight ?? 20.0;

  /// Get recommended reps (uses max of range for initial value)
  int get recommendedReps {
    if (targetReps == null) return 10;
    // Handle range format like "8-12" - use max value
    if (targetReps!.contains('-')) {
      final parts = targetReps!.split('-');
      if (parts.length == 2) {
        final max = int.tryParse(parts[1].trim()) ?? 10;
        return max;
      }
    }
    return int.tryParse(targetReps!) ?? 10;
  }

  /// Get recommended RPE
  double? get recommendedRpe => targetRpe?.toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExerciseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
