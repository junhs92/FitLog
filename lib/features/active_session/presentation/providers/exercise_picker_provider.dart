import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import 'session_provider.dart';

/// Picker navigation steps
enum PickerStep {
  familySelection,   // Step 1: Choose a family
  variationFilter,   // Step 2: Filter by angle/equipment/grip
  finalSelection,    // Step 3: Pick the exact exercise
}

/// State for the hierarchical exercise picker
class ExercisePickerState {
  final PickerStep step;
  final String? selectedFamilyKey;
  final String? selectedFamilyDisplayName;
  final String? selectedAngle;
  final String? selectedEquipment;
  final String? selectedGripOrientation;

  const ExercisePickerState({
    this.step = PickerStep.familySelection,
    this.selectedFamilyKey,
    this.selectedFamilyDisplayName,
    this.selectedAngle,
    this.selectedEquipment,
    this.selectedGripOrientation,
  });

  ExercisePickerState copyWith({
    PickerStep? step,
    String? selectedFamilyKey,
    String? selectedFamilyDisplayName,
    String? selectedAngle,
    String? selectedEquipment,
    String? selectedGripOrientation,
    bool clearAngle = false,
    bool clearEquipment = false,
    bool clearGrip = false,
  }) {
    return ExercisePickerState(
      step: step ?? this.step,
      selectedFamilyKey: selectedFamilyKey ?? this.selectedFamilyKey,
      selectedFamilyDisplayName: selectedFamilyDisplayName ?? this.selectedFamilyDisplayName,
      selectedAngle: clearAngle ? null : (selectedAngle ?? this.selectedAngle),
      selectedEquipment: clearEquipment ? null : (selectedEquipment ?? this.selectedEquipment),
      selectedGripOrientation: clearGrip ? null : (selectedGripOrientation ?? this.selectedGripOrientation),
    );
  }
}

/// Notifier managing the hierarchical picker drill-down state
class ExercisePickerNotifier extends StateNotifier<ExercisePickerState> {
  final List<ExerciseEntity> _allExercises;

  ExercisePickerNotifier(this._allExercises) : super(const ExercisePickerState());

  /// Get exercises for the currently selected family
  List<ExerciseEntity> get _familyExercises {
    if (state.selectedFamilyKey == null) return [];
    // Check if familyKey is an exercise ID (for ungrouped exercises)
    final byFamily = _allExercises.where(
      (e) => e.family == state.selectedFamilyKey,
    ).toList();
    if (byFamily.isNotEmpty) return byFamily;
    // Fallback: treat as exercise ID
    return _allExercises.where((e) => e.id == state.selectedFamilyKey).toList();
  }

  /// Select a family. If <=3 exercises, skip Step 2.
  void selectFamily(String familyKey, String displayName, {Set<String>? exerciseIdsInSession}) {
    final exercises = _allExercises.where((e) => e.family == familyKey).toList();

    // Filter out exercises already in session
    final available = exerciseIdsInSession != null
        ? exercises.where((e) => !exerciseIdsInSession.contains(e.id)).toList()
        : exercises;

    if (available.length == 1) {
      // Single exercise: handled by UI (add directly)
      state = state.copyWith(
        step: PickerStep.finalSelection,
        selectedFamilyKey: familyKey,
        selectedFamilyDisplayName: displayName,
      );
      return;
    }

    if (available.length <= 3) {
      // 2-3 exercises: skip variation filter, go to final selection
      state = state.copyWith(
        step: PickerStep.finalSelection,
        selectedFamilyKey: familyKey,
        selectedFamilyDisplayName: displayName,
      );
      return;
    }

    // >3 exercises: show variation filter
    state = state.copyWith(
      step: PickerStep.variationFilter,
      selectedFamilyKey: familyKey,
      selectedFamilyDisplayName: displayName,
      clearAngle: true,
      clearEquipment: true,
      clearGrip: true,
    );
  }

  /// Set angle filter and recompute valid combos
  void setAngleFilter(String? value) {
    state = state.copyWith(
      selectedAngle: value,
      clearAngle: value == null,
    );
    _autoSelectSingles();
  }

