import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/active_session/domain/entities/exercise_entity.dart';
import '../../features/active_session/domain/services/exercise_recommendation_service.dart';
import '../../features/active_session/presentation/providers/session_provider.dart';
import '../../features/muscle_map/domain/entities/muscle_group.dart';
import 'common/exercise_gif_image.dart';

/// Extracted content widget for exercise picker
/// Can be embedded in dialogs or sheets without its own container/header
class ExercisePickerContent extends ConsumerStatefulWidget {
  final String? clientId;
  final void Function(ExerciseEntity exercise) onExerciseSelected;

  const ExercisePickerContent({
    super.key,
    this.clientId,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<ExercisePickerContent> createState() =>
      _ExercisePickerContentState();
}

class _ExercisePickerContentState extends ConsumerState<ExercisePickerContent> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscleFilter;

  /// Get Korean display name for movement group
  String _getGroupDisplayName(String group) {
    switch (group) {
      case MovementGroup.push:
        return '밀기';
      case MovementGroup.pull:
        return '당기기';
      case MovementGroup.legs:
        return '하체';
      case MovementGroup.core:
        return '코어';
      case MovementGroup.other:
        return '기타';
      default:
        return group;
    }
  }

  /// Group exercises by movement group
  Map<String, List<ExerciseEntity>> _groupByMovementGroup(
      List<ExerciseEntity> exercises) {
    final grouped = <String, List<ExerciseEntity>>{};
    for (final exercise in exercises) {
      final group = exercise.movementGroup;
      grouped.putIfAbsent(group, () => []).add(exercise);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exerciseLibraryProvider(_searchQuery.isEmpty ? null : _searchQuery),
    );

    // Get recommendations if clientId is provided
    final recommendationsAsync = widget.clientId != null
        ? ref.watch(exerciseRecommendationsProvider(widget.clientId!))
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: '운동 검색...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
              filled: true,
              fillColor: AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Muscle filter chips
        _buildMuscleFilterChips(),
        const Divider(height: 1),
        // Exercise list grouped by movement pattern
        Flexible(
          child: exercisesAsync.when(
            data: (allExercises) {
              // Filter exercises by muscle group if selected
              final exercises = _selectedMuscleFilter != null
                  ? allExercises.where((e) {
                      final muscleStr = e.muscleGroup?.toLowerCase() ?? '';
                      return muscleStr ==
                              _selectedMuscleFilter!.name.toLowerCase() ||
                          muscleStr == _selectedMuscleFilter!.displayNameKo;
                    }).toList()
                  : allExercises;

              if (exercises.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isEmpty
                              ? '운동이 없습니다'
                              : '"$_searchQuery" 검색 결과가 없습니다',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get recommendations data
              final recommendationsState = recommendationsAsync?.valueOrNull;
              final recommendations =
                  recommendationsState?.recommendations ?? [];
              final recommendedGroupOrder =
                  recommendationsState?.recommendedGroupOrder ??
                      MovementGroup.all;

              // Group exercises by movement group
              final grouped = _groupByMovementGroup(exercises);

              // Use recommended group order when not searching
              final sortedGroups =
                  _searchQuery.isEmpty ? recommendedGroupOrder : MovementGroup.all;

              // Build list with section headers
              final items = <Widget>[];

              // Add recommended exercises section (only when not searching and has recommendations)
              if (_searchQuery.isEmpty && recommendations.isNotEmpty) {
                items.add(_buildRecommendedSection(recommendations));
              }

              // Add group-based exercises
              for (final group in sortedGroups) {
                final groupExercises = grouped[group];
                if (groupExercises == null || groupExercises.isEmpty) continue;

                // Check if this group is recommended (top 3)
                final groupIndex = recommendedGroupOrder.indexOf(group);
                final isRecommendedGroup =
                    groupIndex >= 0 && groupIndex < 3 && _searchQuery.isEmpty;

                // Section header
                items.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRecommendedGroup
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.neutral200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getGroupDisplayName(group),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isRecommendedGroup
                                  ? AppColors.success
                                  : AppColors.neutral700,
                            ),
                          ),
                        ),
                        if (isRecommendedGroup) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.thumb_up,
                                    size: 10, color: AppColors.success),
                                SizedBox(width: 3),
                                Text(
                                  '추천',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '${groupExercises.length}개',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                // Exercises in this group
                for (final exercise in groupExercises) {
                  items.add(_buildExerciseTile(exercise, recommendations));
                }
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: items,
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '운동 목록을 불러오는데 실패했습니다\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseTile(
      ExerciseEntity exercise, List<RecommendedExercise> recommendations) {
    // Check if this exercise is recommended
    final recommendation = recommendations.firstWhere(
      (r) => r.exercise.id == exercise.id,
      orElse: () => RecommendedExercise(exercise: exercise, score: 0),
    );
    final isRecommended =
        recommendation.score > 0 && recommendation.reason.isNotEmpty;

    return ListTile(
      leading: exercise.hasGif
          ? ExerciseGifThumbnail(
              imageUrl: exercise.imageUrl,
              size: 40,
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRecommended
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: isRecommended ? AppColors.success : AppColors.primary,
                size: 20,
              ),
            ),
      title: Text(
        exercise.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.neutralBlack,
        ),
      ),
      subtitle: Text(
        exercise.muscleGroup ?? exercise.movementGroup,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.neutral600,
        ),
      ),
      trailing: const Icon(
        Icons.add_circle_outline,
        color: AppColors.primary,
      ),
      onTap: () => widget.onExerciseSelected(exercise),
    );
  }

