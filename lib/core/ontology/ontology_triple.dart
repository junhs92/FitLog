import '../../features/muscle_map/domain/entities/muscle_group.dart';

/// All muscle nodes used in the ontology.
///
/// More granular than [MuscleGroup] — the deltoid is split into three heads
/// because each has distinct activation patterns, antagonists, and recovery.
/// All three still display as [MuscleGroup.shoulders] in the UI.
enum OntologyMuscle {
  chest,
  back,
  lats,
  traps,
  anteriorDeltoid, // front delt — pressing movements, front raises
  medialDeltoid, // lateral delt — lateral raises, overhead press
  posteriorDeltoid, // rear delt — rows, face pulls, rear delt flies
  biceps,
  triceps,
  forearms,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  adductors,
  core,
  abs,
  fullBody;

  /// Convert to display-level [MuscleGroup].
  /// All three deltoid heads map to [MuscleGroup.shoulders].
  MuscleGroup toMuscleGroup() {
    switch (this) {
      case OntologyMuscle.chest:
        return MuscleGroup.chest;
      case OntologyMuscle.back:
        return MuscleGroup.back;
      case OntologyMuscle.lats:
        return MuscleGroup.lats;
      case OntologyMuscle.traps:
        return MuscleGroup.traps;
      case OntologyMuscle.anteriorDeltoid:
      case OntologyMuscle.medialDeltoid:
      case OntologyMuscle.posteriorDeltoid:
        return MuscleGroup.shoulders;
      case OntologyMuscle.biceps:
        return MuscleGroup.biceps;
      case OntologyMuscle.triceps:
        return MuscleGroup.triceps;
      case OntologyMuscle.forearms:
        return MuscleGroup.forearms;
      case OntologyMuscle.quadriceps:
        return MuscleGroup.quadriceps;
      case OntologyMuscle.hamstrings:
        return MuscleGroup.hamstrings;
      case OntologyMuscle.glutes:
        return MuscleGroup.glutes;
      case OntologyMuscle.calves:
        return MuscleGroup.calves;
      case OntologyMuscle.adductors:
        return MuscleGroup.adductors;
      case OntologyMuscle.core:
        return MuscleGroup.core;
      case OntologyMuscle.abs:
        return MuscleGroup.abs;
      case OntologyMuscle.fullBody:
        return MuscleGroup.fullBody;
    }
  }

  /// Returns all OntologyMuscle nodes that map to a given [MuscleGroup].
  /// For [MuscleGroup.shoulders], returns all three deltoid heads.
  static List<OntologyMuscle> fromMuscleGroup(MuscleGroup group) {
    if (group == MuscleGroup.shoulders) {
      return [
        OntologyMuscle.anteriorDeltoid,
        OntologyMuscle.medialDeltoid,
        OntologyMuscle.posteriorDeltoid,
      ];
    }
    return OntologyMuscle.values
        .where((m) => !m.isDeltoidHead && m.toMuscleGroup() == group)
        .toList();
  }

  bool get isDeltoidHead =>
      this == OntologyMuscle.anteriorDeltoid ||
      this == OntologyMuscle.medialDeltoid ||
      this == OntologyMuscle.posteriorDeltoid;

  String get displayName {
    switch (this) {
      case OntologyMuscle.anteriorDeltoid:
        return 'Anterior Deltoid';
      case OntologyMuscle.medialDeltoid:
        return 'Medial Deltoid';
      case OntologyMuscle.posteriorDeltoid:
        return 'Posterior Deltoid';
      default:
        return toMuscleGroup().displayName;
    }
  }

  String get displayNameKo {
    switch (this) {
      case OntologyMuscle.anteriorDeltoid:
        return '전면 삼각근';
      case OntologyMuscle.medialDeltoid:
        return '측면 삼각근';
      case OntologyMuscle.posteriorDeltoid:
        return '후면 삼각근';
      default:
        return toMuscleGroup().displayNameKo;
    }
  }
}

/// How a muscle participates in an exercise.
enum ActivationRole {
  primary,
  secondary,
  stabilizer;

  /// Default recovery weight for this role (0.0–1.0).
  double get defaultRecoveryWeight {
    switch (this) {
      case ActivationRole.primary:
        return 1.0;
      case ActivationRole.secondary:
        return 0.5;
      case ActivationRole.stabilizer:
        return 0.15;
    }
  }
}

/// Typed relation between two ontological concepts.
enum OntologyRelation {
  worksAsPrimary,
  worksAsSecondary,
  worksAsStabilizer,
  antagonistOf,
  synergistOf,
  complementaryTo,
  belongsToMovementDetail,
  belongsToMovementGroup,
}

/// A single muscle activation fact for an exercise family.
///
/// Use the named constructors [MuscleActivation.primary],
/// [MuscleActivation.secondary], [MuscleActivation.stabilizer]
/// for clean static data declarations.
class MuscleActivation {
  final String exerciseFamily;
  final OntologyMuscle muscle;
  final ActivationRole role;
  final double recoveryWeight;

  const MuscleActivation({
    required this.exerciseFamily,
    required this.muscle,
    required this.role,
    required this.recoveryWeight,
  });

  const MuscleActivation.primary(this.exerciseFamily, this.muscle)
      : role = ActivationRole.primary,
        recoveryWeight = 1.0;

  const MuscleActivation.secondary(this.exerciseFamily, this.muscle)
      : role = ActivationRole.secondary,
        recoveryWeight = 0.5;

  const MuscleActivation.stabilizer(this.exerciseFamily, this.muscle)
      : role = ActivationRole.stabilizer,
        recoveryWeight = 0.15;
}

/// A generic ontological triple: subject → relation → object.
/// Used for string-keyed facts (e.g. family → movement hierarchy).
class OntologyTriple {
  final String subject;
  final OntologyRelation relation;
  final String object;

  const OntologyTriple(this.subject, this.relation, this.object);
}
