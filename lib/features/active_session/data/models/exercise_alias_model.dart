/// Data model for exercise aliases (search/display normalization)
class ExerciseAliasModel {
  final String id;
  final String exerciseId;
  final String alias;
  final String aliasNormalized;
  final int priority;
  final String locale;
  final String source;
  final DateTime createdAt;

  const ExerciseAliasModel({
    required this.id,
    required this.exerciseId,
    required this.alias,
    required this.aliasNormalized,
    this.priority = 0,
    this.locale = 'ko',
    this.source = 'system',
    required this.createdAt,
  });

  factory ExerciseAliasModel.fromJson(Map<String, dynamic> json) {
    return ExerciseAliasModel(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      alias: json['alias'] as String,
      aliasNormalized: json['alias_normalized'] as String,
      priority: json['priority'] as int? ?? 0,
      locale: json['locale'] as String? ?? 'ko',
      source: json['source'] as String? ?? 'system',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'alias': alias,
      'alias_normalized': aliasNormalized,
      'priority': priority,
      'locale': locale,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
