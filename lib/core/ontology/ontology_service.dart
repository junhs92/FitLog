import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/active_session/domain/entities/exercise_entity.dart';
import '../../features/active_session/domain/entities/exercise_set_entity.dart';
import '../../features/muscle_map/domain/entities/muscle_group.dart';
import 'exercise_ontology.dart';
import 'movement_ontology.dart';
import 'muscle_ontology.dart';
import 'ontology_triple.dart';

/// Returned by [OntologyService.computeRecoveryDays] when a set contains the
/// [SetTag.pain] tag. Callers MUST check for this value and flag for trainer
/// review instead of using it as a numeric duration.
const double kPainAlertRecovery = -1.0;

/// Facade that composes [MuscleOntology], [ExerciseOntology], and
/// [MovementOntology] into a single high-level query interface.
///
/// The rest of the app consumes this class rather than the individual ontology
/// classes. All inputs and outputs use existing domain types ([ExerciseEntity],
/// [MuscleGroup]) so callers need no knowledge of [OntologyMuscle].
///
/// This class is stateless — all data is in compile-time constants.
class OntologyService {
  const OntologyService();

  // ---------------------------------------------------------------------------
  // Muscle queries
  // ---------------------------------------------------------------------------

  /// Returns all [MuscleGroup] values that are antagonists of [muscle].
  ///
  /// For [MuscleGroup.shoulders], checks all three deltoid heads and merges
  /// results (shoulders is always the return for any deltoid head antagonist
  /// that maps back to shoulders).
  List<MuscleGroup> getAntagonists(MuscleGroup muscle) {
    final ontologyMuscles = _toOntologyMuscles(muscle);
    final result = <MuscleGroup>{};
    for (final om in ontologyMuscles) {
      for (final antagonist in MuscleOntology.antagonistsOf(om)) {
        result.add(_toMuscleGroup(antagonist));
      }
    }
    return result.toList();
  }

  /// Returns true if [a] and [b] are antagonist muscle groups.
  bool areAntagonistGroups(MuscleGroup a, MuscleGroup b) {
    return getAntagonists(a).contains(b);
  }

  // ---------------------------------------------------------------------------
  // Exercise → muscle
  // ---------------------------------------------------------------------------

  /// Returns the primary [MuscleGroup] values activated by [exercise].
  ///
  /// Returns an empty list if [exercise.family] is null or not in the ontology.
  List<MuscleGroup> getPrimaryMuscles(ExerciseEntity exercise) {
    if (exercise.family == null) return [];
    return ExerciseOntology.getPrimaryMuscles(exercise.family!)
        .map(_toMuscleGroup)
        .toSet()
        .toList();
  }

  /// Returns the secondary [MuscleGroup] values activated by [exercise].
  List<MuscleGroup> getSecondaryMuscles(ExerciseEntity exercise) {
    if (exercise.family == null) return [];
    return ExerciseOntology.getSecondaryMuscles(exercise.family!)
        .map(_toMuscleGroup)
        .toSet()
        .toList();
  }

