import '../../features/active_session/domain/entities/exercise_entity.dart';
import 'ontology_triple.dart';

/// Static exercise-to-muscle activation knowledge base.
///
/// Encodes muscle activation facts at the [ExerciseFamily] level — facts that
/// apply to ALL exercises within a family regardless of equipment variation.
/// Source: 02_relations.md Part B.
class ExerciseOntology {
  ExerciseOntology._();

  // ---------------------------------------------------------------------------
  // Activation map: ExerciseFamily key → List<MuscleActivation>
  // ---------------------------------------------------------------------------

  static const Map<String, List<MuscleActivation>> _activations = {
    // ── CHEST ──────────────────────────────────────────────────────────────
    ExerciseFamily.benchPress: [
      MuscleActivation.primary(ExerciseFamily.benchPress, OntologyMuscle.chest),
      MuscleActivation.secondary(ExerciseFamily.benchPress, OntologyMuscle.triceps),
      MuscleActivation.secondary(ExerciseFamily.benchPress, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.benchPress, OntologyMuscle.core),
    ],
    ExerciseFamily.fly: [
      MuscleActivation.primary(ExerciseFamily.fly, OntologyMuscle.chest),
      MuscleActivation.secondary(ExerciseFamily.fly, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.fly, OntologyMuscle.core),
    ],
    ExerciseFamily.pushup: [
      MuscleActivation.primary(ExerciseFamily.pushup, OntologyMuscle.chest),
      MuscleActivation.secondary(ExerciseFamily.pushup, OntologyMuscle.triceps),
      MuscleActivation.secondary(ExerciseFamily.pushup, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.pushup, OntologyMuscle.core),
      MuscleActivation.stabilizer(ExerciseFamily.pushup, OntologyMuscle.abs),
    ],
    ExerciseFamily.pullover: [
      MuscleActivation.primary(ExerciseFamily.pullover, OntologyMuscle.chest),
      MuscleActivation.primary(ExerciseFamily.pullover, OntologyMuscle.lats),
      MuscleActivation.secondary(ExerciseFamily.pullover, OntologyMuscle.triceps),
      MuscleActivation.stabilizer(ExerciseFamily.pullover, OntologyMuscle.core),
    ],

    // ── SHOULDERS ──────────────────────────────────────────────────────────
    ExerciseFamily.overheadPress: [
      MuscleActivation.primary(ExerciseFamily.overheadPress, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.primary(ExerciseFamily.overheadPress, OntologyMuscle.medialDeltoid),
      MuscleActivation.secondary(ExerciseFamily.overheadPress, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.secondary(ExerciseFamily.overheadPress, OntologyMuscle.triceps),
      MuscleActivation.stabilizer(ExerciseFamily.overheadPress, OntologyMuscle.core),
      MuscleActivation.stabilizer(ExerciseFamily.overheadPress, OntologyMuscle.traps),
    ],
    ExerciseFamily.lateralRaise: [
      MuscleActivation.primary(ExerciseFamily.lateralRaise, OntologyMuscle.medialDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.lateralRaise, OntologyMuscle.core),
    ],
    ExerciseFamily.frontRaise: [
      MuscleActivation.primary(ExerciseFamily.frontRaise, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.secondary(ExerciseFamily.frontRaise, OntologyMuscle.medialDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.frontRaise, OntologyMuscle.core),
    ],
    ExerciseFamily.rearDelt: [
      MuscleActivation.primary(ExerciseFamily.rearDelt, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.secondary(ExerciseFamily.rearDelt, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.rearDelt, OntologyMuscle.back),
      MuscleActivation.stabilizer(ExerciseFamily.rearDelt, OntologyMuscle.core),
    ],
    ExerciseFamily.yRaise: [
      MuscleActivation.primary(ExerciseFamily.yRaise, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.primary(ExerciseFamily.yRaise, OntologyMuscle.medialDeltoid),
      MuscleActivation.secondary(ExerciseFamily.yRaise, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.yRaise, OntologyMuscle.back),
      MuscleActivation.stabilizer(ExerciseFamily.yRaise, OntologyMuscle.core),
    ],
    ExerciseFamily.shrug: [
      MuscleActivation.primary(ExerciseFamily.shrug, OntologyMuscle.traps),
      MuscleActivation.stabilizer(ExerciseFamily.shrug, OntologyMuscle.forearms),
    ],
    ExerciseFamily.uprightRow: [
      MuscleActivation.primary(ExerciseFamily.uprightRow, OntologyMuscle.medialDeltoid),
      MuscleActivation.primary(ExerciseFamily.uprightRow, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.uprightRow, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.secondary(ExerciseFamily.uprightRow, OntologyMuscle.biceps),
      MuscleActivation.stabilizer(ExerciseFamily.uprightRow, OntologyMuscle.core),
    ],

    // ── TRICEPS ────────────────────────────────────────────────────────────
    ExerciseFamily.tricepExtension: [
      MuscleActivation.primary(ExerciseFamily.tricepExtension, OntologyMuscle.triceps),
      MuscleActivation.stabilizer(ExerciseFamily.tricepExtension, OntologyMuscle.core),
    ],
    ExerciseFamily.dip: [
      MuscleActivation.primary(ExerciseFamily.dip, OntologyMuscle.triceps),
      MuscleActivation.primary(ExerciseFamily.dip, OntologyMuscle.chest),
      MuscleActivation.secondary(ExerciseFamily.dip, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.dip, OntologyMuscle.core),
    ],
    ExerciseFamily.jmPress: [
      MuscleActivation.primary(ExerciseFamily.jmPress, OntologyMuscle.triceps),
      MuscleActivation.secondary(ExerciseFamily.jmPress, OntologyMuscle.chest),
      MuscleActivation.stabilizer(ExerciseFamily.jmPress, OntologyMuscle.core),
    ],
    ExerciseFamily.tatePress: [
      MuscleActivation.primary(ExerciseFamily.tatePress, OntologyMuscle.triceps),
      MuscleActivation.secondary(ExerciseFamily.tatePress, OntologyMuscle.chest),
      MuscleActivation.stabilizer(ExerciseFamily.tatePress, OntologyMuscle.core),
    ],

    // ── BACK ───────────────────────────────────────────────────────────────
    ExerciseFamily.row: [
      MuscleActivation.primary(ExerciseFamily.row, OntologyMuscle.back),
      MuscleActivation.primary(ExerciseFamily.row, OntologyMuscle.lats),
      MuscleActivation.secondary(ExerciseFamily.row, OntologyMuscle.biceps),
      MuscleActivation.secondary(ExerciseFamily.row, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.row, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.row, OntologyMuscle.core),
    ],
    ExerciseFamily.pulldown: [
      MuscleActivation.primary(ExerciseFamily.pulldown, OntologyMuscle.lats),
      MuscleActivation.secondary(ExerciseFamily.pulldown, OntologyMuscle.biceps),
      MuscleActivation.secondary(ExerciseFamily.pulldown, OntologyMuscle.back),
      MuscleActivation.stabilizer(ExerciseFamily.pulldown, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.pulldown, OntologyMuscle.core),
    ],
    ExerciseFamily.pullup: [
      MuscleActivation.primary(ExerciseFamily.pullup, OntologyMuscle.lats),
      MuscleActivation.primary(ExerciseFamily.pullup, OntologyMuscle.back),
      MuscleActivation.secondary(ExerciseFamily.pullup, OntologyMuscle.biceps),
      MuscleActivation.secondary(ExerciseFamily.pullup, OntologyMuscle.posteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.pullup, OntologyMuscle.core),
    ],
    ExerciseFamily.rackPull: [
      MuscleActivation.primary(ExerciseFamily.rackPull, OntologyMuscle.back),
      MuscleActivation.primary(ExerciseFamily.rackPull, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.rackPull, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.rackPull, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.rackPull, OntologyMuscle.core),
    ],

    // ── BICEPS / FOREARMS ──────────────────────────────────────────────────
    ExerciseFamily.curl: [
      MuscleActivation.primary(ExerciseFamily.curl, OntologyMuscle.biceps),
      MuscleActivation.secondary(ExerciseFamily.curl, OntologyMuscle.forearms),
      MuscleActivation.stabilizer(ExerciseFamily.curl, OntologyMuscle.core),
    ],
    ExerciseFamily.wristCurl: [
      MuscleActivation.primary(ExerciseFamily.wristCurl, OntologyMuscle.forearms),
    ],
    ExerciseFamily.grip: [
      MuscleActivation.primary(ExerciseFamily.grip, OntologyMuscle.forearms),
      MuscleActivation.secondary(ExerciseFamily.grip, OntologyMuscle.biceps),
    ],

    // ── LEGS — QUAD DOMINANT ───────────────────────────────────────────────
    ExerciseFamily.squat: [
      MuscleActivation.primary(ExerciseFamily.squat, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.squat, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.squat, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.squat, OntologyMuscle.core),
      MuscleActivation.stabilizer(ExerciseFamily.squat, OntologyMuscle.adductors),
    ],
    ExerciseFamily.lunge: [
      MuscleActivation.primary(ExerciseFamily.lunge, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.lunge, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.lunge, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.lunge, OntologyMuscle.core),
      MuscleActivation.stabilizer(ExerciseFamily.lunge, OntologyMuscle.adductors),
    ],
    ExerciseFamily.legExtension: [
      MuscleActivation.primary(ExerciseFamily.legExtension, OntologyMuscle.quadriceps),
    ],

    // ── LEGS — HIP DOMINANT ────────────────────────────────────────────────
    ExerciseFamily.deadlift: [
      MuscleActivation.primary(ExerciseFamily.deadlift, OntologyMuscle.hamstrings),
      MuscleActivation.primary(ExerciseFamily.deadlift, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.deadlift, OntologyMuscle.back),
      MuscleActivation.secondary(ExerciseFamily.deadlift, OntologyMuscle.traps),
      MuscleActivation.stabilizer(ExerciseFamily.deadlift, OntologyMuscle.core),
    ],
    ExerciseFamily.hipThrust: [
      MuscleActivation.primary(ExerciseFamily.hipThrust, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.hipThrust, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.hipThrust, OntologyMuscle.core),
    ],
    ExerciseFamily.legCurl: [
      MuscleActivation.primary(ExerciseFamily.legCurl, OntologyMuscle.hamstrings),
      MuscleActivation.secondary(ExerciseFamily.legCurl, OntologyMuscle.glutes),
    ],
    ExerciseFamily.gluteKickback: [
      MuscleActivation.primary(ExerciseFamily.gluteKickback, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.gluteKickback, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.gluteKickback, OntologyMuscle.core),
    ],
    ExerciseFamily.reverseHyper: [
      MuscleActivation.primary(ExerciseFamily.reverseHyper, OntologyMuscle.glutes),
      MuscleActivation.primary(ExerciseFamily.reverseHyper, OntologyMuscle.hamstrings),
      MuscleActivation.secondary(ExerciseFamily.reverseHyper, OntologyMuscle.back),
      MuscleActivation.stabilizer(ExerciseFamily.reverseHyper, OntologyMuscle.core),
    ],

    // ── LEGS — OTHER ───────────────────────────────────────────────────────
    ExerciseFamily.calfRaise: [
      MuscleActivation.primary(ExerciseFamily.calfRaise, OntologyMuscle.calves),
    ],
    ExerciseFamily.hipAdduction: [
      MuscleActivation.primary(ExerciseFamily.hipAdduction, OntologyMuscle.adductors),
      MuscleActivation.secondary(ExerciseFamily.hipAdduction, OntologyMuscle.glutes),
      MuscleActivation.stabilizer(ExerciseFamily.hipAdduction, OntologyMuscle.core),
    ],
    ExerciseFamily.hipAbduction: [
      MuscleActivation.primary(ExerciseFamily.hipAbduction, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.hipAbduction, OntologyMuscle.adductors),
      MuscleActivation.stabilizer(ExerciseFamily.hipAbduction, OntologyMuscle.core),
    ],

    // ── CORE ───────────────────────────────────────────────────────────────
    ExerciseFamily.plank: [
      MuscleActivation.primary(ExerciseFamily.plank, OntologyMuscle.core),
      MuscleActivation.primary(ExerciseFamily.plank, OntologyMuscle.abs),
      MuscleActivation.stabilizer(ExerciseFamily.plank, OntologyMuscle.anteriorDeltoid),
    ],
    ExerciseFamily.crunch: [
      MuscleActivation.primary(ExerciseFamily.crunch, OntologyMuscle.abs),
      MuscleActivation.secondary(ExerciseFamily.crunch, OntologyMuscle.core),
    ],
    ExerciseFamily.carry: [
      MuscleActivation.primary(ExerciseFamily.carry, OntologyMuscle.core),
      MuscleActivation.secondary(ExerciseFamily.carry, OntologyMuscle.traps),
      MuscleActivation.secondary(ExerciseFamily.carry, OntologyMuscle.forearms),
      MuscleActivation.stabilizer(ExerciseFamily.carry, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.carry, OntologyMuscle.medialDeltoid),
    ],
    ExerciseFamily.rotation: [
      MuscleActivation.primary(ExerciseFamily.rotation, OntologyMuscle.core),
      MuscleActivation.primary(ExerciseFamily.rotation, OntologyMuscle.abs),
      MuscleActivation.secondary(ExerciseFamily.rotation, OntologyMuscle.back),
    ],
    ExerciseFamily.mountainClimber: [
      MuscleActivation.primary(ExerciseFamily.mountainClimber, OntologyMuscle.core),
      MuscleActivation.primary(ExerciseFamily.mountainClimber, OntologyMuscle.abs),
      MuscleActivation.stabilizer(ExerciseFamily.mountainClimber, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.stabilizer(ExerciseFamily.mountainClimber, OntologyMuscle.chest),
    ],

    // ── FULL BODY / CARDIO ─────────────────────────────────────────────────
    ExerciseFamily.sled: [
      MuscleActivation.primary(ExerciseFamily.sled, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.sled, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.sled, OntologyMuscle.hamstrings),
      MuscleActivation.stabilizer(ExerciseFamily.sled, OntologyMuscle.core),
    ],
    ExerciseFamily.jump: [
      MuscleActivation.primary(ExerciseFamily.jump, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.jump, OntologyMuscle.glutes),
      MuscleActivation.secondary(ExerciseFamily.jump, OntologyMuscle.calves),
      MuscleActivation.stabilizer(ExerciseFamily.jump, OntologyMuscle.core),
    ],
    ExerciseFamily.battleRopes: [
      MuscleActivation.primary(ExerciseFamily.battleRopes, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.primary(ExerciseFamily.battleRopes, OntologyMuscle.medialDeltoid),
      MuscleActivation.secondary(ExerciseFamily.battleRopes, OntologyMuscle.back),
      MuscleActivation.stabilizer(ExerciseFamily.battleRopes, OntologyMuscle.core),
    ],
    ExerciseFamily.wallBall: [
      MuscleActivation.primary(ExerciseFamily.wallBall, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.wallBall, OntologyMuscle.anteriorDeltoid),
      MuscleActivation.primary(ExerciseFamily.wallBall, OntologyMuscle.medialDeltoid),
      MuscleActivation.secondary(ExerciseFamily.wallBall, OntologyMuscle.glutes),
      MuscleActivation.stabilizer(ExerciseFamily.wallBall, OntologyMuscle.core),
    ],
    ExerciseFamily.cardioMachine: [
      MuscleActivation.primary(ExerciseFamily.cardioMachine, OntologyMuscle.quadriceps),
      MuscleActivation.primary(ExerciseFamily.cardioMachine, OntologyMuscle.calves),
      MuscleActivation.stabilizer(ExerciseFamily.cardioMachine, OntologyMuscle.core),
    ],
    // burpee → fullBody, no family-level breakdown
    ExerciseFamily.burpee: [
      MuscleActivation.primary(ExerciseFamily.burpee, OntologyMuscle.fullBody),
    ],

    // ── MOBILITY / WARMUP ──────────────────────────────────────────────────
    // These are excluded from recovery calculation (category = mobility/warmup).
    // Listed so getActivations() never returns null for any known family.
    ExerciseFamily.shoulderMobility: [],
    ExerciseFamily.hipMobility: [],
    ExerciseFamily.spineMobility: [],
    ExerciseFamily.ankleMobility: [],
    ExerciseFamily.foamRoll: [],
    ExerciseFamily.yoga: [],
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all [MuscleActivation] facts for [exerciseFamily].
  /// Returns empty list for unknown or mobility families.
  static List<MuscleActivation> getActivations(String exerciseFamily) {
    return _activations[exerciseFamily] ?? [];
  }

  /// Returns muscles in a specific [role] for [exerciseFamily].
  static List<OntologyMuscle> getMusclesByRole(
    String exerciseFamily,
    ActivationRole role,
  ) {
    return getActivations(exerciseFamily)
        .where((a) => a.role == role)
        .map((a) => a.muscle)
        .toList();
  }

  static List<OntologyMuscle> getPrimaryMuscles(String exerciseFamily) =>
      getMusclesByRole(exerciseFamily, ActivationRole.primary);

  static List<OntologyMuscle> getSecondaryMuscles(String exerciseFamily) =>
      getMusclesByRole(exerciseFamily, ActivationRole.secondary);

  static List<OntologyMuscle> getStabilizers(String exerciseFamily) =>
      getMusclesByRole(exerciseFamily, ActivationRole.stabilizer);

  /// Returns a recovery load map: muscle → recovery weight for [exerciseFamily].
  /// When a muscle appears in multiple activations, the highest weight wins.
  static Map<OntologyMuscle, double> getRecoveryLoad(String exerciseFamily) {
    final result = <OntologyMuscle, double>{};
    for (final activation in getActivations(exerciseFamily)) {
      final existing = result[activation.muscle] ?? 0.0;
      if (activation.recoveryWeight > existing) {
        result[activation.muscle] = activation.recoveryWeight;
      }
    }
    return result;
  }

  /// Returns the fraction of primary muscles shared between two families (0.0–1.0).
  /// Used in similarity scoring.
  static double primaryMuscleOverlap(String familyA, String familyB) {
    final a = getPrimaryMuscles(familyA).toSet();
    final b = getPrimaryMuscles(familyB).toSet();
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final union = a.union(b).length;
    final intersection = a.intersection(b).length;
    return intersection / union;
  }
}
