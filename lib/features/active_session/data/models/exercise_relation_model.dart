/// Relation types for exercise relationships
enum ExerciseRelationType {
  variation,       // same exercise, different angle/equipment
  complementary,   // good to do together
  supplementary,   // isolation for same muscle
  substitute;      // can replace when unavailable

  static ExerciseRelationType fromString(String value) {
    return ExerciseRelationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseRelationType.complementary,
    );
  }
}

/// Data model for exercise relationships
class ExerciseRelationModel {
  final String id;
  final String fromExerciseId;
  final String toExerciseId;
  final ExerciseRelationType relationType;
  final int strength;
  final List<String> reasonTags;
  final Map<String, dynamic> constraints;
  final bool isActive;
  final DateTime createdAt;

  const ExerciseRelationModel({
    required this.id,
    required this.fromExerciseId,
    required this.toExerciseId,
    required this.relationType,
    this.strength = 50,
    this.reasonTags = const [],
    this.constraints = const {},
    this.isActive = true,
    required this.createdAt,
  });

  factory ExerciseRelationModel.fromJson(Map<String, dynamic> json) {
    return ExerciseRelationModel(
      id: json['id'] as String,
      fromExerciseId: json['from_exercise_id'] as String,
      toExerciseId: json['to_exercise_id'] as String,
      relationType: ExerciseRelationType.fromString(json['relation_type'] as String),
      strength: json['strength'] as int? ?? 50,
      reasonTags: (json['reason_tags'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      constraints: json['constraints'] as Map<String, dynamic>? ?? const {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_exercise_id': fromExerciseId,
      'to_exercise_id': toExerciseId,
      'relation_type': relationType.name,
      'strength': strength,
      'reason_tags': reasonTags,
      'constraints': constraints,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
