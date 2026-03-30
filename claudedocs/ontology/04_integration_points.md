# FitLog Pro — Exercise Ontology: Integration Points

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-29

This document maps exactly which existing files change and how, so future sessions can resume without re-reading the whole codebase.

---

## Existing Files That Change

### 1. ExerciseRecommendationService
**Path**: `lib/features/active_session/domain/services/exercise_recommendation_service.dart`
**Change type**: Enhancement (new dependency injected)

**Current behavior**: Uses group-level heuristics (movementGroup, family matching) for complementary/supplementary suggestions. Recovery awareness is limited to days-since logic on `MuscleGroupHistoryEntry`.

**After ontology**:
- Constructor receives `OntologyService`
- `getComplementaryExercises()` → uses `ontologyService.areComplementary()` instead of family-level heuristics
- `getSupplementaryExercises()` → uses `ontologyService.muscleSimilarity()` to find medium-distance exercises
- New method: `getSessionBalance(List<ExerciseEntity> current)` → calls `ontologyService.isSessionBalanced()`
- Recovery awareness improved: uses `ontologyService.getUnrecoveredMuscles()` instead of just `MuscleGroupHistoryEntry.workedAt`

**Backward compatibility**: All existing public methods retain their signatures. Ontology is additive — it improves results without breaking callers.

---

### 2. AI Workout Edge Function Context Builder
**Path**: Find via `grep -r 'edge_function\|supabase.functions' lib/features/ai_workout/`
**Change type**: Data enrichment (add ontology-derived fields to AI context payload)

**Current behavior**: Sends to AI: trainingSplit, muscleGroupHistory, consistencyScore, lastSessionFocus, client goals.

**After ontology**:
- Add `unrecovered_muscles: []` — list of muscles not yet recovered (from OntologyService)
- Add `session_balance_score: 0.0-1.0` — how balanced recent sessions were
- Add `overloaded_muscles: []` — muscles that got excessive volume lately

This gives the AI structured recovery context instead of asking it to infer from raw history.

---

### 3. MuscleMap Presentation Layer
**Path**: `lib/features/muscle_map/`
**Change type**: Data enhancement (richer activation data)

**Current behavior**: Displays which `MuscleGroup` values were worked, binary (worked / not worked).

**After ontology**:
- Uses `ExerciseOntology.getRecoveryLoad(exerciseFamily)` to compute weighted activation
- Displays activation intensity (primary=full color, secondary=lighter, stabilizer=faint)
- Shows antagonist pairs when a muscle is tapped (e.g., tap chest → highlight back as antagonist)

**Note**: This is Phase 6c and is lower priority. The muscle map changes are UI-level only — no domain logic changes needed.

---

## New Files Created

All new files go in `lib/core/ontology/`. See `03_implementation_plan.md` for full details.

| File | Status |
|---|---|
| `lib/core/ontology/ontology_triple.dart` | Not started |
| `lib/core/ontology/muscle_ontology.dart` | Not started |
| `lib/core/ontology/exercise_ontology.dart` | Not started |
| `lib/core/ontology/movement_ontology.dart` | Not started |
| `lib/core/ontology/ontology_service.dart` | Not started |

---

## Existing Files That Do NOT Change

These files are read by the ontology but never modified:

| File | Role |
|---|---|
| `lib/features/muscle_map/domain/entities/muscle_group.dart` | `MuscleGroup` enum — ontology imports this |
| `lib/features/active_session/domain/entities/exercise_entity.dart` | `ExerciseFamily`, `MovementGroup`, etc. — ontology references these constants |
| `lib/features/ai_workout/domain/entities/workout_program.dart` | `TrainingSplit`, `TrainingGoal` — read by ontology service for recovery inference |

---

## Riverpod Provider Registration

Add the ontology service provider to the DI graph:

**File to create or add to**: `lib/core/ontology/ontology_service.dart` (at bottom of file)

```dart
// At the bottom of ontology_service.dart
final ontologyServiceProvider = Provider<OntologyService>((ref) {
  return OntologyService();
});
```

Then in `ExerciseRecommendationService`'s Riverpod provider (wherever it is registered):
```dart
// Inject ontologyServiceProvider
final exerciseRecommendationServiceProvider = Provider((ref) {
  final ontologyService = ref.watch(ontologyServiceProvider);
  return ExerciseRecommendationService(ontologyService: ontologyService);
});
```

---

## Questions to Resolve Before Phase 6

These need answers before modifying existing files (do not guess):

1. **ExerciseRecommendationService provider registration**: Where is this service registered as a Riverpod provider? Search: `grep -r 'ExerciseRecommendationService' lib/`

2. **AI prompt builder location**: Where is the Supabase edge function payload assembled? Search: `grep -r 'generate_session\|ai_workout' lib/features/ai_workout/data/`

3. **MuscleMap data source**: Does the muscle map read from completed sessions or from a separate muscle activity table? Check: `lib/features/muscle_map/data/`

4. **ExerciseEntity.family vs ExerciseFamily constant**: Are all `exercise.family` values guaranteed to match `ExerciseFamily` constants, or can they be arbitrary strings (including from custom exercises)? If custom exercises can have arbitrary families, `ExerciseOntology` needs a null-safe fallback.
