import '../../features/active_session/domain/entities/exercise_entity.dart';
import 'exercise_ontology.dart';

/// Static movement hierarchy and complementary exercise knowledge base.
///
/// Encodes:
///   - Exercise family → movementGroup + movementDetail (Part C of 02_relations.md)
///   - Complementary exercise pairs (Part D of 02_relations.md)
///
/// [muscleSimilarityScore] composes with [ExerciseOntology] to measure
/// how interchangeable two exercise families are for variety/substitution logic.
class MovementOntology {
  MovementOntology._();

  // ---------------------------------------------------------------------------
  // Movement hierarchy map
  // family → (movementGroup, movementDetail)
  // null movementDetail = isolation movement with no directional sub-category
  // ---------------------------------------------------------------------------

  static const Map<String, (String, String?)> _movementMap = {
    // Chest — horizontal push
    ExerciseFamily.benchPress: ('push', 'horizontal'),
    ExerciseFamily.fly: ('push', 'horizontal'),
    ExerciseFamily.pushup: ('push', 'horizontal'),
    ExerciseFamily.pullover: ('pull', 'horizontal'),

    // Shoulders — push (vertical or isolation)
    ExerciseFamily.overheadPress: ('push', 'vertical'),
    ExerciseFamily.dip: ('push', 'vertical'),
    ExerciseFamily.lateralRaise: ('push', null),
    ExerciseFamily.frontRaise: ('push', null),
    ExerciseFamily.jmPress: ('push', 'vertical'),
    ExerciseFamily.tatePress: ('push', 'vertical'),

    // Shoulders — pull / isolation
    ExerciseFamily.rearDelt: ('pull', null),
    ExerciseFamily.yRaise: ('pull', null),
    ExerciseFamily.shrug: ('pull', null),
    ExerciseFamily.uprightRow: ('pull', 'vertical'),

    // Triceps — push isolation
    ExerciseFamily.tricepExtension: ('push', null),

    // Back — pull
    ExerciseFamily.row: ('pull', 'horizontal'),
    ExerciseFamily.rackPull: ('pull', 'horizontal'),
    ExerciseFamily.pulldown: ('pull', 'vertical'),
    ExerciseFamily.pullup: ('pull', 'vertical'),

    // Biceps / Forearms — pull isolation
    ExerciseFamily.curl: ('pull', null),
    ExerciseFamily.wristCurl: ('other', null),
    ExerciseFamily.grip: ('other', null),

    // Legs — quad dominant
    ExerciseFamily.squat: ('legs', 'squat'),
    ExerciseFamily.lunge: ('legs', 'lunge'),
    ExerciseFamily.legExtension: ('legs', 'squat'),
    ExerciseFamily.jump: ('legs', 'squat'),

    // Legs — hip dominant
    ExerciseFamily.deadlift: ('legs', 'hinge'),
    ExerciseFamily.hipThrust: ('legs', 'hinge'),
    ExerciseFamily.legCurl: ('legs', 'hinge'),
    ExerciseFamily.gluteKickback: ('legs', 'hinge'),
    ExerciseFamily.reverseHyper: ('legs', 'hinge'),

    // Legs — isolation
    ExerciseFamily.calfRaise: ('legs', null),
    ExerciseFamily.hipAdduction: ('legs', null),
    ExerciseFamily.hipAbduction: ('legs', null),

    // Core
    ExerciseFamily.plank: ('core', 'anti_extension'),
    ExerciseFamily.carry: ('core', 'anti_lateral_flexion'),
    ExerciseFamily.crunch: ('core', 'anti_flexion'),
    ExerciseFamily.rotation: ('core', 'rotation'),
    ExerciseFamily.mountainClimber: ('core', 'anti_extension'),

    // Full body / cardio / other
    ExerciseFamily.sled: ('other', null),
    ExerciseFamily.burpee: ('other', null),
    ExerciseFamily.battleRopes: ('other', null),
    ExerciseFamily.wallBall: ('other', null),
    ExerciseFamily.cardioMachine: ('other', null),

    // Mobility / warmup
    ExerciseFamily.foamRoll: ('other', null),
    ExerciseFamily.yoga: ('other', null),
    ExerciseFamily.shoulderMobility: ('other', null),
    ExerciseFamily.hipMobility: ('other', null),
    ExerciseFamily.spineMobility: ('other', null),
    ExerciseFamily.ankleMobility: ('other', null),
  };

  // ---------------------------------------------------------------------------
  // Complementary pairs — bidirectional
  // Antagonist movement patterns that balance each other within the same session.
  // Source: 02_relations.md Part D.
  // ---------------------------------------------------------------------------

