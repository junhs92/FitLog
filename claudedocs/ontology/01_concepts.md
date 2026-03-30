# FitLog Pro — Exercise Ontology: Concepts

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-30

---

## Core Ontological Concepts

An ontology is built from **concepts** (things that exist in the domain) and **relations** (how they connect). Below are all concepts used in this ontology.

---

## Concept 1: MuscleNode

A named muscle group that can participate in relations.

The existing `MuscleGroup` enum in Dart has 16 values:
```
chest, back, shoulders, biceps, triceps, forearms,
quadriceps, hamstrings, glutes, calves, adductors,
core, abs, lats, traps, fullBody
```

**The ontology extends this with one critical subdivision: `shoulders`.**

### Shoulder Subdivision

`shoulders` as a single node is too coarse for meaningful ontological reasoning.
The deltoid has three anatomically and functionally distinct heads with different
activation patterns, different antagonists, and different exercise families.

| Ontology Node | Anatomical Name | Activated By |
|---|---|---|
| `anterior_deltoid` | Front deltoid head | Pressing movements, front raises |
| `medial_deltoid` | Middle / lateral deltoid head | Lateral raises, overhead press |
| `posterior_deltoid` | Rear deltoid head | Rear delt flies, rows, face pulls |

**Why this matters for the ontology:**
- `bench_press` works `anterior_deltoid` as secondary — NOT medial or posterior
- `lateral_raise` works `medial_deltoid` exclusively — not the other two heads
- `row` works `posterior_deltoid` as secondary — not anterior or medial
- The antagonist of `chest` in pressing is `posterior_deltoid` (rear delt), not all of shoulders
- Recovery from `lateral_raise` does not conflict with recovery from `bench_press`

**Mapping to existing Dart `MuscleGroup` enum:**
The three ontology nodes all map to `MuscleGroup.shoulders` for display purposes.
The subdivision only exists within the ontology layer — existing UI and queries are unaffected.

```
anterior_deltoid  ┐
medial_deltoid    ├── all display as MuscleGroup.shoulders in the app UI
posterior_deltoid ┘
```

**All other muscles remain as single nodes** matching the existing enum directly.

---

### Functional Sub-groupings

Logical groupings used in antagonist pairing and session balance checks:

| Group | Members |
|---|---|
| Upper Push | chest, anterior_deltoid, medial_deltoid, triceps |
| Upper Pull | back, lats, posterior_deltoid, biceps, traps |
| Anterior Chain | chest, anterior_deltoid, quadriceps, abs |
| Posterior Chain | back, lats, posterior_deltoid, hamstrings, glutes, traps |
| Pressing Synergists | chest, anterior_deltoid, triceps |
| Pulling Synergists | back, lats, posterior_deltoid, biceps |
| Core Stabilizers | core, abs |
| Leg Extensors | quadriceps |
| Leg Flexors | hamstrings |

These sub-groupings inform antagonist pairings (see `02_relations.md`).

---

## Concept 2: MovementConcept

A named movement pattern in the biomechanical hierarchy.

### Hierarchy (top → bottom)

```
MovementGroup (existing)
  push
    horizontal_push   ← MovementDetail
    vertical_push
  pull
    horizontal_pull
    vertical_pull
  legs
    squat
    hinge
    lunge
  core
    anti_extension
    anti_flexion
    anti_lateral_flexion
    rotation
  other
    (no sub-details)

ExerciseFamily (existing, ~50 families)
  ← belongs under a MovementDetail
  e.g. bench_press ← horizontal_push ← push
       deadlift    ← hinge            ← legs
       curl        ← (none/isolation) ← pull
```

**Note**: Some families (curl, lateral_raise) are isolation exercises that don't map cleanly to a MovementDetail. They are classified under their MovementGroup only.

---

## Concept 3: ExerciseConcept

An individual exercise, represented by its `ExerciseFamily` (not individual exercise ID), because ontological facts apply at the family level — bench_press facts are true for all bench_press variants.

When individual exercise-level precision is needed, the `angle` and `gripOrientation` fields refine the family.

**Key distinction:**
- `bench_press` family → works chest (primary), anterior deltoid (secondary), triceps (secondary)
- `incline_bench_press` (family=bench_press, angle=incline) → shifts emphasis toward upper chest and anterior deltoid

Ontology facts are defined at **family** level. Angle and grip modifiers can shift muscle emphasis but do not change which muscles are involved.

---

## Concept 4: ActivationRole

How a muscle participates in an exercise:

| Role | Description | Example |
|---|---|---|
| `primary` | Main mover; the muscle the exercise is primarily designed to train | chest in bench_press |
| `secondary` | Significantly involved but not the primary target | triceps in bench_press |
| `stabilizer` | Holds position / prevents unwanted movement | core in bench_press |

**Rules for assignment:**
- An exercise has 1–3 primary muscles
- Secondary muscles receive ~30–60% of the primary stimulus
- Stabilizers are engaged isometrically; they fatigue but don't hypertrophy like primary/secondary
- Recovery impact: primary > secondary >> stabilizer

---

## Concept 5: OntologyRelation

A typed directed edge between two concepts.

Full list defined in `02_relations.md`. Summary:

| Relation | From → To | Example |
|---|---|---|
| `worksAsPrimary` | ExerciseFamily → MuscleNode | bench_press → chest |
| `worksAsSecondary` | ExerciseFamily → MuscleNode | bench_press → triceps |
| `worksAsStabilizer` | ExerciseFamily → MuscleNode | bench_press → core |
| `antagonistOf` | MuscleNode ↔ MuscleNode | chest ↔ back |
| `synergistOf` | MuscleNode → MuscleNode | biceps → brachialis (not modeled at MuscleGroup level) |
| `belongsToFamily` | ExerciseFamily → MovementConcept | bench_press → horizontal_push |
| `isVariationOf` | ExerciseFamily → ExerciseFamily | incline_press isVariationOf bench_press (angle modifier only) |
| `complementaryTo` | ExerciseFamily ↔ ExerciseFamily | bench_press ↔ row (push/pull pairing) |
| `requiresEquipment` | ExerciseFamily → Equipment | bench_press → barbell|dumbbell |

---

## Concept 6: RecoveryWeight

A numeric value (0.0–1.0) expressing how much a muscle is taxed by an exercise, used for recovery inference.

| ActivationRole | Default RecoveryWeight |
|---|---|
| primary | 1.0 |
| secondary | 0.5 |
| stabilizer | 0.15 |

Used in: `OntologyService.getRecoveryLoad(exerciseFamily)` → returns `Map<MuscleGroup, double>`

**Example:**
```
bench_press recovery load:
  chest       → 1.0
  triceps     → 0.5
  shoulders   → 0.5
  core        → 0.15
```

This enables the AI workout generator to reason: "chest received 1.0 load 2 days ago — still recovering."

---

## Concept 7: OntologicalDistance

A computed similarity score between two exercises (0.0 = identical, 1.0 = completely different).

Formula (weighted):
```
distance =
  0.40 * musclePrimaryOverlap(ex1, ex2)  +
  0.25 * movementDetailMatch(ex1, ex2)   +
  0.20 * movementGroupMatch(ex1, ex2)    +
  0.15 * equipmentOverlap(ex1, ex2)
```

Used for:
- Exercise substitution: find exercises with low distance (similar)
- Session variety: avoid exercises with very low distance in same session
- Recommendation: suggest exercises with medium distance (complementary, not redundant)
