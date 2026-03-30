# FitLog Pro — Trainer-Client Compatibility Ontology

**Status**: Design phase (pre-implementation)
**Last updated**: 2026-03-29

---

## Purpose

This ontology models the **social, psychological, and aspirational dynamics** between trainers and clients that drive:
- Initial registration (why a client chooses a specific trainer)
- Session attendance (showing up consistently)
- Package renewal (recurrence)
- Long-term retention

This is distinct from the exercise ontology — it has nothing to do with biomechanics. It models **human compatibility** as a formal knowledge structure.

---

## Current State (What the App Captures Today)

### Trainer — `UserEntity`
```
id, email, name, role, phone, profilePhotoUrl, createdAt, lastLoginAt
```
**Missing**: specialization, coaching style, body composition archetype, experience, background story, philosophy.

### Client — `ClientEntity`
```
id, trainerId, name, email, phone, dateOfBirth, gender,
height, weight, goals (List<String>), notes, profilePhotoUrl
```
**Missing**: motivation type, psychological readiness, fitness experience level, lifestyle context, health constraints, preferred training style, goal horizon.

### Registration — `RegisterScreen`
Captures: name, email, password, role only.
Trainer requires a hardcoded verification code.

**The core problem**: Neither entity currently has enough semantic attributes to compute compatibility. `goals` is an unstructured string list with no formal meaning.

---

## Semantic Layer — "What types exist"

### Trainer Profile Dimensions

#### 1. Body Composition Archetype
What the trainer's physical appearance communicates to prospective clients.

| Value | Description |
|---|---|
| `lean_athletic` | Lean, defined musculature — communicates fat loss + tone |
| `muscular_bulk` | Large, high muscle mass — communicates mass building |
| `fit_average` | Healthy, active appearance — communicates general fitness |
| `transformed` | Visibly underwent significant body change — communicates relatability |
| `athletic_performance` | Sport-specific build — communicates performance training |

> This is not a judgement of the trainer's worth — it is a signal clients use when selecting a trainer. Different archetypes attract different client goals.

#### 2. Specialization
Primary area of training expertise.

| Value | Korean | Description |
|---|---|---|
| `strength` | 근력 | Powerlifting, strength sports |
| `physique` | 피지크/보디빌딩 | Bodybuilding, aesthetics |
| `weight_loss` | 체중 감량 | Fat loss, metabolic conditioning |
| `rehabilitation` | 재활 | Injury recovery, corrective exercise |
| `athletic_performance` | 운동 능력 향상 | Sports-specific training |
| `general_fitness` | 전반적 체력 | Broad wellness, beginners |
| `mobility_flexibility` | 유연성/모빌리티 | Movement quality, yoga-adjacent |

A trainer can have 1–2 specializations (primary + secondary).

#### 3. Coaching Style
How the trainer delivers instruction and motivation.

| Value | Korean | Traits |
|---|---|---|
| `motivational` | 동기부여형 | High energy, encouragement-focused, emotionally engaging |
| `technical` | 기술형 | Detail-oriented, form-correction-heavy, analytical |
| `nurturing` | 지지형 | Empathetic, patient, emotionally safe environment |
| `challenging` | 도전형 | Pushes limits, high expectations, intensity-focused |
| `educational` | 교육형 | Explains the why, knowledge-sharing, empowers autonomy |

#### 4. Background Story Type
The trainer's personal origin — shapes client identification.

| Value | Description |
|---|---|
| `competitive_athlete` | Former competitive sports background |
| `personal_transformation` | Underwent significant body/health transformation themselves |
| `medical_professional` | Physio, nurse, doctor background |
| `lifelong_fitness` | Always been active, no dramatic transformation story |
| `late_starter` | Came to fitness later in life |

#### 5. Experience Level

| Value | Years | Meaning |
|---|---|---|
| `emerging` | 0–2y | Building client base, lower price point |
| `established` | 2–5y | Proven track record, moderate pricing |
| `expert` | 5y+ | Deep expertise, premium positioning |

---

### Client Profile Dimensions

#### 1. Body Composition Archetype
Mirrors trainer archetype — used for aspirational gap calculation.

| Value | Description |
|---|---|
| `lean` | Already lean, seeking tone/performance |
| `average` | Moderate body fat, general improvement goals |
| `overweight` | Above average body fat, weight loss primary driver |
| `obese` | Significant weight to lose, often first-time exerciser |
| `underweight` | Seeking mass/strength gain |
| `athletic` | Already fit, seeking performance gains |
| `post_rehabilitation` | Recovering from injury or medical event |