  /// Set equipment filter
  void setEquipmentFilter(String? value) {
    state = state.copyWith(
      selectedEquipment: value,
      clearEquipment: value == null,
    );
    _autoSelectSingles();
  }

  /// Set grip orientation filter
  void setGripFilter(String? value) {
    state = state.copyWith(
      selectedGripOrientation: value,
      clearGrip: value == null,
    );
    _autoSelectSingles();
  }

  /// Auto-select if only 1 valid option remains on an axis
  void _autoSelectSingles() {
    final filtered = getFilteredExercises();
    if (filtered.length <= 3 && state.step == PickerStep.variationFilter) {
      state = state.copyWith(step: PickerStep.finalSelection);
    }
  }

  /// Get exercises filtered by current selections
  List<ExerciseEntity> getFilteredExercises({Set<String>? exerciseIdsInSession}) {
    var exercises = _familyExercises;

    // Filter out exercises in session
    if (exerciseIdsInSession != null) {
      exercises = exercises.where((e) => !exerciseIdsInSession.contains(e.id)).toList();
    }

    if (state.selectedAngle != null) {
      exercises = exercises.where((e) => e.angle == state.selectedAngle).toList();
    }
    if (state.selectedEquipment != null) {
      exercises = exercises.where((e) => e.equipment == state.selectedEquipment).toList();
    }
    if (state.selectedGripOrientation != null) {
      exercises = exercises.where((e) => e.gripOrientation == state.selectedGripOrientation).toList();
    }
    return exercises;
  }

  /// Get available options for an axis, considering other active filters.
  /// Returns map of value -> isValid (false = greyed out).
  Map<String, bool> getAvailableOptions(String axis, {Set<String>? exerciseIdsInSession}) {
    var exercises = _familyExercises;

    // Filter out exercises in session
    if (exerciseIdsInSession != null) {
      exercises = exercises.where((e) => !exerciseIdsInSession.contains(e.id)).toList();
    }

    // Apply OTHER filters (not the axis we're computing for)
    if (axis != 'angle' && state.selectedAngle != null) {
      exercises = exercises.where((e) => e.angle == state.selectedAngle).toList();
    }
    if (axis != 'equipment' && state.selectedEquipment != null) {
      exercises = exercises.where((e) => e.equipment == state.selectedEquipment).toList();
    }
    if (axis != 'grip' && state.selectedGripOrientation != null) {
      exercises = exercises.where((e) => e.gripOrientation == state.selectedGripOrientation).toList();
    }

    // Collect valid values for this axis
    final validValues = <String>{};
    for (final ex in exercises) {
      String? value;
      switch (axis) {
        case 'angle':
          value = ex.angle;
          break;
        case 'equipment':
          value = ex.equipment;
          break;
        case 'grip':
          value = ex.gripOrientation;
          break;
      }
      if (value != null && value.isNotEmpty) {
        validValues.add(value);
      }
    }

    // Get ALL values for this axis in the family (before other filters)
    var allFamilyExercises = _familyExercises;
    if (exerciseIdsInSession != null) {
      allFamilyExercises = allFamilyExercises
          .where((e) => !exerciseIdsInSession.contains(e.id)).toList();
    }
    final allValues = <String>{};
    for (final ex in allFamilyExercises) {
      String? value;
      switch (axis) {
        case 'angle':
          value = ex.angle;
          break;
        case 'equipment':
          value = ex.equipment;
          break;
        case 'grip':
          value = ex.gripOrientation;
          break;
      }
      if (value != null && value.isNotEmpty) {
        allValues.add(value);
      }
    }

    // Map: value -> isValid
    final result = <String, bool>{};
    for (final v in allValues) {
      result[v] = validValues.contains(v);
    }
    return result;
  }

  /// Check if an axis has >1 distinct value (worth showing filter for)
  bool hasMultipleOptions(String axis, {Set<String>? exerciseIdsInSession}) {
    final options = getAvailableOptions(axis, exerciseIdsInSession: exerciseIdsInSession);
    // Filter out 'na' values for display purposes
    final meaningful = options.keys.where((k) => k != 'na' && k != 'neutral').toList();
    return meaningful.length > 1 || options.length > 1;
  }

