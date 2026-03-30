# FitLog Pro — Exercise Ontology: Overview

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-29
**Goal**: Add a formal ontology layer to the exercise domain so the app can reason about muscle relationships, movement patterns, and exercise complementarity — rather than relying on ad-hoc heuristics.

---

## Why Ontology?

### Current state (proto-taxonomy)
The app already classifies exercises through several flat layers:

```
ExerciseEntity
  .category         → compound | isolation | cardio | mobility | warmup | cooldown
  .movementGroup    → push | pull | legs | core | other
  .movementDetail   → horizontal | vertical | squat | hinge | lunge | anti_* | rotation
  .family           → bench_press | squat | deadlift | curl | ...  (~50 families)
  .angle            → flat | incline | decline | high | low | neutral | na
  .gripOrientation  → overhand | underhand | neutral | mixed | rotating | na
  .muscleGroup      → (primary, string)
  .secondaryMuscles → (list of strings)
```

`MuscleGroup` enum has 16 values with `isFrontView` and `isUpperBody` booleans only.

### The gap
These are **classification labels**, not **relationships**. The system knows that bench_press is a `horizontal push` and works `chest`, but it cannot answer:
- "What muscles are antagonist to chest?"
- "Does bench_press + overhead_press overload any shared stabilizer?"
- "Is incline_dumbbell_press semantically close to cable_fly?"
- "If a client did heavy squats, what leg exercises should be avoided tomorrow?"

### What ontology adds
Formal, typed, bidirectional relationships that enable **inference**:

| Capability | Before | After |
|---|---|---|
| Antagonist pairing | Hardcoded rules in AI prompt | `MuscleGroup.chest.antagonists` |
| Muscle overlap between exercises | Not computed | `ontology.muscleSimilarity(ex1, ex2)` |
| Session balance check | Manual AI judgement | `ontology.isSessionBalanced(exercises)` |
| Exercise substitution | Same family only | Semantic similarity via ontological distance |
| Recovery awareness | Days-since heuristic | Specific muscle group fatigue inference |
| AI workout reasoning | Black-box prompt | Explainable ontological constraints |

---

## Scope of This Work

**In scope:**
- Muscle relationship ontology (antagonist, synergist, stabilizer)
- Exercise-to-muscle activation ontology (primary, secondary, stabilizer roles)
- Movement pattern hierarchy (family → movementDetail → movementGroup)
- An `OntologyService` that wraps this knowledge and exposes queries
- Integration hooks into `ExerciseRecommendationService`

**Out of scope (future):**
- Storing ontology in Supabase DB (start in-code, migrate later if needed)
- OWL/RDF serialization
- Ontology UI for trainers to extend
- Joint/biomechanical relationships (insertion points, fiber direction)

---

## Where This Lives in the Codebase

```
lib/
└── core/
    └── ontology/                         ← NEW directory
        ├── muscle_ontology.dart          ← Muscle group relationships
        ├── exercise_ontology.dart        ← Exercise → muscle activation facts
        ├── movement_ontology.dart        ← Movement pattern hierarchy
        ├── ontology_service.dart         ← Query interface (the public API)
        └── ontology_triple.dart          ← Data types (relation types + triples)
```

These are **pure Dart, no external dependencies** — static data + logic only.

The `OntologyService` is consumed by:
- `lib/features/active_session/domain/services/exercise_recommendation_service.dart`
- `lib/features/ai_workout/` (AI workout generation context)
- `lib/features/muscle_map/` (activation level display)

---

## Document Index

| File | Contents |
|---|---|
| `00_overview.md` | This file — motivation, scope, directory plan |
| `01_concepts.md` | Formal definition of all ontological concepts |
| `02_relations.md` | All relation types with complete muscle/exercise mappings |
| `03_implementation_plan.md` | Phase-by-phase coding plan with file names and task checklist |
| `04_integration_points.md` | Exactly where existing code changes to use the ontology |