#### 2. Primary Motivation Type
What fundamentally drives the client to exercise.

| Value | Korean | Description |
|---|---|---|
| `aesthetic` | 외모/체형 | Looks, body composition, appearance |
| `health` | 건강 | Medical, longevity, energy levels |
| `performance` | 퍼포먼스 | Sport, strength, athletic output |
| `social` | 사교 | Community, accountability, fun |
| `mental_wellbeing` | 정신 건강 | Stress relief, mood, confidence |
| `competitive` | 경쟁 | Contests, comparisons, rankings |

#### 3. Psychological Readiness Stage
Where the client is in their behavior change journey (Transtheoretical Model).

| Stage | Description | Training Implication |
|---|---|---|
| `pre_contemplation` | Not yet thinking about change | Education-first approach, no hard programming |
| `contemplation` | Aware, not yet committed | Low-barrier entry, motivation focus |
| `preparation` | Ready to start, planning | Structure, clear goals, early wins |
| `action` | Actively training (0–6 months) | Progressive programming, habit building |
| `maintenance` | Consistent 6+ months | Challenge progression, variety, autonomy |
| `relapse` | Was consistent, lapsed | Re-engagement, barrier removal |

This is the most important dynamic variable — it changes as the client progresses, and trainer behavior must adapt to it.

#### 4. Fitness Experience Level

| Value | Description |
|---|---|
| `complete_beginner` | Never trained consistently |
| `recreational` | Occasional gym-goer, no structured programming |
| `intermediate` | 1–3 years of consistent training |
| `advanced` | 3+ years, understands progressive overload |
| `athlete` | Sport-specific training background |

#### 5. Goal Horizon

| Value | Description |
|---|---|
| `event_driven` | Wedding, vacation, competition — specific deadline |
| `short_term` | 1–3 month goals, quick results focus |
| `long_term` | Lifestyle change, 6+ month perspective |
| `open_ended` | No specific timeline, general wellness |

#### 6. Lifestyle Context (new — not in current entity)

| Field | Values | Training Impact |
|---|---|---|
| `occupation_activity` | sedentary, light_active, moderate_active, highly_active | Affects volume tolerance and recovery |
| `stress_level` | low, moderate, high, variable | Affects session intensity caps |
| `sleep_quality` | good, average, poor | Affects recovery; feeds into lifestyle ontology |
| `schedule_flexibility` | fixed, semi_flexible, flexible | Affects session frequency options |

---

## Kinetic Layer — "How they relate"

### Compatibility Dimension 1: Aspirational Identification

The degree to which a client sees the trainer as embodiment of their goal state.

**Formula:**
```
aspirational_score = f(
  body_archetype_gap,       // trainer has what client wants
  gender_match,             // same gender → higher identification
  background_story_match    // trainer overcame similar starting point
)
```

**Body archetype gap matrix** (client archetype → trainer archetype → score):

| Client | Target Trainer Archetype | Score |
|---|---|---|
| `overweight` | `lean_athletic` or `transformed` | HIGH (0.8–1.0) |
| `overweight` | `muscular_bulk` | MODERATE (0.5) |
| `underweight` | `muscular_bulk` or `lean_athletic` | HIGH |
| `average` | `lean_athletic` or `athletic_performance` | HIGH |
| `athletic` | `athletic_performance` or `muscular_bulk` | HIGH |
| `post_rehabilitation` | trainer with `rehabilitation` specialization | CRITICAL |

**Gender matching effect:**
- Same gender → +0.15 to aspirational score (comfort, identification, privacy comfort)
- Opposite gender → neutral (not negative — can be positive in some motivation types)

**Background story matching:**
- Client `overweight` + trainer with `personal_transformation` story → +0.20 (relatability bonus)
- Client `athlete` + trainer with `competitive_athlete` story → +0.15

---

### Compatibility Dimension 2: Goal-Specialization Alignment

How well the trainer's specialization addresses the client's stated goals.

| Client Goal | Best Trainer Specialization | Moderate Match | Poor Match |
|---|---|---|---|
| Weight loss | `weight_loss`, `general_fitness` | `physique`, `athletic_performance` | `strength` |
| Muscle building | `physique`, `strength` | `general_fitness`, `athletic_performance` | `rehabilitation` |
| Strength gains | `strength`, `athletic_performance` | `physique` | `weight_loss` |
| General fitness | `general_fitness` | anything | — |
| Rehabilitation | `rehabilitation` | `general_fitness` | `strength`, `physique` |
| Sport performance | `athletic_performance` | `strength` | `weight_loss` |