  /// Navigate back
  void goBack() {
    switch (state.step) {
      case PickerStep.finalSelection:
        // Check if we should go to variation filter or family selection
        final exercises = _familyExercises;
        if (exercises.length > 3) {
          state = state.copyWith(
            step: PickerStep.variationFilter,
          );
        } else {
          reset();
        }
        break;
      case PickerStep.variationFilter:
        reset();
        break;
      case PickerStep.familySelection:
        break; // Already at top
    }
  }

  /// Reset to Step 1
  void reset() {
    state = const ExercisePickerState();
  }
}

/// Provider for the exercise picker notifier
/// Scoped per exercise picker sheet lifetime
final exercisePickerProvider =
    StateNotifierProvider.autoDispose<ExercisePickerNotifier, ExercisePickerState>((ref) {
  final exercisesAsync = ref.watch(exerciseLibraryProvider(null));
  final exercises = exercisesAsync.valueOrNull ?? [];
  return ExercisePickerNotifier(exercises);
});

/// Provider for family-scored list used in Step 1
/// Groups exercises by family, scores each family using max-score from recommendations
final familyScoredListProvider = Provider.autoDispose.family<List<ScoredFamily>, String>((ref, clientId) {
  debugPrint('📋 [familyScoredListProvider] Building for client: $clientId');

  final service = ref.read(exerciseRecommendationServiceProvider);

  // Get recommendation scores
  final recsAsync = ref.watch(exerciseRecommendationsProvider(clientId));
  final recommendations = recsAsync.valueOrNull?.recommendations ?? [];

  // Get contextual recommendations
  final contextualRecs = ref.watch(contextualRecommendationsProvider(clientId));

  // Get all exercises
  final exercisesAsync = ref.watch(exerciseLibraryProvider(null));
  final allExercises = exercisesAsync.valueOrNull ?? [];

  if (allExercises.isEmpty) {
    debugPrint('📋 [familyScoredListProvider] No exercises loaded yet');
    return [];
  }

  // Get exercises in session
  final sessionState = ref.watch(activeSessionProvider);
  final exerciseIdsInSession = sessionState.session?.exercises
      .map((e) => e.exercise.id)
      .toSet() ?? <String>{};

  // If recommendations available, use scored aggregation
  if (recommendations.isNotEmpty) {
    final families = service.aggregateToFamilyScores(
      scoredExercises: recommendations,
      contextualRecs: contextualRecs,
      allExercises: allExercises,
      exerciseIdsInSession: exerciseIdsInSession,
    );
    // Sort compound-first, then accessory, then mobility; each group sorted by score desc
    final compoundFamilies = families.where((f) => f.isCompound).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final accessoryFamilies = families.where((f) => f.isAccessory).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final mobilityFamilies = families.where((f) => f.isMobility).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final sorted = [...compoundFamilies, ...accessoryFamilies, ...mobilityFamilies];
    debugPrint('📋 [familyScoredListProvider] ${sorted.length} scored families (${compoundFamilies.length} compound, ${accessoryFamilies.length} accessory, ${mobilityFamilies.length} mobility)');
    return sorted;
  }

  // Fallback: build unscored families directly from exercise library
  debugPrint('📋 [familyScoredListProvider] No recs yet, building unscored families');
  final familyGroups = <String, List<ExerciseEntity>>{};
  final ungrouped = <ExerciseEntity>[];

  for (final exercise in allExercises) {
    if (exerciseIdsInSession.contains(exercise.id)) continue;
    final family = exercise.family;
    if (family != null && family.isNotEmpty) {
      familyGroups.putIfAbsent(family, () => []).add(exercise);
    } else {
      ungrouped.add(exercise);
    }
  }

  final families = <ScoredFamily>[];
  for (final entry in familyGroups.entries) {
    final totalInFamily = allExercises.where((e) => e.family == entry.key).length;
    final rep = entry.value.first;
    families.add(ScoredFamily(
      familyKey: entry.key,
      displayNameKo: ExerciseFamily.getDisplayNameKo(entry.key),
      score: 0,
      reason: '',
      exerciseCount: totalInFamily,
      availableCount: entry.value.length,
      movementGroup: rep.movementGroup,
      muscleGroup: rep.muscleGroup,
      familyCategory: rep.category,
    ));
  }
  for (final exercise in ungrouped) {
    families.add(ScoredFamily(
      familyKey: exercise.id,
      displayNameKo: exercise.displayName,
      score: 0,
      reason: '',
      exerciseCount: 1,
      availableCount: 1,
      movementGroup: exercise.movementGroup,
      muscleGroup: exercise.muscleGroup,
      isCustom: exercise.isCustom,
      familyCategory: exercise.category,
    ));
  }

  // Sort compound-first, then accessory, then mobility (alphabetical within each group)
  final compoundFamilies = families.where((f) => f.isCompound).toList()
    ..sort((a, b) => a.displayNameKo.compareTo(b.displayNameKo));
  final accessoryFamilies = families.where((f) => f.isAccessory).toList()
    ..sort((a, b) => a.displayNameKo.compareTo(b.displayNameKo));
  final mobilityFamilies = families.where((f) => f.isMobility).toList()
    ..sort((a, b) => a.displayNameKo.compareTo(b.displayNameKo));
  return [...compoundFamilies, ...accessoryFamilies, ...mobilityFamilies];
});

