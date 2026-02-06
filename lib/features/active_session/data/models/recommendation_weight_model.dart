/// Data model for tunable recommendation weights
class RecommendationWeightModel {
  final String id;
  final String key;
  final String category;
  final double weight;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecommendationWeightModel({
    required this.id,
    required this.key,
    required this.category,
    required this.weight,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecommendationWeightModel.fromJson(Map<String, dynamic> json) {
    return RecommendationWeightModel(
      id: json['id'] as String,
      key: json['key'] as String,
      category: json['category'] as String,
      weight: (json['weight'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'category': category,
      'weight': weight,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Default weights (fallback when database is not available)
  static Map<String, double> get defaultWeights => const {
    // Complementary weights
    'same_group': 40,
    'same_detail': 20,
    'same_prime': 30,
    'same_family': 25,
    'angle_variation': 20,
    'same_equipment': 10,
    'category_match': 10,
    // Supplementary weights
    'supplementary_same_prime': 30,
    'isolation_bonus': 25,
    'secondary_overlap': 20,
    'stable_equipment': 10,
    // General weights
    'difficulty_mismatch_penalty': -15,
  };

  /// Convert list of models to weight map (key -> weight)
  static Map<String, double> toWeightMap(List<RecommendationWeightModel> models) {
    final map = <String, double>{};
    for (final model in models) {
      if (model.isActive) {
        map[model.key] = model.weight;
      }
    }
    return map;
  }
}
