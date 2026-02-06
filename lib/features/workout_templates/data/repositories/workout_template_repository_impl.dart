import 'package:dartz/dartz.dart';

import '../../../../shared/models/result.dart';
import '../../domain/entities/workout_template_entity.dart';
import '../../domain/repositories/workout_template_repository.dart';
import '../datasources/workout_template_remote_datasource.dart';

/// Implementation of WorkoutTemplateRepository using remote data source
class WorkoutTemplateRepositoryImpl implements WorkoutTemplateRepository {
  final WorkoutTemplateRemoteDataSource _remoteDataSource;

  WorkoutTemplateRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<WorkoutTemplateEntity>>> getTemplates({
    String? focusArea,
    int? limit,
  }) async {
    try {
      final templates = await _remoteDataSource.getTemplates(
        focusArea: focusArea,
        limit: limit,
      );
      return Right(templates);
    } catch (e) {
      return Left(ServerFailure('Failed to get templates: $e'));
    }
  }

  @override
  Future<Result<WorkoutTemplateEntity>> getTemplateById(
      String templateId) async {
    try {
      final template = await _remoteDataSource.getTemplateById(templateId);
      return Right(template);
    } catch (e) {
      return Left(ServerFailure('Failed to get template: $e'));
    }
  }

  @override
  Future<Result<WorkoutTemplateEntity>> createTemplate({
    required String name,
    String? nameKo,
    String? description,
    required List<TemplateExerciseInput> exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    try {
      final template = await _remoteDataSource.createTemplate(
        name: name,
        nameKo: nameKo,
        description: description,
        exercises: exercises,
        estimatedDurationMinutes: estimatedDurationMinutes,
        focusArea: focusArea,
      );
      return Right(template);
    } catch (e) {
      return Left(ServerFailure('Failed to create template: $e'));
    }
  }

  @override
  Future<Result<WorkoutTemplateEntity>> updateTemplate({
    required String templateId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseInput>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    try {
      final template = await _remoteDataSource.updateTemplate(
        templateId: templateId,
        name: name,
        nameKo: nameKo,
        description: description,
        exercises: exercises,
        estimatedDurationMinutes: estimatedDurationMinutes,
        focusArea: focusArea,
      );
      return Right(template);
    } catch (e) {
      return Left(ServerFailure('Failed to update template: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTemplate(String templateId) async {
    try {
      await _remoteDataSource.deleteTemplate(templateId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete template: $e'));
    }
  }

  @override
  Future<Result<void>> incrementUsage(String templateId) async {
    try {
      await _remoteDataSource.incrementUsage(templateId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to increment usage: $e'));
    }
  }
}
