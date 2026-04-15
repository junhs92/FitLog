import 'ontology_triple.dart';

/// Static muscle relationship knowledge base.
///
/// Encodes antagonist and synergist pairs between [OntologyMuscle] nodes.
/// All data sourced from 02_relations.md Part A.
class MuscleOntology {
  MuscleOntology._();

  // ---------------------------------------------------------------------------
  // Antagonist pairs — bidirectional
  // If A antagonistOf B, then B antagonistOf A.
  // Stored as directed pairs; lookup handles both directions.
  // ---------------------------------------------------------------------------

  static const List<(OntologyMuscle, OntologyMuscle)> _antagonistPairs = [
    (OntologyMuscle.chest, OntologyMuscle.back),
    (OntologyMuscle.chest, OntologyMuscle.lats),
    (OntologyMuscle.chest, OntologyMuscle.posteriorDeltoid),
    (OntologyMuscle.anteriorDeltoid, OntologyMuscle.posteriorDeltoid),
    (OntologyMuscle.anteriorDeltoid, OntologyMuscle.back),
    (OntologyMuscle.biceps, OntologyMuscle.triceps),
    (OntologyMuscle.quadriceps, OntologyMuscle.hamstrings),
    (OntologyMuscle.glutes, OntologyMuscle.quadriceps),
    (OntologyMuscle.abs, OntologyMuscle.traps),
    (OntologyMuscle.calves, OntologyMuscle.quadriceps),
  ];

  // ---------------------------------------------------------------------------
  // Synergist pairs — directional (primary assists synergist)
  // ---------------------------------------------------------------------------

  static const List<(OntologyMuscle, OntologyMuscle)> _synergistPairs = [
    (OntologyMuscle.chest, OntologyMuscle.triceps),
    (OntologyMuscle.chest, OntologyMuscle.anteriorDeltoid),
    (OntologyMuscle.anteriorDeltoid, OntologyMuscle.medialDeltoid),
    (OntologyMuscle.anteriorDeltoid, OntologyMuscle.triceps),
    (OntologyMuscle.back, OntologyMuscle.biceps),
    (OntologyMuscle.back, OntologyMuscle.posteriorDeltoid),
    (OntologyMuscle.back, OntologyMuscle.traps),
    (OntologyMuscle.lats, OntologyMuscle.posteriorDeltoid),
    (OntologyMuscle.glutes, OntologyMuscle.hamstrings),
    (OntologyMuscle.quadriceps, OntologyMuscle.glutes),
    (OntologyMuscle.core, OntologyMuscle.abs),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all muscles that are antagonists of [muscle].
  /// Bidirectional — checks both sides of every pair.
  static List<OntologyMuscle> antagonistsOf(OntologyMuscle muscle) {
    final result = <OntologyMuscle>[];
    for (final pair in _antagonistPairs) {
      if (pair.$1 == muscle) result.add(pair.$2);
      if (pair.$2 == muscle) result.add(pair.$1);
    }
    return result;
  }

  /// Returns all muscles that are synergists of [muscle].
  /// Checks both directions since synergism is mutual in practice.
  static List<OntologyMuscle> synergistsOf(OntologyMuscle muscle) {
    final result = <OntologyMuscle>[];
    for (final pair in _synergistPairs) {
      if (pair.$1 == muscle) result.add(pair.$2);
      if (pair.$2 == muscle) result.add(pair.$1);
    }
    return result;
  }

  /// Returns true if [a] and [b] are antagonists.
  static bool areAntagonists(OntologyMuscle a, OntologyMuscle b) {
    return antagonistsOf(a).contains(b);
  }

  /// Returns true if [a] and [b] are synergists.
  static bool areSynergists(OntologyMuscle a, OntologyMuscle b) {
    return synergistsOf(a).contains(b);
  }

  /// Given a list of muscles being trained, returns any muscles that would
  /// create a recovery conflict if also trained (i.e. their antagonists).
  ///
  /// Used by AI workout generator to avoid overloading antagonist pairs
  /// in the same session beyond intended balance.
  static List<OntologyMuscle> getRecoveryConflicts(
    List<OntologyMuscle> muscles,
  ) {
    final conflicts = <OntologyMuscle>{};
    for (final muscle in muscles) {
      for (final antagonist in antagonistsOf(muscle)) {
        if (!muscles.contains(antagonist)) {
          conflicts.add(antagonist);
        }
      }
    }
    return conflicts.toList();
  }

  /// Returns the base recovery days for a given muscle node.
  /// Source: 02_relations.md Part E.
  static double baseRecoveryDays(OntologyMuscle muscle) {
    switch (muscle) {
      // Large compound muscles
      case OntologyMuscle.chest:
      case OntologyMuscle.back:
      case OntologyMuscle.lats:
      case OntologyMuscle.quadriceps:
      case OntologyMuscle.hamstrings:
      case OntologyMuscle.glutes:
        return 2.0;

      // Mid-size muscles
      case OntologyMuscle.anteriorDeltoid:
      case OntologyMuscle.medialDeltoid:
      case OntologyMuscle.posteriorDeltoid:
      case OntologyMuscle.traps:
      case OntologyMuscle.biceps:
      case OntologyMuscle.triceps:
        return 1.5;

      // Small / fast-recovery muscles
      case OntologyMuscle.forearms:
      case OntologyMuscle.calves:
      case OntologyMuscle.adductors:
      case OntologyMuscle.abs:
        return 1.0;

      // Core — used daily, recovers quickly
      case OntologyMuscle.core:
        return 1.0;

      // Full body — use large compound value
      case OntologyMuscle.fullBody:
        return 2.0;
    }
  }
}
