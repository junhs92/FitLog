import '../../domain/entities/meal_log_entity.dart';

/// Data model for meal logs with JSON serialization
class MealLogModel extends MealLogEntity {
  const MealLogModel({
    required super.id,
    required super.clientId,
    required super.logDate,
    required super.mealType,
    super.photoUrl,
    super.description,
    super.calories,
    super.protein,
    super.carbs,
    super.fat,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from JSON map
  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    return MealLogModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      mealType: _mealTypeFromString(json['meal_type'] as String),
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String?,
      calories: json['calories'] as int?,
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'meal_type': _mealTypeToString(mealType),
      'photo_url': photoUrl,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from entity
  factory MealLogModel.fromEntity(MealLogEntity entity) {
    return MealLogModel(
      id: entity.id,
      clientId: entity.clientId,
      logDate: entity.logDate,
      mealType: entity.mealType,
      photoUrl: entity.photoUrl,
      description: entity.description,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static MealType _mealTypeFromString(String value) {
    switch (value) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.snack;
    }
  }

  static String _mealTypeToString(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.snack:
        return 'snack';
    }
  }
}
