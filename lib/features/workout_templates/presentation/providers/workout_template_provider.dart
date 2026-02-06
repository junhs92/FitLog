import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/supabase_provider.dart';
import '../../data/datasources/workout_template_remote_datasource.dart';
import '../../data/repositories/workout_template_repository_impl.dart';
import '../../domain/entities/workout_template_entity.dart';
import '../../domain/repositories/workout_template_repository.dart';

export '../../domain/repositories/workout_template_repository.dart'
    show TemplateExerciseInput;

/// Provider for workout template remote data source
final workoutTemplateRemoteDataSourceProvider =
    Provider<WorkoutTemplateRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WorkoutTemplateRemoteDataSourceImpl(client);
});

/// Provider for workout template repository
final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((ref) {
  final dataSource = ref.watch(workoutTemplateRemoteDataSourceProvider);
  return WorkoutTemplateRepositoryImpl(dataSource);
});

/// Provider for all templates of the current trainer
final trainerTemplatesProvider =
    FutureProvider<List<WorkoutTemplateEntity>>((ref) async {
  final repository = ref.read(workoutTemplateRepositoryProvider);
  final result = await repository.getTemplates();
  return result.fold(
    (_) => <WorkoutTemplateEntity>[],
    (templates) => templates,
  );
});

/// Provider for a specific template by ID
final templateByIdProvider =
    FutureProvider.family<WorkoutTemplateEntity?, String>((ref, templateId) async {
  final repository = ref.read(workoutTemplateRepositoryProvider);
  final result = await repository.getTemplateById(templateId);
  return result.fold(
    (_) => null,
    (template) => template,
  );
});

/// State class for template mutation operations
class TemplateMutationState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const TemplateMutationState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;

  TemplateMutationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return TemplateMutationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for template mutation operations (create, update, delete)
class TemplateMutationNotifier extends StateNotifier<TemplateMutationState> {
  final WorkoutTemplateRepository _repository;
  final Ref _ref;

  TemplateMutationNotifier(this._repository, this._ref)
      : super(const TemplateMutationState());

  /// Create a new template
  Future<WorkoutTemplateEntity?> createTemplate({
    required String name,
    String? nameKo,
    String? description,
    required List<TemplateExerciseInput> exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);

    final result = await _repository.createTemplate(
      name: name,
      nameKo: nameKo,
      description: description,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDurationMinutes,
      focusArea: focusArea,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.toString(),
        );
        return null;
      },
      (template) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        // Invalidate templates list to refresh
        _ref.invalidate(trainerTemplatesProvider);
        return template;
      },
    );
  }

  /// Update an existing template
  Future<WorkoutTemplateEntity?> updateTemplate({
    required String templateId,
    String? name,
    String? nameKo,
    String? description,
    List<TemplateExerciseInput>? exercises,
    int? estimatedDurationMinutes,
    String? focusArea,
  }) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);

    final result = await _repository.updateTemplate(
      templateId: templateId,
      name: name,
      nameKo: nameKo,
      description: description,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDurationMinutes,
      focusArea: focusArea,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.toString(),
        );
        return null;
      },
      (template) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        // Invalidate caches
        _ref.invalidate(trainerTemplatesProvider);
        _ref.invalidate(templateByIdProvider(templateId));
        return template;
      },
    );
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);

    final result = await _repository.deleteTemplate(templateId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.toString(),
        );
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        // Invalidate templates list
        _ref.invalidate(trainerTemplatesProvider);
        return true;
      },
    );
  }

  /// Increment usage count when template is used
  Future<void> incrementUsage(String templateId) async {
    await _repository.incrementUsage(templateId);
    // Optionally invalidate cache
    _ref.invalidate(trainerTemplatesProvider);
  }

  /// Reset state
  void reset() {
    state = const TemplateMutationState();
  }
}

/// Provider for template mutation notifier
final templateMutationProvider =
    StateNotifierProvider<TemplateMutationNotifier, TemplateMutationState>(
        (ref) {
  final repository = ref.watch(workoutTemplateRepositoryProvider);
  return TemplateMutationNotifier(repository, ref);
});
