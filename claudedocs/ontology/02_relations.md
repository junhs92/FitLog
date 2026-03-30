# FitLog Pro — Exercise Ontology: Relations & Mappings

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-30

This file is the **ground truth knowledge base** — every fact the ontology will encode.

---

## Part A: Muscle Antagonist Pairs

Antagonist pairs are **bidirectional** (if A antagonistOf B, then B antagonistOf A).

> **Note on shoulder subdivision**: `shoulders` is split into `anterior_deltoid`,
> `medial_deltoid`, and `posterior_deltoid` throughout this document.
> Each head has distinct antagonists and activation patterns.
> See `01_concepts.md` Concept 1 for rationale.

### Antagonist Pairs

| Muscle A | Muscle B (Antagonist) | Notes |
|---|---|---|
| `chest` | `back` | Horizontal push ↔ horizontal pull |
| `chest` | `lats` | Chest press ↔ pulldown/row |
| `chest` | `posterior_deltoid` | Anterior pressing ↔ rear delt pulling |
| `anterior_deltoid` | `posterior_deltoid` | Front delt ↔ rear delt (same joint, opposite vectors) |
| `anterior_deltoid` | `back` | Overhead pressing plane ↔ rowing plane |
| `medial_deltoid` | — | No strong antagonist — lateral abduction is relatively isolated |
| `biceps` | `triceps` | Elbow flexion ↔ extension |
| `quadriceps` | `hamstrings` | Knee extension ↔ flexion |
| `glutes` | `quadriceps` | Hip extension ↔ knee extension (partial) |
| `abs` | `traps` | Spinal flexion ↔ extension (partial) |
| `calves` | `quadriceps` | Plantar flexion ↔ knee drive (walking pattern) |

### Synergist Pairs

Muscles that assist each other — not antagonists, but recruited together.

| Primary | Synergist | Context |
|---|---|---|
| `chest` | `triceps` | All horizontal pressing |
| `chest` | `anterior_deltoid` | All horizontal pressing (front delt only) |
| `anterior_deltoid` | `medial_deltoid` | Overhead pressing (both heads active) |
| `anterior_deltoid` | `triceps` | All pressing movements |
| `back` | `biceps` | All pulling movements |
| `back` | `posterior_deltoid` | Row and horizontal pull movements |
| `back` | `traps` | Row and vertical pull movements |
| `lats` | `posterior_deltoid` | Pulldown and vertical pull movements |
| `glutes` | `hamstrings` | Hip hinge movements |
| `quadriceps` | `glutes` | Squat movements |
| `core` | `abs` | All stabilization |

---

## Part B: Exercise Family → Muscle Activation

Format: `family → { primary: [], secondary: [], stabilizer: [] }`

### Chest

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `bench_press` | chest | triceps, anterior_deltoid | core |
| `fly` | chest | anterior_deltoid | core |
| `pushup` | chest | triceps, anterior_deltoid | core, abs |
| `pullover` | chest, lats | triceps | core |

**Angle modifiers for bench_press / fly:**
- `flat` → standard distribution above
- `incline` → shifts +20% emphasis to upper chest, anterior_deltoid becomes co-primary
- `decline` → shifts +15% emphasis to lower chest, anterior_deltoid involvement decreases

### Shoulders

> `shoulders` is subdivided into three distinct heads. Each family targets specific heads only.

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `overhead_press` | anterior_deltoid, medial_deltoid | posterior_deltoid, triceps | core, traps |
| `lateral_raise` | medial_deltoid | — | core |
| `front_raise` | anterior_deltoid | medial_deltoid | core |
| `rear_delt` | posterior_deltoid | traps, back | core |
| `y_raise` | posterior_deltoid, medial_deltoid | traps, back | core |
| `shrug` | traps | — | forearms |
| `upright_row` | medial_deltoid, traps | anterior_deltoid, biceps | core |

**Why this matters for recovery:**
- A client who did `bench_press` (anterior_deltoid secondary) can do `lateral_raise` (medial_deltoid primary) the next day — no recovery conflict.
- A client who did `overhead_press` (anterior + medial primary) should wait before doing `lateral_raise` — medial_deltoid overlap.
- `rear_delt` and `bench_press` have zero muscle overlap — fully complementary.

### Triceps

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `tricep_extension` | triceps | — | core |
| `dip` | triceps, chest | anterior_deltoid | core |
| `jm_press` | triceps | chest | core |
| `tate_press` | triceps | chest | core |

### Back

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `row` | back, lats | biceps, traps, posterior_deltoid | core |
| `pulldown` | lats | biceps, back | posterior_deltoid, core |
| `pullup` | lats, back | biceps, posterior_deltoid | core |
| `rack_pull` | back, traps | glutes, hamstrings | core |

