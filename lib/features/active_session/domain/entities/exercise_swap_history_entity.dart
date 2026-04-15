/// Domain entity representing a single exercise swap event within a session
class ExerciseSwapHistoryEntity {
  final String id;
  final String sessionExerciseId;
  final String originalExerciseId;
  final String newExerciseId;
  final String? reason;
  final int swapOrder;
  final String clientId;
  final String trainerId;
  final DateTime createdAt;

  const ExerciseSwapHistoryEntity({
    required this.id,
    required this.sessionExerciseId,
    required this.originalExerciseId,
    required this.newExerciseId,
    this.reason,
    required this.swapOrder,
    required this.clientId,
    required this.trainerId,
    required this.createdAt,
  });

  ExerciseSwapHistoryEntity copyWith({
    String? id,
    String? sessionExerciseId,
    String? originalExerciseId,
    String? newExerciseId,
    String? reason,
    int? swapOrder,
    String? clientId,
    String? trainerId,
    DateTime? createdAt,
  }) {
    return ExerciseSwapHistoryEntity(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      newExerciseId: newExerciseId ?? this.newExerciseId,
      reason: reason ?? this.reason,
      swapOrder: swapOrder ?? this.swapOrder,
      clientId: clientId ?? this.clientId,
      trainerId: trainerId ?? this.trainerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSwapHistoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
