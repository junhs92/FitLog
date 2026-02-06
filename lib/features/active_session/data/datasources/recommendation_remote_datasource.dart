import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise_alias_model.dart';
import '../models/exercise_relation_model.dart';
import '../models/user_preference_model.dart';
import '../models/recommendation_weight_model.dart';

/// Remote data source for recommendation-related operations via Supabase
class RecommendationRemoteDataSource {
  final SupabaseClient _client;

  RecommendationRemoteDataSource(this._client);

  String get _currentAuthUserId => _client.auth.currentUser!.id;

  // ==================== Exercise Aliases ====================

  /// Get aliases for a specific exercise
  Future<List<ExerciseAliasModel>> getAliasesForExercise(String exerciseId) async {
    final response = await _client
        .from('exercise_aliases')
        .select()
        .eq('exercise_id', exerciseId)
        .order('priority', ascending: false);

    return (response as List)
        .map((json) => ExerciseAliasModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Search aliases by normalized text (for search functionality)
  Future<List<ExerciseAliasModel>> searchAliases(String query) async {
    final normalized = query.toLowerCase().replaceAll(' ', '');
    final response = await _client
        .from('exercise_aliases')
        .select()
        .ilike('alias_normalized', '%$normalized%')
        .limit(20);

    return (response as List)
        .map((json) => ExerciseAliasModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== Exercise Relations ====================

  /// Get relations for a specific exercise
  Future<List<ExerciseRelationModel>> getRelationsForExercise(
    String exerciseId, {
    ExerciseRelationType? relationType,
  }) async {
    var query = _client
        .from('exercise_relations')
        .select()
        .eq('from_exercise_id', exerciseId)
        .eq('is_active', true);

    if (relationType != null) {
      query = query.eq('relation_type', relationType.name);
    }

    final response = await query.order('strength', ascending: false);

    return (response as List)
        .map((json) => ExerciseRelationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get all relations of a specific type
  Future<List<ExerciseRelationModel>> getRelationsByType(
    ExerciseRelationType relationType,
  ) async {
    final response = await _client
        .from('exercise_relations')
        .select()
        .eq('relation_type', relationType.name)
        .eq('is_active', true)
        .order('strength', ascending: false);

    return (response as List)
        .map((json) => ExerciseRelationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== User Preferences ====================

  /// Get user preferences for the current user
  Future<UserPreferenceModel?> getUserPreferences() async {
    try {
      // First get the account ID from the auth user
      final accountResponse = await _client
          .from('accounts')
          .select('id')
          .eq('user_id', _currentAuthUserId)
          .single();

      final accountId = accountResponse['id'] as String;

      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', accountId)
          .maybeSingle();

      if (response == null) return null;
      return UserPreferenceModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create or update user preferences
  Future<UserPreferenceModel> upsertUserPreferences(UserPreferenceModel prefs) async {
    final response = await _client
        .from('user_preferences')
        .upsert(prefs.toJson())
        .select()
        .single();

    return UserPreferenceModel.fromJson(response);
  }

  // ==================== Recommendation Weights ====================

  /// Get all active recommendation weights
  Future<List<RecommendationWeightModel>> getRecommendationWeights() async {
    final response = await _client
        .from('recommendation_weights')
        .select()
        .eq('is_active', true);

    return (response as List)
        .map((json) => RecommendationWeightModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get weights by category (complementary, supplementary, etc.)
  Future<List<RecommendationWeightModel>> getWeightsByCategory(String category) async {
    final response = await _client
        .from('recommendation_weights')
        .select()
        .eq('category', category)
        .eq('is_active', true);

    return (response as List)
        .map((json) => RecommendationWeightModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get weight map (key -> weight) for all active weights
  Future<Map<String, double>> getWeightMap() async {
    final weights = await getRecommendationWeights();
    return RecommendationWeightModel.toWeightMap(weights);
  }
}