### Biceps / Forearms

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `curl` | biceps | forearms | core |
| `wrist_curl` | forearms | — | — |
| `grip` | forearms | biceps | — |

### Legs — Quad Dominant

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `squat` | quadriceps | glutes, hamstrings | core, adductors |
| `lunge` | quadriceps | glutes, hamstrings | core, adductors |
| `leg_extension` | quadriceps | — | — |

### Legs — Hip Dominant

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `deadlift` | hamstrings, glutes | back, traps | core |
| `hip_thrust` | glutes | hamstrings | core |
| `leg_curl` | hamstrings | glutes | — |
| `glute_kickback` | glutes | hamstrings | core |
| `reverse_hyper` | glutes, hamstrings | back | core |

### Legs — Other

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `calf_raise` | calves | — | — |
| `hip_adduction` | adductors | glutes | core |
| `hip_abduction` | glutes (lateral) | adductors | core |

### Core

> Core exercises load the anterior_deltoid as a stabilizer in front-facing positions (plank, mountain climber).
> This does NOT conflict with medial or posterior deltoid recovery.

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `plank` | core, abs | — | anterior_deltoid |
| `crunch` | abs | core | — |
| `carry` | core | traps, forearms | anterior_deltoid, medial_deltoid |
| `rotation` | core, abs | back | — |
| `mountain_climber` | core, abs | — | anterior_deltoid, chest |

### Full Body / Cardio

| Family | Primary | Secondary | Stabilizer |
|---|---|---|---|
| `sled` | quadriceps, glutes | hamstrings | core |
| `jump` | quadriceps, glutes | calves | core |
| `burpee` | fullBody | — | — |
| `battle_ropes` | anterior_deltoid, medial_deltoid | back, core | — |
| `wall_ball` | quadriceps, anterior_deltoid, medial_deltoid | glutes, core | — |
| `cardio_machine` | calves, quadriceps | core | — |

### Mobility / Warmup

> Mobility families are excluded from recovery calculation (category = mobility/warmup).
> Listed here for completeness only.

| Family | Targets | Notes |
|---|---|---|
| `foam_roll` | (targeted area) | Recovery aid, not a fatigue source |
| `yoga` | fullBody | Restorative |
| `shoulder_mobility` | anterior_deltoid, medial_deltoid, posterior_deltoid | All three heads |
| `hip_mobility` | glutes, adductors, hamstrings | — |
| `spine_mobility` | back, core | — |
| `ankle_mobility` | calves, adductors | — |

---

## Part C: Exercise Family → Movement Hierarchy

Format: `family → movementGroup → movementDetail`

| Family | MovementGroup | MovementDetail |
|---|---|---|
| `bench_press` | push | horizontal |
| `fly` | push | horizontal |
| `pushup` | push | horizontal |
| `pullover` | pull | horizontal |
| `overhead_press` | push | vertical |
| `dip` | push | vertical |
| `row` | pull | horizontal |
| `rack_pull` | pull | horizontal |
| `pulldown` | pull | vertical |
| `pullup` | pull | vertical |
| `squat` | legs | squat |
| `lunge` | legs | lunge |
| `leg_extension` | legs | squat |
| `deadlift` | legs | hinge |
| `hip_thrust` | legs | hinge |
| `leg_curl` | legs | hinge |
| `glute_kickback` | legs | hinge |
| `reverse_hyper` | legs | hinge |
| `calf_raise` | legs | — (isolation) |
| `hip_adduction` | legs | — (isolation) |
| `hip_abduction` | legs | — (isolation) |
| `lateral_raise` | push | — (isolation) |
| `front_raise` | push | — (isolation) |
| `rear_delt` | pull | — (isolation) |
| `shrug` | pull | — (isolation) |
| `curl` | pull | — (isolation) |
| `tricep_extension` | push | — (isolation) |
| `plank` | core | anti_extension |
| `carry` | core | anti_lateral_flexion |
| `crunch` | core | anti_flexion |
| `rotation` | core | rotation |
| `mountain_climber` | core | anti_extension |
| `battle_ropes` | other | — |
| `burpee` | other | — |
| `sled` | other | — |
| `jump` | legs | squat |
| `wall_ball` | other | — |
| `cardio_machine` | other | — |
| `foam_roll` | other | — |
| `yoga` | other | — |

---

## Part D: Complementary Exercise Pairs

Two exercises are **complementary** when they train antagonist muscle groups and/or opposite movement patterns. Using both in the same session creates balance.

High-value complementary pairings:

| Exercise A | Exercise B | Reason |
|---|---|---|
| `bench_press` | `row` | horizontal push ↔ horizontal pull |
| `overhead_press` | `pulldown` | vertical push ↔ vertical pull |
| `squat` | `deadlift` | quad dominant ↔ hip dominant |
| `hip_thrust` | `leg_extension` | glute/hamstring ↔ quad |
| `plank` | `crunch` | anti-extension ↔ flexion |
| `tricep_extension` | `curl` | triceps ↔ biceps |
| `lateral_raise` | `rear_delt` | anterior ↔ posterior shoulder |

---

## Part E: Base Recovery Timeline

Used as the **starting point** before RPE and volume modifiers (Part F) are applied.

Based on general exercise science guidance (not medical):

| Muscle Category | Members | Base Recovery (days) |
|---|---|---|
| Large compound | chest, back, lats, quadriceps, hamstrings, glutes | 2 |
| Mid-size | shoulders, biceps, triceps, traps | 1.5 |
| Small | forearms, calves, adductors, abs | 1 |
| Core / stabilizer | core | 1 |
| Stabilizer role only | (muscle appeared only as stabilizer in session) | 0 |

These are **baseline values at RPE 7, 3–4 working sets, isolation category**. All adjustments are in Part F.

**Final formula:**
```
recoveryDays =
  baseRecovery
  × rpeMultiplier      (Part F-1)
  × volumeMultiplier   (Part F-2)
  × categoryMultiplier (Part F-3)
  + tagBonus           (Part F-4)

result: round up to nearest 0.5, cap at 5.0 days
```

---

## Part F: RPE–Recovery Relations

`ExerciseSetEntity` tracks `rpe` (double, 0–10) and `tags` (SetTag enum) per set. This part defines how those values translate into recovery demand.

---

### F-1: RPE Recovery Multiplier

RPE is a continuous variable. A single binary threshold (≥8 = +1 day) loses precision. Use a multiplier instead:

| RPE Range | Multiplier | Interpretation |
|---|---|---|
| 1–4 | 0.5x | Sub-maximal, warmup territory — negligible mechanical fatigue |
| 5 | 0.7x | Light effort, significant reps in reserve |
| 6 | 0.85x | Moderate, comfortable, 4+ reps in reserve |
| 7 | 1.0x | Standard working set — **baseline** (3 reps in reserve) |
| 8 | 1.3x | Hard, 2 reps in reserve |
| 9 | 1.6x | Near-maximal, 1 rep in reserve |
| 10 | 2.0x | True failure — maximum mechanical damage |

**Which RPE value to use:** Use **peak RPE** (highest single set) for a given muscle per session, not average. The hardest set determines recovery ceiling — averaging underestimates it.

---

### F-2: Volume Multiplier

RPE compounds across sets. High RPE sustained for 8 sets causes far more fatigue than the same RPE for 2 sets.

Count only **working sets** (exclude `warmup`-tagged sets).

| Working Sets per Muscle | Multiplier |
|---|---|
| 1–2 | 0.75x |
| 3–4 | 1.0x (baseline) |
| 5–6 | 1.3x |
| 7–9 | 1.6x |
| 10+ | 2.0x |

> When one muscle appears as primary across multiple exercises in the same session (e.g., bench_press + fly + pushup all hit chest), sum the working sets across all of them.

---

### F-3: Exercise Category Multiplier

Compound movements at the same RPE produce greater total fatigue than isolation movements because of higher CNS demand, more muscle mass involved, and greater mechanical loading through stretch.

| `ExerciseCategory` | Multiplier | Reason |
|---|---|---|
| `compound` | 1.2x | Multi-joint, high CNS demand, large mechanical stress |
| `isolation` | 1.0x | Baseline — single joint, lower systemic fatigue |
| `cardio` | 0.6x | Different fatigue type — cardiovascular, not mechanical damage |
| `mobility` | 0.3x | Low load, restorative — may actually aid recovery |
| `warmup` / `cooldown` | 0.0x | Not counted in recovery demand |

---

### F-4: Set Tag Modifiers

`SetTag` values on `ExerciseSetEntity` carry fatigue information beyond RPE. Applied as **additive bonuses** to `recoveryDays` after the multipliers.

| SetTag | Bonus (days) | Reason |
|---|---|---|
| `failureSet` | +0.5 | True failure causes more myofibrillar damage than RPE 10 alone captures |
| `dropSet` | +0.3 | Extended time under tension after mechanical failure |
| `fatigue` | +0.2 | Client self-reported fatigue — subjective confirmation of high load |
| `pain` | ALERT | Do not compute recovery — flag for trainer review; may indicate injury |
| `goodCondition` | −0.2 (floor: 0) | Client in peak state — faster recovery expected |
| `warmup` | Exclude from calculation | Not a working set |
| `pr` | 0 | PR sets are at high RPE already — RPE captures the effect |
| `formIssue` | +0.1 | Compensatory movement patterns increase fatigue in stabilizers |