  static const List<(String, String)> _complementaryPairs = [
    (ExerciseFamily.benchPress, ExerciseFamily.row),
    (ExerciseFamily.overheadPress, ExerciseFamily.pulldown),
    (ExerciseFamily.overheadPress, ExerciseFamily.pullup),
    (ExerciseFamily.squat, ExerciseFamily.deadlift),
    (ExerciseFamily.hipThrust, ExerciseFamily.legExtension),
    (ExerciseFamily.plank, ExerciseFamily.crunch),
    (ExerciseFamily.tricepExtension, ExerciseFamily.curl),
    (ExerciseFamily.lateralRaise, ExerciseFamily.rearDelt),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the movement group for an exercise family (e.g. 'push', 'pull',
  /// 'legs', 'core', 'other'). Returns null if the family is not in the map.
  static String? getMovementGroup(String exerciseFamily) {
    return _movementMap[exerciseFamily]?.$1;
  }

  /// Returns the movement detail for an exercise family (e.g. 'horizontal',
  /// 'vertical', 'hinge', 'squat'). Returns null for isolation movements or
  /// unknown families.
  static String? getMovementDetail(String exerciseFamily) {
    return _movementMap[exerciseFamily]?.$2;
  }

  /// Returns all families that are complementary to [exerciseFamily].
  /// Bidirectional — checks both sides of every pair.
  static List<String> getComplementaryFamilies(String exerciseFamily) {
    final result = <String>[];
    for (final pair in _complementaryPairs) {
      if (pair.$1 == exerciseFamily) result.add(pair.$2);
      if (pair.$2 == exerciseFamily) result.add(pair.$1);
    }
    return result;
  }

  /// Returns true if [family1] and [family2] are complementary.
  static bool areComplementary(String family1, String family2) {
    return getComplementaryFamilies(family1).contains(family2);
  }

  /// Returns all exercise families that share the given [movementDetail].
  /// Useful for finding substitution candidates within the same movement pattern.
  static List<String> getFamiliesByMovementDetail(String movementDetail) {
    return _movementMap.entries
        .where((e) => e.value.$2 == movementDetail)
        .map((e) => e.key)
        .toList();
  }

  /// Returns all exercise families that share the given [movementGroup].
  static List<String> getFamiliesByMovementGroup(String movementGroup) {
    return _movementMap.entries
        .where((e) => e.value.$1 == movementGroup)
        .map((e) => e.key)
        .toList();
  }

  /// Returns an ontological distance score between two exercise families.
  ///
  /// Score range: 0.0 (identical) → 1.0 (completely different)
  ///
  /// Formula (source: 01_concepts.md Concept 7):
  /// ```
  /// score =
  ///   0.40 × primaryMuscleDistanceFraction  (Jaccard distance on primary muscles)
  ///   0.25 × (movementDetail differs ? 1 : 0)
  ///   0.20 × (movementGroup differs ? 1 : 0)
  ///   0.15 × 0.0  (equipment overlap — reserved; not yet encoded)
  /// ```
  ///
  /// Lower score = more substitutable / more similar.
  /// Higher score = better for variety / complementary pairing.
  static double muscleSimilarityScore(String family1, String family2) {
    if (family1 == family2) return 0.0;

    // Component 1: Primary muscle Jaccard distance (0.0 = identical, 1.0 = no overlap)
    final primary1 = ExerciseOntology.getPrimaryMuscles(family1).toSet();
    final primary2 = ExerciseOntology.getPrimaryMuscles(family2).toSet();

    final double primaryDistanceFraction;
    if (primary1.isEmpty && primary2.isEmpty) {
      primaryDistanceFraction = 0.0;
    } else {
      final intersection = primary1.intersection(primary2).length;
      final union = primary1.union(primary2).length;
      primaryDistanceFraction = union == 0 ? 0.0 : 1.0 - (intersection / union);
    }

    // Component 2: Movement detail difference
    final detail1 = getMovementDetail(family1);
    final detail2 = getMovementDetail(family2);
    final detailDiffers =
        (detail1 != null || detail2 != null) && detail1 != detail2 ? 1.0 : 0.0;

    // Component 3: Movement group difference
    final group1 = getMovementGroup(family1);
    final group2 = getMovementGroup(family2);
    final groupDiffers =
        (group1 != null || group2 != null) && group1 != group2 ? 1.0 : 0.0;

    final score =
        0.40 * primaryDistanceFraction +
        0.25 * detailDiffers +
        0.20 * groupDiffers;
    // 0.15 * equipment (not yet encoded — reserved)

    return score.clamp(0.0, 1.0);
  }
}
