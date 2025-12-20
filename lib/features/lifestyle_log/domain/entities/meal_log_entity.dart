import 'package:equatable/equatable.dart';

/// Meal type enumeration
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

/// Entity representing a meal log entry
class MealLogEntity extends Equatable {
  final String id;
  final String clientId;
  final DateTime logDate;
  final MealType mealType;
  final String? photoUrl;
  final String? description;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealLogEntity({
    required this.id,
    required this.clientId,
    required this.logDate,
    required this.mealType,
    this.photoUrl,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.createdAt,
    this.updatedAt,
  });

  /// Display name for meal type
  String get mealTypeName {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  /// Icon for meal type
  String get mealTypeIcon {
    switch (mealType) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }

  /// Check if meal has nutrition info
  bool get hasNutrition =>
      calories != null || protein != null || carbs != null || fat != null;

  MealLogEntity copyWith({
    String? id,
    String? clientId,
    DateTime? logDate,
    MealType? mealType,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealLogEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      logDate: logDate ?? this.logDate,
      mealType: mealType ?? this.mealType,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        logDate,
        mealType,
        photoUrl,
        description,
        calories,
        protein,
        carbs,
        fat,
        createdAt,
        updatedAt,
      ];
}
