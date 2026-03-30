# FitLog Pro — Exercise Ontology: Implementation Plan

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-29

---

## Phase Overview

```
Phase 1 — Core data types         (ontology_triple.dart)
Phase 2 — Muscle relations        (muscle_ontology.dart)
Phase 3 — Exercise activation     (exercise_ontology.dart)
Phase 4 — Movement hierarchy      (movement_ontology.dart)
Phase 5 — OntologyService API     (ontology_service.dart)
Phase 6 — Wire into existing code
```

Each phase is self-contained and testable. Do not start Phase N+1 until Phase N compiles cleanly.

---

## Phase 1 — Core Data Types

**File**: `lib/core/ontology/ontology_triple.dart`

**What to build:**
- `enum OntologyRelation` — all relation types
- `class OntologyTriple` — a single fact (subject, relation, object)
- `class MuscleActivation` — exercise family + muscle + role + recovery weight

**Key design decisions:**
- Use `String` for subject/object (not typed enums) to keep the triple store flexible
- `MuscleActivation.recoveryWeight` is a `double` (0.0–1.0), defaulted by role
- No external dependencies — pure Dart

**Checklist:**
- [ ] `enum OntologyRelation` with values: `worksAsPrimary, worksAsSecondary, worksAsStabilizer, antagonistOf, synergistOf, complementaryTo, belongsToMovementDetail, belongsToMovementGroup, requiresEquipment`
- [ ] `class OntologyTriple { String subject; OntologyRelation relation; String object; }`
- [ ] `enum ActivationRole { primary, secondary, stabilizer }`
- [ ] `class MuscleActivation { String exerciseFamily; MuscleGroup muscle; ActivationRole role; double recoveryWeight; }`
- [ ] Default `recoveryWeight` by role: primary=1.0, secondary=0.5, stabilizer=0.15
- [ ] Unit test: create a few triples, verify equality

---

## Phase 2 — Muscle Relations

**File**: `lib/core/ontology/muscle_ontology.dart`

**What to build:**
A static map encoding all muscle↔muscle relations from `02_relations.md` Part A.

**Key design decisions:**
- Store as `Map<MuscleGroup, List<MuscleGroup>> _antagonists` (bidirectional — both directions stored)
- Store as `Map<MuscleGroup, List<MuscleGroup>> _synergists`
- All data is `const` — initialized at compile time, no runtime cost

**Public API surface:**
```dart
class MuscleOntology {
  static List<MuscleGroup> antagonistsOf(MuscleGroup muscle);
  static List<MuscleGroup> synergistsOf(MuscleGroup muscle);
  static bool areAntagonists(MuscleGroup a, MuscleGroup b);
  static List<MuscleGroup> getRecoveryConflicts(List<MuscleGroup> muscles);
  // → returns muscles that would conflict if trained same day
}
```

**Checklist:**
- [ ] Define `_antagonists` map from `02_relations.md` Part A
- [ ] Define `_synergists` map from `02_relations.md` Part A (synergist section)
- [ ] Implement `antagonistsOf()` — returns list, empty if none
- [ ] Implement `areAntagonists()` — uses antagonistsOf both ways
- [ ] Implement `getRecoveryConflicts()` — used by AI generator to avoid overloading
- [ ] Unit tests: chest antagonist → back, lats; biceps antagonist → triceps

---

## Phase 3 — Exercise Activation

**File**: `lib/core/ontology/exercise_ontology.dart`

**What to build:**
Static maps of exercise family → muscle activations (from `02_relations.md` Part B).

**Key design decisions:**
- Key is `String` matching `ExerciseFamily` constants (e.g., `'bench_press'`)
- Value is `List<MuscleActivation>`
- Every family in `ExerciseFamily` class must have an entry (or explicit `[]` if unknown)
- Mobility/warmup families (foam_roll, yoga) can have empty or minimal activation data

**Public API surface:**
```dart
class ExerciseOntology {
  static List<MuscleActivation> getActivations(String exerciseFamily);
  static List<MuscleGroup> getPrimaryMuscles(String exerciseFamily);
  static List<MuscleGroup> getSecondaryMuscles(String exerciseFamily);
  static List<MuscleGroup> getStabilizers(String exerciseFamily);
  static Map<MuscleGroup, double> getRecoveryLoad(String exerciseFamily);
  // → Map of muscle → recovery weight
}
```

