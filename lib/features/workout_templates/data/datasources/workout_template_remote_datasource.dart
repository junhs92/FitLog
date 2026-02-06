import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/workout_template_repository.dart';
import '../models/workout_template_model.dart';

/// Remote data source for workout template operations
abstract class WorkoutTemplateRemoteDataSource {
  Future<List<WorkoutTemplateModel>> getTemplates({
    String? focusArea,
    int? limit,
  });
  Future<WorkoutTemplateModel> getTemplateById(String templateId);
  Future<WorkoutTemplateModel> createTemplate({
    required String name,
    String? nameKo,
    String? description,
    required List<TemplateExerciseInput> exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  });
  Future<WorkoutTemplateModel> updateTemplate({
    required String templateId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseInput>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  });
  Future<void> deleteTemplate(String templateId);
  Future<void> incrementUsage(String templateId);
}

/// Implementation using Supabase
class WorkoutTemplateRemoteDataSourceImpl
    implements WorkoutTemplateRemoteDataSource {
  final SupabaseClient _client;

  WorkoutTemplateRemoteDataSourceImpl(this._client);

  /// Get current user's account ID
  Future<String> _getMyAccountId() async {
    final result = await _client.rpc<String>('get_my_account_id');
    return result;
  }

  /// Select statement for templates with exercises
  static const String _templateSelectWithExercises = '''
    *,
    workout_template_exercises(
      *,
      exercises(*)
    )
  ''';

  /// Select statement for templates without exercises (for list view)
  static const String _templateSelectSimple = '*';

  @override
  Future<List<WorkoutTemplateModel>> getTemplates({
    String? focusArea,
    int? limit,
  }) async {
    final creatorId = await _getMyAccountId();

    // Build query with all conditions
    dynamic response;

    if (focusArea != null && limit != null) {
      response = await _client
          .from('workout_templates')
          .select(_templateSelectWithExercises)
          .eq('creator_id', creatorId)
          .eq('focus_area', focusArea)
          .order('created_at', ascending: false)
          .limit(limit);
    } else if (focusArea != null) {
      response = await _client
          .from('workout_templates')
          .select(_templateSelectWithExercises)
          .eq('creator_id', creatorId)
          .eq('focus_area', focusArea)
          .order('created_at', ascending: false);
    } else if (limit != null) {
      response = await _client
          .from('workout_templates')
          .select(_templateSelectWithExercises)
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false)
          .limit(limit);
    } else {
      response = await _client
          .from('workout_templates')
          .select(_templateSelectWithExercises)
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);
    }

    return (response as List)
        .map((json) =>
            WorkoutTemplateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutTemplateModel> getTemplateById(String templateId) async {
    final response = await _client
        .from('workout_templates')
        .select(_templateSelectWithExercises)
        .eq('id', templateId)
        .single();

    return WorkoutTemplateModel.fromJson(response);
  }

  @override
  Future<WorkoutTemplateModel> createTemplate({
    required String name,
    String? nameKo,
    String? description,
    required List<TemplateExerciseInput> exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    final creatorId = await _getMyAccountId();

    // Insert template
    final templateResponse = await _client
        .from('workout_templates')
        .insert({
          'creator_id': creatorId,
          'name': name,
          if (nameKo != null) 'name_ko': nameKo,
          if (description != null) 'description': description,
          if (estimatedDurationMinutes != null)
            'estimated_duration_minutes': estimatedDurationMinutes,
          if (focusArea != null) 'focus_area': focusArea,
        })
        .select(_templateSelectSimple)
        .single();

    final templateId = templateResponse['id'] as String;

    // Insert exercises if any
    if (exercises.isNotEmpty) {
      final exerciseInserts = exercises.map((e) {
        final json = e.toJson();
        json['template_id'] = templateId;
        return json;
      }).toList();

      await _client.from('workout_template_exercises').insert(exerciseInserts);
    }

    // Return full template with exercises
    return getTemplateById(templateId);
  }

  @override
  Future<WorkoutTemplateModel> updateTemplate({
    required String templateId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseInput>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    // Update template metadata if any fields provided
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (nameKo != null) updates['name_ko'] = nameKo;
    if (description != null) updates['description'] = description;
    if (estimatedDurationMinutes != null) {
      updates['estimated_duration_minutes'] = estimatedDurationMinutes;
    }
    if (focusArea != null) updates['focus_area'] = focusArea;

    if (updates.isNotEmpty) {
      await _client
          .from('workout_templates')
          .update(updates)
          .eq('id', templateId);
    }

    // Update exercises if provided (replace all)
    if (exercises != null) {
      // Delete existing exercises
      await _client
          .from('workout_template_exercises')
          .delete()
          .eq('template_id', templateId);

      // Insert new exercises
      if (exercises.isNotEmpty) {
        final exerciseInserts = exercises.map((e) {
          final json = e.toJson();
          json['template_id'] = templateId;
          return json;
        }).toList();

        await _client
            .from('workout_template_exercises')
            .insert(exerciseInserts);
      }
    }

    // Return updated template
    return getTemplateById(templateId);
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await _client.from('workout_templates').delete().eq('id', templateId);
  }

  @override
  Future<void> incrementUsage(String templateId) async {
    await _client.rpc<void>('increment_template_usage', params: {
      'p_template_id': templateId,
    });
  }
}