> If multiple tags apply to the same set, sum the bonuses. Cap total tag bonus at +1.0 days.

---

### F-5: Aggregating Set-Level RPE to Muscle-Level

`ExerciseSetEntity.rpe` is recorded per set. The ontology needs muscle-level recovery demand.

**Aggregation rules:**

1. Collect all sets from exercises where `MuscleGroup` appears as **primary** activation
2. Exclude sets tagged `warmup`
3. For each set: if `rpe` is null, apply the **null RPE defaults** (F-6)
4. Take **peak RPE** across all collected sets → use for F-1 multiplier
5. Count total working sets → use for F-2 multiplier
6. Apply F-3 using the `category` of the exercise that produced the peak RPE set
7. Sum F-4 tag bonuses across all sets (cap at +1.0)
8. Compute: `recoveryDays = base × rpeMultiplier × volumeMultiplier × categoryMultiplier + tagBonus`

> Secondary muscle activations use a reduced calculation:
> `secondaryRecoveryDays = primaryRecoveryDays × 0.5`

> Stabilizer activations: 0 days (not computed — stabilizer fatigue is captured in the primary muscle of that exercise).

---

### F-6: Null RPE Defaults

Many sets will not have RPE recorded. Rather than discarding them, assume:

| Condition | Assumed RPE |
|---|---|
| Set tagged `warmup` | 5.0 (excluded anyway) |
| Set tagged `failureSet` | 10.0 |
| Set tagged `fatigue` | 8.5 |
| Set tagged `goodCondition` | 6.5 |
| First set of an exercise (setNumber = 1) | 7.0 |
| Later sets (setNumber ≥ 3) | 7.5 |
| General fallback | 7.0 |

---

### F-7: RPE Trend Signals (Dynamic Layer)

These are **cross-session patterns** computed from RPE history. Used to trigger deload, progression, or trainer alerts. These feed into the dynamic layer of the ontology — they are not per-session calculations.

| Pattern | Signal | Threshold | Action |
|---|---|---|---|
| Same weight, RPE rising | Accumulated fatigue / overreaching | RPE increased ≥ 1.0 over 2 consecutive sessions | Reduce volume 20%, consider deload week |
| Same weight, RPE falling | Adaptation — ready to progress | RPE decreased ≥ 1.0 over 3 consecutive sessions | Increase load or volume next session |
| RPE consistently low | Undertraining | Avg RPE < 6 for 3+ sessions on same muscle | Increase intensity target |
| RPE consistently at ceiling | Overreaching | Avg RPE ≥ 9 for 3+ sessions | Mandatory deload |
| `failureSet` tag recurring | Excessive intensity | Appears in 3+ consecutive sessions | Reduce RPE targets, program adjustment |
| `pain` tag recurring | Injury risk | Same muscle, 2+ consecutive sessions | Alert trainer immediately, avoid muscle |
| `fatigue` tag recurring | Systemic fatigue | Appears across multiple muscle groups in same session | Check sleep/lifestyle logs |

---

### F-8: Complete Recovery Calculation Example

**Scenario:** Client did bench_press (compound) with these sets:
```
Set 1: weight=80kg, reps=8, rpe=7,   tags=[]
Set 2: weight=80kg, reps=8, rpe=8,   tags=[]
Set 3: weight=80kg, reps=6, rpe=9,   tags=[fatigue]
Set 4: weight=70kg, reps=8, rpe=10,  tags=[failureSet, dropSet]
```

**Step 1 — Collect working sets for chest (primary):** All 4 sets (none tagged warmup)

**Step 2 — Peak RPE:** 10 (Set 4) → multiplier = 2.0

**Step 3 — Working set count:** 4 → multiplier = 1.0

**Step 4 — Category:** compound → multiplier = 1.2

**Step 5 — Tag bonuses:** fatigue(+0.2) + failureSet(+0.5) + dropSet(+0.3) = +1.0 (at cap)

**Step 6 — Base recovery (chest = large compound):** 2.0 days

**Calculation:**
```
recoveryDays = 2.0 × 2.0 × 1.0 × 1.2 + 1.0 = 5.8 → capped at 5.0 days
```

Chest needs **5 days recovery** before being loaded as primary again.

**Secondary muscles (triceps, shoulders):**
```
secondaryRecovery = 5.0 × 0.5 = 2.5 days
```