**Checklist:**
- [ ] Define `_activationMap` for all families in ExerciseFamily (from Part B of 02_relations.md)
- [ ] Implement `getActivations()` — returns list, empty if family unknown
- [ ] Implement `getPrimaryMuscles()` — filter by role
- [ ] Implement `getRecoveryLoad()` — aggregate by muscle (take max if muscle appears multiple times)
- [ ] Implement `getSecondaryMuscles()` and `getStabilizers()`
- [ ] Unit tests: bench_press primary=chest; deadlift primary=hamstrings,glutes; curl primary=biceps
- [ ] Confirm all 50 ExerciseFamily constants have entries (no silent misses)

---

## Phase 4 — Movement Hierarchy

**File**: `lib/core/ontology/movement_ontology.dart`

**What to build:**
Static lookup from exercise family → movementGroup + movementDetail (from `02_relations.md` Part C).
Also encodes complementary exercise pairs (Part D).

**Key design decisions:**
- Movement hierarchy is already partially encoded in `ExerciseEntity` fields, but the ontology provides a canonical source that doesn't depend on DB data
- Complementary pairs are `Set<Set<String>>` (unordered pairs for bidirectionality)

**Public API surface:**
```dart
class MovementOntology {
  static String? getMovementGroup(String exerciseFamily);
  static String? getMovementDetail(String exerciseFamily);
  static List<String> getComplementaryFamilies(String exerciseFamily);
  static bool areComplementary(String family1, String family2);
  static List<String> getFamiliesByMovementDetail(String movementDetail);
  static double muscleSimilarityScore(String family1, String family2);
  // → 0.0 = identical, 1.0 = completely different
}
```

**`muscleSimilarityScore` formula** (see `01_concepts.md` Concept 7):
```
score =
  0.40 * primaryMuscleOverlapFraction +
  0.25 * (movementDetail matches ? 0 : 1) +
  0.20 * (movementGroup matches ? 0 : 1) +
  0.15 * equipmentOverlapFraction
```
Lower score = more similar. Used for substitution and variety enforcement.

**Checklist:**
- [ ] Define `_movementMap` mapping family → (group, detail) from Part C
- [ ] Define `_complementaryPairs` from Part D
- [ ] Implement `getMovementGroup()` and `getMovementDetail()`
- [ ] Implement `getComplementaryFamilies()` and `areComplementary()`
- [ ] Implement `getFamiliesByMovementDetail()` — inverse lookup
- [ ] Implement `muscleSimilarityScore()` — uses ExerciseOntology for muscle overlap
- [ ] Unit tests: bench_press complementary → row; squat complementary → deadlift

---

## Phase 5 — OntologyService

**File**: `lib/core/ontology/ontology_service.dart`

**What to build:**
A facade that composes MuscleOntology, ExerciseOntology, and MovementOntology into a single high-level query API. This is what the rest of the app consumes.