---

### Compatibility Dimension 3: Coaching Style × Motivation Type

| Client Motivation | Best Coaching Style | Acceptable | Risky |
|---|---|---|---|
| `aesthetic` | `motivational`, `nurturing` | `educational` | `challenging` (too intense) |
| `health` | `educational`, `nurturing` | `motivational` | `challenging` |
| `performance` | `technical`, `challenging` | `educational` | `nurturing` (too soft) |
| `social` | `motivational`, `nurturing` | any | `technical` (too cold) |
| `mental_wellbeing` | `nurturing`, `motivational` | `educational` | `challenging` |
| `competitive` | `challenging`, `technical` | `motivational` | `nurturing` |

---

### Compatibility Dimension 4: Readiness Stage × Coaching Style

| Readiness Stage | Appropriate Style | Risk if Mismatched |
|---|---|---|
| `pre_contemplation` | `educational`, `nurturing` | `challenging` → immediate dropout |
| `contemplation` | `motivational`, `nurturing` | `technical` → overwhelm |
| `preparation` | `motivational`, `educational` | — |
| `action` | `technical`, `challenging` | `nurturing` → stagnation |
| `maintenance` | `educational`, `challenging` | `motivational` (patronizing) |
| `relapse` | `nurturing`, `motivational` | `challenging` → guilt spiral |

---

### Compatibility Dimension 5: Experience Level × Trainer Experience

| Client Level | Trainer Match | Notes |
|---|---|---|
| `complete_beginner` | Any — but `general_fitness` specialization preferred | Beginners don't need elite trainers, they need patient ones |
| `recreational` | `emerging` or `established` | Good match for emerging trainers building portfolio |
| `intermediate` | `established` or `expert` | Needs structured programming knowledge |
| `advanced` | `expert` | Demands technical depth; emerging trainers may lose credibility |
| `athlete` | `expert` with `athletic_performance` | Non-negotiable domain match |

---

## Overall Compatibility Score

```
CompatibilityScore = (
  0.30 × aspirational_identification  +
  0.25 × goal_specialization_alignment +
  0.25 × coaching_style_compatibility  +
  0.10 × readiness_stage_alignment     +
  0.10 × experience_level_match
)
```

Score ranges:
- 0.8–1.0 → High compatibility → Strong registration and retention signal
- 0.6–0.8 → Moderate compatibility → Good match, standard retention
- 0.4–0.6 → Borderline → Some friction expected; monitor retention
- 0.0–0.4 → Low compatibility → High churn risk; flag for intervention

---

## Dynamic Layer — "How it changes over time"

### Registration Probability
Computed at the moment a client is browsing or being matched to a trainer.

```
P(register) ∝ compatibility_score × trainer_visibility_score
```

`trainer_visibility_score` = profile completeness + photo quality + review count (future feature).

### Recurrence Model

Recurrence (package renewal probability) is updated after each completed session:

```
P(renew) = f(
  compatibility_score,          // static baseline
  result_attribution,           // does client credit trainer for their progress?
  session_satisfaction_trend,   // RPE tags, completion rate, mood post-session
  relationship_duration,        // longer = higher switching cost
  trainer_consistency           // did trainer show up, prepared, on time?
)
```

**Key insight from your example:**
> female client (overweight) + female trainer (lean athletic) → HIGH recurrence

This is driven by aspirational_identification (score ~0.85) + gender match bonus. Even if results are slow initially, the aspirational pull keeps the client coming back because the trainer *is* the goal state made visible.

### Churn Risk Signals

| Signal | Churn Indicator | Suggested Action |
|---|---|---|
| Cancellation rate increases > 2 sessions in a row | MODERATE risk | Trainer reaches out, check-in |
| Client readiness stage = `relapse` | HIGH risk | Reduce intensity, focus on re-engagement |
| Compatibility score < 0.4 (computed retrospectively) | HIGH risk | Consider trainer reassignment |
| 0 lifestyle logs for 2+ weeks | MODERATE risk | Engagement nudge |
| Session RPE consistently below target | LOW risk (sandbagging) | Coaching style recalibration |
| Session RPE consistently > 9 | MODERATE risk (burnout) | Volume reduction, recovery week |
| No PR or measurable progress for 4+ weeks | HIGH risk | Program refresh, goal conversation |

### Relationship Phase Model

The trainer-client relationship evolves through phases, each requiring different behavior:

```
Phase 1: Onboarding (sessions 1–4)
  → Priority: trust building, early wins, habit formation
  → Compatibility matters most: nurturing/motivational style dominant
  → Risk: overwhelming the client with too much too fast

Phase 2: Development (sessions 5–20)
  → Priority: progressive programming, measurable results
  → Compatibility: technical competence becomes visible
  → Risk: plateau → client questions trainer's expertise

Phase 3: Consolidation (sessions 21–50)
  → Priority: autonomy development, advanced programming
  → Compatibility: relationship depth; client should feel understood
  → Risk: complacency on both sides; over-familiarity

Phase 4: Long-term Partnership (50+ sessions)
  → Priority: goal evolution, new challenges, lifestyle integration
  → Compatibility: peer-level dynamic; coach becomes advisor
  → Risk: client feels they've outgrown the trainer
```

---

## Data Gaps — What Needs to Be Added

The following fields are **not currently captured** but are required to compute compatibility.

### TrainerProfile (extend `UserEntity` or create `TrainerProfileEntity`)

| New Field | Type | Captured When |
|---|---|---|
| `bodyCompositionArchetype` | `TrainerBodyArchetype` enum | Trainer profile setup |
| `specializations` | `List<TrainerSpecialization>` | Trainer profile setup |
| `coachingStyle` | `CoachingStyle` enum | Trainer profile setup |
| `backgroundStoryType` | `TrainerBackground` enum | Optional — trainer profile |
| `experienceYears` | `int` | Trainer profile setup |

### ClientProfile (extend `ClientEntity`)

| New Field | Type | Captured When |
|---|---|---|
| `motivationType` | `ClientMotivationType` enum | Client onboarding intake |
| `readinessStage` | `PsychologicalReadiness` enum | Client onboarding intake (updates over time) |
| `fitnessExperienceLevel` | `FitnessExperience` enum | Client onboarding intake |
| `goalHorizon` | `GoalHorizon` enum | Client onboarding intake |
| `occupationActivity` | `OccupationActivity` enum | Client onboarding intake |
| `bodyCompositionArchetype` | `ClientBodyArchetype` enum | Derived from height/weight/goal, or asked directly |

### Relationship (new `TrainerClientRelationship` entity or extend connection)

| New Field | Type | Captured When |
|---|---|---|
| `compatibilityScore` | `double` | Computed at connection time |
| `currentRelationshipPhase` | `RelationshipPhase` enum | Computed from session count |
| `churnRiskLevel` | `ChurnRisk` enum | Computed continuously |
| `lastCheckinAt` | `DateTime` | Trainer action |

---

## Integration Points

### Affects These Existing Features

| Feature | How Compatibility Ontology Connects |
|---|---|
| **Client Registration / Add Client** | Collect new semantic fields (motivation type, readiness, experience) |
| **Trainer Profile** | Add archetype, specialization, coaching style fields |
| **Client Management dashboard** | Show compatibility score + relationship phase per client |
| **AI Workout Generation** | Use readiness stage + motivation type to modulate session intensity and style |
| **AI Session Report** | Tailor language and tone to coaching style + motivation type |
| **Session Scheduling** | Flag churn risk clients for proactive trainer outreach |
| **Package Renewal** | Surface renewal prompts at high compatibility + good result moments |

### New Features This Enables

| Feature | Description |
|---|---|
| **Trainer-Client Matching** | When client registers, rank available trainers by compatibility score |
| **Retention Dashboard** | Trainer sees all clients ranked by churn risk level |
| **Relationship Health Score** | Composite metric: compatibility + progress + engagement |
| **Readiness Stage Tracker** | Trainer marks when client advances stages; program adapts |

---

## Open Questions Before Implementation

1. **Trainer profile setup UX**: When and how does a trainer fill in their archetype and coaching style? Post-registration onboarding flow? Or during first login?

2. **Client intake timing**: Are the new client fields collected when the trainer creates the client (AddClientScreen), or in a separate onboarding questionnaire the client fills themselves?

3. **Body composition archetype derivation**: Can `bodyCompositionArchetype` be inferred from existing `height + weight` (BMI proxy) rather than asking directly? This avoids a sensitive question at registration.

4. **Compatibility score storage**: Computed at connection time and stored, or recomputed on each access? (Recommend: store + recalculate periodically as profile data updates.)

5. **Privacy boundary**: Compatibility score based on trainer physique — is this something trainers see ("clients who match my profile"), or only used internally by the recommendation system?