  /// Returns a map of [MuscleGroup] → recovery load (0.0–1.0) for [exercise].
  ///
  /// When multiple [OntologyMuscle] nodes map to the same [MuscleGroup]
  /// (e.g., two deltoid heads), takes the maximum load for that group.
  Map<MuscleGroup, double> getRecoveryLoad(ExerciseEntity exercise) {
    if (exercise.family == null) return {};
    final ontologyMap = ExerciseOntology.getRecoveryLoad(exercise.family!);
    final result = <MuscleGroup, double>{};
    for (final entry in ontologyMap.entries) {
      final group = _toMuscleGroup(entry.key);
      final existing = result[group] ?? 0.0;
      if (entry.value > existing) result[group] = entry.value;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Exercise → exercise
  // ---------------------------------------------------------------------------

  /// Returns true if [ex1] and [ex2] are complementary exercises
  /// (antagonist muscle groups or opposite movement patterns).
  bool areComplementary(ExerciseEntity ex1, ExerciseEntity ex2) {
    if (ex1.family == null || ex2.family == null) return false;
    return MovementOntology.areComplementary(ex1.family!, ex2.family!);
  }

  /// Returns an ontological distance score between two exercises.
  ///
  /// 0.0 = nearly identical (same muscles, same pattern)
  /// 1.0 = completely different
  ///
  /// Null family falls back to comparing movementGroup from [ExerciseEntity]
  /// directly using the movement group string.
  double muscleSimilarity(ExerciseEntity ex1, ExerciseEntity ex2) {
    if (ex1.family != null && ex2.family != null) {
      return MovementOntology.muscleSimilarityScore(
        ex1.family!,
        ex2.family!,
      );
    }
    // Fallback when family is unknown: compare movementGroup strings only
    final groupDiffers = ex1.movementGroup != ex2.movementGroup ? 1.0 : 0.0;
    return (0.20 * groupDiffers).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Session-level queries
  // ---------------------------------------------------------------------------

  /// Returns true if the session [exercises] list is balanced between push and
  /// pull movement patterns.
  ///
  /// A session is balanced when push:pull ratio is within [0.5, 2.0].
  /// Legs, core, and other movement groups are excluded from the ratio.
  bool isSessionBalanced(List<ExerciseEntity> exercises) {
    int pushCount = 0;
    int pullCount = 0;
    for (final exercise in exercises) {
      final group = exercise.family != null
          ? MovementOntology.getMovementGroup(exercise.family!)
          : exercise.movementGroup;
      if (group == 'push') pushCount++;
      if (group == 'pull') pullCount++;
    }
    if (pullCount == 0 && pushCount == 0) return true;
    if (pullCount == 0) return false;
    final ratio = pushCount / pullCount;
    return ratio >= 0.5 && ratio <= 2.0;
  }

  /// Returns aggregated recovery load per [MuscleGroup] across all [exercises].
  ///
  /// Loads are summed (not capped) — use [getOverloadedMuscles] to flag
  /// muscles that exceeded the threshold.
  Map<MuscleGroup, double> getSessionRecoveryLoad(
    List<ExerciseEntity> exercises,
  ) {
    final totals = <MuscleGroup, double>{};
    for (final exercise in exercises) {
      final load = getRecoveryLoad(exercise);
      for (final entry in load.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0.0) + entry.value;
      }
    }
    return totals;
  }

  /// Returns muscles whose summed session recovery load exceeds [threshold].
  ///
  /// Default threshold (2.0) corresponds to a muscle appearing as primary
  /// across multiple exercises — a sign of over-specialisation in a single
  /// session.
  List<MuscleGroup> getOverloadedMuscles(
    List<ExerciseEntity> exercises, {
    double threshold = 2.0,
  }) {
    return getSessionRecoveryLoad(exercises)
        .entries
        .where((e) => e.value > threshold)
        .map((e) => e.key)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Recovery queries
  // ---------------------------------------------------------------------------

  /// Computes recovery days required for [muscle] after a session containing
  /// [sets], using the RPE–Recovery formula (02_relations.md Part F).
  ///
  /// [sets] must contain only working sets where [muscle] was a **primary**
  /// activation — callers are responsible for this filtering.
  ///
  /// [exerciseCategory] is the category of the dominant exercise
  /// (use the exercise that produced the peak RPE set).
  ///
  /// Returns [kPainAlertRecovery] (-1.0) if any set has a [SetTag.pain] tag.
  /// Callers must check for this value and flag for trainer review.
  ///
  /// Formula:
  /// ```
  /// recoveryDays = base × rpeMultiplier × volumeMultiplier × categoryMultiplier
  ///               + tagBonus
  /// result: rounded up to nearest 0.5, capped at 5.0
  /// ```
  double computeRecoveryDays(
    MuscleGroup muscle,
    List<ExerciseSetEntity> sets,
    String exerciseCategory,
  ) {
    if (sets.isEmpty) return 0.0;

    // Pain alert — do not compute, surface to trainer
    if (sets.any((s) => s.tags.contains(SetTag.pain))) {
      return kPainAlertRecovery;
    }

    // Working sets only (exclude warmup-tagged)
    final workingSets =
        sets.where((s) => !s.tags.contains(SetTag.warmup)).toList();
    if (workingSets.isEmpty) return 0.0;

    // Step 1 — Base recovery for this muscle group
    final base = _baseRecoveryDays(muscle);

    // Step 2 — Resolve RPE per set (apply F-6 null defaults)
    final resolvedRpes = workingSets.map(_resolveRpe).toList();

    // Step 3 — Peak RPE → F-1 multiplier
    final peakRpe = resolvedRpes.reduce((a, b) => a > b ? a : b);
    final rpeMultiplier = _rpeMultiplier(peakRpe);

    // Step 4 — Working set count → F-2 multiplier
    final volumeMultiplier = _volumeMultiplier(workingSets.length);

    // Step 5 — Exercise category → F-3 multiplier
    final categoryMultiplier = _categoryMultiplier(exerciseCategory);

    // Step 6 — Tag bonuses across all sets (F-4), capped at 1.0
    final tagBonus = _tagBonus(workingSets);

    // Step 7 — Compute, round up to nearest 0.5, cap at 5.0
    final raw = base * rpeMultiplier * volumeMultiplier * categoryMultiplier
        + tagBonus;
    return _roundUpToHalf(raw).clamp(0.0, 5.0);
  }

  /// Returns true if [muscle] has recovered from its last session.
  ///
  /// [requiredRecoveryDays] is typically the value returned by
  /// [computeRecoveryDays] for a previous session.
  bool isRecovered(
    MuscleGroup muscle,
    DateTime lastWorkedAt,
    double requiredRecoveryDays,
  ) {
    if (requiredRecoveryDays <= 0) return true;
    final hoursElapsed =
        DateTime.now().difference(lastWorkedAt).inMinutes / 60.0;
    return hoursElapsed >= requiredRecoveryDays * 24;
  }

  /// Returns all muscles that have not yet recovered.
  ///
  /// [lastWorkedDates] — map of muscle → last session date.
  /// [recoveryDaysByMuscle] — pre-computed required recovery per muscle
  ///   (from [computeRecoveryDays] for each muscle's last session).
  List<MuscleGroup> getUnrecoveredMuscles(
    Map<MuscleGroup, DateTime> lastWorkedDates,
    Map<MuscleGroup, double> recoveryDaysByMuscle,
  ) {
    return lastWorkedDates.keys.where((muscle) {
      final required = recoveryDaysByMuscle[muscle] ?? 0.0;
      if (required == kPainAlertRecovery) return true; // pain = always unrecovered
      return !isRecovered(muscle, lastWorkedDates[muscle]!, required);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Private — type bridging
  // ---------------------------------------------------------------------------

  /// Converts a [MuscleGroup] to the corresponding [OntologyMuscle] node(s).
  ///
  /// [MuscleGroup.shoulders] returns all three deltoid heads.
  List<OntologyMuscle> _toOntologyMuscles(MuscleGroup group) {
    return OntologyMuscle.fromMuscleGroup(group);
  }

  MuscleGroup _toMuscleGroup(OntologyMuscle muscle) {
    return muscle.toMuscleGroup();
  }

  // ---------------------------------------------------------------------------
  // Private — RPE formula helpers (Part F of 02_relations.md)
  // ---------------------------------------------------------------------------

  /// Base recovery days for a [MuscleGroup].
  /// Uses the first matching [OntologyMuscle] (all nodes in a group share the
  /// same base value; shoulder heads all return 1.5).
  double _baseRecoveryDays(MuscleGroup group) {
    final nodes = OntologyMuscle.fromMuscleGroup(group);
    if (nodes.isEmpty) return 1.0;
    return MuscleOntology.baseRecoveryDays(nodes.first);
  }

  /// F-1: RPE → recovery multiplier.
  /// Continuous step function from 02_relations.md Part F-1.
  double _rpeMultiplier(double rpe) {
    if (rpe <= 4) return 0.5;
    if (rpe < 5.5) return 0.7;
    if (rpe < 6.5) return 0.85;
    if (rpe < 7.5) return 1.0;
    if (rpe < 8.5) return 1.3;
    if (rpe < 9.5) return 1.6;
    return 2.0; // RPE 10
  }

  /// F-2: Working set count → volume multiplier.
  double _volumeMultiplier(int workingSets) {
    if (workingSets <= 2) return 0.75;
    if (workingSets <= 4) return 1.0;
    if (workingSets <= 6) return 1.3;
    if (workingSets <= 9) return 1.6;
    return 2.0; // 10+
  }

  /// F-3: Exercise category → compound fatigue multiplier.
  double _categoryMultiplier(String category) {
    switch (category) {
      case ExerciseCategory.compound:
        return 1.2;
      case ExerciseCategory.isolation:
        return 1.0;
      case ExerciseCategory.cardio:
        return 0.6;
      case ExerciseCategory.mobility:
        return 0.3;
      case ExerciseCategory.warmup:
      case ExerciseCategory.cooldown:
        return 0.0;
      default:
        return 1.0;
    }
  }

  /// F-6: Null RPE default — infers RPE from set context.
  double _resolveRpe(ExerciseSetEntity set) {
    if (set.rpe != null) return set.rpe!;
    if (set.tags.contains(SetTag.failureSet)) return 10.0;
    if (set.tags.contains(SetTag.fatigue)) return 8.5;
    if (set.tags.contains(SetTag.goodCondition)) return 6.5;
    if (set.setNumber == 1) return 7.0;
    if (set.setNumber >= 3) return 7.5;
    return 7.0;
  }

  /// F-4: Tag bonuses summed and capped at 1.0.
  double _tagBonus(List<ExerciseSetEntity> workingSets) {
    var total = 0.0;
    for (final set in workingSets) {
      for (final tag in set.tags) {
        switch (tag) {
          case SetTag.failureSet:
            total += 0.5;
          case SetTag.dropSet:
            total += 0.3;
          case SetTag.fatigue:
            total += 0.2;
          case SetTag.formIssue:
            total += 0.1;
          case SetTag.goodCondition:
            total = (total - 0.2).clamp(0.0, double.infinity);
          case SetTag.warmup:
          case SetTag.pr:
          case SetTag.pain: // handled upstream — should not reach here
            break;
        }
      }
    }
    return total.clamp(0.0, 1.0);
  }

  /// Round up [value] to the nearest 0.5.
  double _roundUpToHalf(double value) {
    return (value * 2).ceil() / 2;
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Riverpod provider for [OntologyService].
///
/// Register in your DI graph and inject into services that need ontology queries:
/// ```dart
/// final myService = ref.watch(ontologyServiceProvider);
/// ```
final ontologyServiceProvider = Provider<OntologyService>((ref) {
  return const OntologyService();
});
