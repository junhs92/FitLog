import 'package:dartz/dartz.dart';
import '../../../../shared/models/result.dart';
import '../datasources/recommendation_remote_datasource.dart';
import '../models/exercise_alias_model.dart';
import '../models/exercise_relation_model.dart';
import '../models/user_preference_model.dart';
import '../models/recommendation_weight_model.dart';

/// Repository for recommendation-related data operations
class RecommendationRepository {
  final RecommendationRemoteDataSource _remoteDataSource;

  RecommendationRepository(this._remoteDataSource);

  // ==================== Exercise Aliases ====================

  /// Get aliases for a specific exercise
  Future<Result<List<ExerciseAliasModel>>> getAliasesForExercise(String exerciseId) async {
    try {
      final aliases = await _remoteDataSource.getAliasesForExercise(exerciseId);
      return Right(aliases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Search aliases by query
  Future<Result<List<ExerciseAliasModel>>> searchAliases(String query) async {
    try {
      final aliases = await _remoteDataSource.searchAliases(query);
      return Right(aliases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== Exercise Relations ====================

  /// Get relations for a specific exercise
  Future<Result<List<ExerciseRelationModel>>> getRelationsForExercise(
    String exerciseId, {
    ExerciseRelationType? relationType,
  }) async {
    try {
      final relations = await _remoteDataSource.getRelationsForExercise(
        exerciseId,
        relationType: relationType,
      );
      return Right(relations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get all relations of a specific type
  Future<Result<List<ExerciseRelationModel>>> getRelationsByType(
    ExerciseRelationType relationType,
  ) async {
    try {
      final relations = await _remoteDataSource.getRelationsByType(relationType);
      return Right(relations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== User Preferences ====================

  /// Get user preferences for the current user
  Future<Result<UserPreferenceModel?>> getUserPreferences() async {
    try {
      final prefs = await _remoteDataSource.getUserPreferences();
      return Right(prefs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Create or update user preferences
  Future<Result<UserPreferenceModel>> upsertUserPreferences(UserPreferenceModel prefs) async {
    try {
      final updated = await _remoteDataSource.upsertUserPreferences(prefs);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ==================== Recommendation Weights ====================

  /// Get all active recommendation weights
  Future<Result<List<RecommendationWeightModel>>> getRecommendationWeights() async {
    try {
      final weights = await _remoteDataSource.getRecommendationWeights();
      return Right(weights);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get weights by category
  Future<Result<List<RecommendationWeightModel>>> getWeightsByCategory(String category) async {
    try {
      final weights = await _remoteDataSource.getWeightsByCategory(category);
      return Right(weights);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get weight map (key -> weight) with fallback to defaults
  Future<Map<String, double>> getWeightMapWithFallback() async {
    try {
      final weights = await _remoteDataSource.getWeightMap();
      if (weights.isEmpty) {
        return RecommendationWeightModel.defaultWeights;
      }
      // Merge with defaults for any missing keys
      return {...RecommendationWeightModel.defaultWeights, ...weights};
    } catch (e) {
      // Return defaults on any error
      return RecommendationWeightModel.defaultWeights;
    }
  }
}