  /// Build the recommended exercises section
  Widget _buildRecommendedSection(List<RecommendedExercise> recommendations) {
    // Take top 5 recommendations with reasons
    final topRecommendations =
        recommendations.where((r) => r.reason.isNotEmpty).take(5).toList();

    if (topRecommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.neutralWhite),
                    SizedBox(width: 4),
                    Text(
                      '맞춤 추천',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${topRecommendations.length}개',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        // Recommended exercises
        ...topRecommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 2,
              ),
              child: Material(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: ListTile(
                  dense: true,
                  leading: rec.exercise.hasGif
                      ? ExerciseGifThumbnail(
                          imageUrl: rec.exercise.imageUrl,
                          size: 36,
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ),
                  title: Text(
                    rec.exercise.displayName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        rec.exercise.muscleGroup ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (rec.reason.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rec.reason,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(
                    Icons.add_circle,
                    color: AppColors.success,
                    size: 22,
                  ),
                  onTap: () => widget.onExerciseSelected(rec.exercise),
                ),
              ),
            )),
        const Divider(height: 24),
      ],
    );
  }

  /// Build muscle group filter chips
  Widget _buildMuscleFilterChips() {
    // Main muscle groups for filtering (excluding fullBody)
    const filterMuscles = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.quadriceps,
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
      MuscleGroup.core,
      MuscleGroup.calves,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          // All muscles chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              selected: _selectedMuscleFilter == null,
              label: const Text('전체'),
              labelStyle: TextStyle(
                fontSize: 12,
                color: _selectedMuscleFilter == null
                    ? AppColors.neutralWhite
                    : AppColors.neutral700,
              ),
              backgroundColor: AppColors.neutral100,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.neutralWhite,
              onSelected: (_) => setState(() => _selectedMuscleFilter = null),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          // Individual muscle chips
          ...filterMuscles.map((muscle) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  selected: _selectedMuscleFilter == muscle,
                  label: Text(muscle.displayNameKo),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _selectedMuscleFilter == muscle
                        ? AppColors.neutralWhite
                        : AppColors.neutral700,
                  ),
                  backgroundColor: AppColors.neutral100,
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.neutralWhite,
                  onSelected: (_) => setState(() {
                    _selectedMuscleFilter =
                        _selectedMuscleFilter == muscle ? null : muscle;
                  }),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )),
        ],
      ),
    );
  }
}