**Key design decisions:**
- Stateless (no Riverpod provider needed — it's just static logic)
- All inputs use existing types: `ExerciseEntity`, `MuscleGroup`, `String` (family name)
- Returns are domain-meaningful (not raw triples)
- Registered as a Riverpod `Provider<OntologyService>` for DI compatibility

**Public API surface:**
```dart
class OntologyService {
  // Muscle queries
  List<MuscleGroup> getAntagonists(MuscleGroup muscle);
  bool areAntagonists(MuscleGroup a, MuscleGroup b);

  // Exercise → muscle
  List<MuscleGroup> getPrimaryMuscles(ExerciseEntity exercise);
  Map<MuscleGroup, double> getRecoveryLoad(ExerciseEntity exercise);

  // Exercise → exercise
  bool areComplementary(ExerciseEntity ex1, ExerciseEntity ex2);
  double muscleSimilarity(ExerciseEntity ex1, ExerciseEntity ex2);
  List<ExerciseFamily> getSimilarFamilies(ExerciseEntity exercise, {double maxScore = 0.4});

  // Session-level queries
  bool isSessionBalanced(List<ExerciseEntity> exercises);
  // → true if push:pull ratio is within 0.5–2.0
  Map<MuscleGroup, double> getSessionRecoveryLoad(List<ExerciseEntity> exercises);
  List<MuscleGroup> getOverloadedMuscles(List<ExerciseEntity> exercises);
  // → muscles with total recovery load > threshold (default 2.0)

  // Recovery queries
  double computeRecoveryDays(
    MuscleGroup muscle,
    List<ExerciseSetEntity> sets,   // all sets from session where muscle was primary
    String exerciseCategory,         // ExerciseCategory constant
  );
  // → applies Part F formula: base × rpeMultiplier × volumeMultiplier × categoryMultiplier + tagBonus

  bool isRecovered(MuscleGroup muscle, DateTime lastWorkedAt, double requiredRecoveryDays);
  // → DateTime.now().difference(lastWorkedAt).inHours >= requiredRecoveryDays * 24

  List<MuscleGroup> getUnrecoveredMuscles(
    Map<MuscleGroup, DateTime> lastWorkedDates,
    Map<MuscleGroup, double> recoveryDaysByMuscle,  // pre-computed via computeRecoveryDays
  );
}
```

**Checklist:**
- [ ] Implement all methods above
- [ ] Add `final ontologyServiceProvider = Provider((ref) => OntologyService())`
- [ ] `isSessionBalanced()` — counts push vs pull exercises, checks ratio
- [ ] `isRecovered()` — uses recovery heuristics from `02_relations.md` Part E
- [ ] Unit tests for each public method
- [ ] Integration test: given a list of 5 exercises (bench + row + squat + deadlift + curl), session is balanced

---

## Phase 6 — Wire Into Existing Code

**This phase modifies existing files — read each file carefully before editing.**

### 6a. ExerciseRecommendationService

**File**: `lib/features/active_session/domain/services/exercise_recommendation_service.dart`

**Changes:**
- Inject `OntologyService` via constructor
- Replace group-level muscle conflict detection with `ontologyService.getRecoveryLoad()`
- Use `ontologyService.areComplementary()` to improve complementary suggestions
- Use `ontologyService.muscleSimilarity()` to improve supplementary suggestions
- Add a new method: `getOntologyExplanation(ExerciseEntity exercise)` → returns a human-readable string explaining why the exercise was recommended

### 6b. AI Workout Generation context

**File**: `lib/features/ai_workout/` (locate the Supabase edge function caller or prompt builder)

**Changes:**
- When building AI context, include ontology-derived data:
  - `unrecoveredMuscles` from `OntologyService.getUnrecoveredMuscles()`
  - `sessionBalance` from recent sessions
- This reduces reliance on the AI to figure out recovery — we provide it as structured input

### 6c. Muscle Map

**File**: `lib/features/muscle_map/`

**Changes:**
- Use `ExerciseOntology.getRecoveryLoad()` to calculate per-muscle load from logged sessions
- Currently uses `MuscleGroup` list — can now show weighted activation levels
- Optional: show antagonist pairs visually highlighted

---

## Testing Strategy

Each phase has unit tests. Recommended test file locations:

```
test/
└── core/
    └── ontology/
        ├── muscle_ontology_test.dart
        ├── exercise_ontology_test.dart
        ├── movement_ontology_test.dart
        └── ontology_service_test.dart
```

**Critical test cases to verify:**
1. All 50 ExerciseFamily constants return non-null from ExerciseOntology
2. All MuscleGroup enum values appear in at least one activation entry
3. Antagonist relation is symmetric: if A antagonistOf B, then B antagonistOf A
4. `muscleSimilarityScore(bench_press, bench_press) == 0.0`
5. `muscleSimilarityScore(bench_press, deadlift) > 0.7`
6. `isSessionBalanced([bench, overhead_press, row, pulldown]) == true`
7. `isSessionBalanced([bench, overhead_press, dip, tricep_extension]) == false`

---

## Dependency Map

```
ontology_triple.dart          ← no deps
muscle_ontology.dart          ← depends on: muscle_group.dart (MuscleGroup enum)
exercise_ontology.dart        ← depends on: ontology_triple.dart, muscle_ontology.dart
movement_ontology.dart        ← depends on: exercise_ontology.dart, exercise_entity.dart
ontology_service.dart         ← depends on: all three above
recommendation_service.dart   ← depends on: ontology_service.dart (inject)
```

Build order must follow this dependency chain.