/// Provider that detects which accessory muscle groups the client has neglected
final neglectedAccessoriesProvider = Provider.autoDispose
    .family<Set<String>, String>((ref, clientId) {
  final service = ref.read(exerciseRecommendationServiceProvider);
  final sessionsAsync = ref.watch(clientRecentSessionsProvider(clientId));
  final sessions = sessionsAsync.valueOrNull ?? [];
  return service.getNeglectedAccessoryGroups(recentSessions: sessions);
});

/// A group of sets from one session, with a date
class SessionSetsGroup {
  final String sessionExerciseId;
  final DateTime date;
  final List<ExerciseSetEntity> sets;

  const SessionSetsGroup({
    required this.sessionExerciseId,
    required this.date,
    required this.sets,
  });
}

/// Data class for exercise picker inline history
class ExercisePickerHistoryData {
  final ExerciseSetEntity? pr;
  final List<SessionSetsGroup> recentSessions;

  const ExercisePickerHistoryData({
    this.pr,
    this.recentSessions = const [],
  });

  bool get hasData => pr != null || recentSessions.isNotEmpty;
}

/// Provider that fetches exercise history for inline display in the picker
final exercisePickerHistoryProvider = FutureProvider.autoDispose
    .family<ExercisePickerHistoryData, ({String clientId, String exerciseId})>((ref, params) async {
  final repository = ref.read(sessionRepositoryProvider);
  final result = await repository.getExerciseHistory(
    clientId: params.clientId,
    exerciseId: params.exerciseId,
    limit: 50,
  );

  return result.fold(
    (failure) => const ExercisePickerHistoryData(),
    (history) {
      if (history.isEmpty) return const ExercisePickerHistoryData();

      // Find PR using Epley formula: weight × (1 + reps/30)
      ExerciseSetEntity? pr;
      double maxEstimated1RM = 0;
      for (final set in history) {
        final weight = set.weight ?? 0;
        final reps = set.reps ?? 0;
        final estimated1RM = weight * (1 + reps / 30);
        if (estimated1RM > maxEstimated1RM) {
          maxEstimated1RM = estimated1RM;
          pr = set;
        }
      }

      // Group sets by sessionExerciseId, preserving order (most recent first)
      final groupMap = <String, List<ExerciseSetEntity>>{};
      final groupOrder = <String>[];
      for (final set in history) {
        final id = set.sessionExerciseId;
        if (!groupMap.containsKey(id)) {
          groupMap[id] = [];
          groupOrder.add(id);
        }
        groupMap[id]!.add(set);
      }

      // Take last 3 sessions
      final recentSessions = groupOrder.take(3).map((id) {
        final sets = groupMap[id]!;
        return SessionSetsGroup(
          sessionExerciseId: id,
          date: sets.first.completedAt,
          sets: sets,
        );
      }).toList();

      return ExercisePickerHistoryData(
        pr: pr,
        recentSessions: recentSessions,
      );
    },
  );
});
