import '../../../../shared/models/result.dart';
import '../entities/meal_log_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to log a meal
class LogMeal {
  final LifestyleRepository _repository;

  LogMeal(this._repository);

  /// Log a new meal
  Future<Result<MealLogEntity>> call({
    required String clientId,
    required DateTime date,
    required MealType mealType,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return _repository.logMeal(
      clientId: clientId,
      date: date,
      mealType: mealType,
      photoUrl: photoUrl,
      description: description,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Update an existing meal
  Future<Result<MealLogEntity>> update({
    required String mealId,
    String? photoUrl,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return _repository.updateMeal(
      mealId: mealId,
      photoUrl: photoUrl,
      description: description,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Delete a meal
  Future<Result<void>> delete(String mealId) {
    return _repository.deleteMeal(mealId);
  }
}
