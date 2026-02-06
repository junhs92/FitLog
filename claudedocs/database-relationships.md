# Database Relationships Documentation

## Entity Relationship Diagram

```
┌─────────────────┐
│    accounts     │
│ (trainer/client)│
└────────┬────────┘
         │
         │ 1:N
         ▼
┌─────────────────────────────────────┐
│     trainer_client_relationships    │
│         (many-to-many link)         │
└─────────────────────────────────────┘
         │
         │ Enables
         ▼
┌─────────────────┐       ┌──────────────────┐
│ workout_programs│◀──────│     sessions     │
│   (directions)  │  1:N  │ (actual workouts)│
└────────┬────────┘       └────────┬─────────┘
         │                         │
         │ Referenced              │ 1:N
         │                         ▼
         │                ┌──────────────────┐
         │                │ session_exercises│
         │                │ (junction table) │
         │                └────────┬─────────┘
         │                         │
         │                         │ N:1
         │                         ▼
         │                ┌──────────────────┐
         └───────────────▶│    exercises     │
                          │   (library)      │
                          └──────────────────┘
```

---

## Table Relationships

### 1. accounts → sessions (1:N)

```sql
-- A trainer has many sessions
sessions.trainer_id → accounts.id

-- A client has many sessions
sessions.client_id → accounts.id
```

**Usage in code:**
```dart
// Get all sessions for a trainer
await supabase.from('sessions')
  .select('*, accounts!sessions_client_id_fkey(full_name)')
  .eq('trainer_id', trainerId);
```

### 2. workout_programs → sessions (1:N)

```sql
sessions.program_id → workout_programs.id
```

**Purpose:** Links a session to its training direction (program).

**Usage:**
```dart
// Create session linked to program
await supabase.from('sessions').insert({
  'program_id': programId,
  'client_id': clientId,
  ...
});
```

### 3. sessions → session_exercises (1:N)

```sql
session_exercises.session_id → sessions.id
```

**Purpose:** Each session has multiple exercises.

**Usage:**
```dart
// Fetch session with exercises
await supabase.from('sessions')
  .select('''
    *,
    session_exercises(*, exercises(*))
  ''')
  .eq('id', sessionId);
```

### 4. exercises → session_exercises (1:N)

```sql
session_exercises.exercise_id → exercises.id
```

**Purpose:** Links session exercises to the exercise library.

---

## Key Constraints

### Foreign Key Constraints

| Source Table | Column | Target Table | Column |
|--------------|--------|--------------|--------|
| sessions | trainer_id | accounts | id |
| sessions | client_id | accounts | id |
| sessions | program_id | workout_programs | id |
| session_exercises | session_id | sessions | id |
| session_exercises | exercise_id | exercises | id |
| workout_programs | client_id | accounts | id |
| workout_programs | trainer_id | accounts | id |

### Check Constraints

```sql
-- sessions.status must be one of:
CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'))

-- exercises.category must be one of:
CHECK (category IN ('compound', 'isolation', 'cardio', 'mobility', 'warmup', 'cooldown'))

-- exercises.movement_pattern must be one of:
CHECK (movement_pattern IN ('squat', 'hinge', 'horizontal_push', 'horizontal_pull',
                             'vertical_push', 'vertical_pull', 'carry', 'rotation',
                             'isolation', 'cardio'))
```

---

## Data Flow Patterns

### Pattern 1: AI Session Creation

```
1. Edge Function reads:
   - accounts (client profile)
   - workout_programs (training direction)
   - sessions (recent history)
   - session_exercises (exercise history)
   - exercises (library)

2. Edge Function writes:
   - sessions (new row, status='scheduled')
   - sessions.ai_recommended_exercises (JSONB - original exercise list)
   - sessions.ai_reasoning (text - AI explanations)

3. Client activates session:
   - session_exercises (created from user's final exercise list)
   - sessions.status → 'active'
```

### Pattern 2: Session Recording

```
1. Trainer logs set:
   - session_exercises.sets (JSONB array updated)

2. Trainer completes exercise:
   - session_exercises.completed_at (timestamp set)

3. Session completed:
   - sessions.status → 'completed'
   - sessions.completed_at (timestamp set)
   - sessions.total_exercises, total_sets, etc. (calculated)
```

---

## JSONB / Text Columns

### sessions.ai_recommended_exercises (JSONB)

Stores the **original exercise list** recommended by AI before user modifications.

```json
[
  {
    "exerciseId": "uuid",
    "exerciseName": "Barbell Squat",
    "bodyCategory": "lower_body",
    "exerciseType": "compound",
    "orderIndex": 0,
    "targetSets": 4,
    "targetReps": "8-12",
    "targetRpe": 7,
    "restSeconds": 90
  },
  {
    "exerciseId": "uuid",
    "exerciseName": "Bench Press",
    "bodyCategory": "upper_body",
    "exerciseType": "compound",
    "orderIndex": 1,
    "targetSets": 4,
    "targetReps": "8-12",
    "targetRpe": 7,
    "restSeconds": 90
  }
]
```

### sessions.ai_reasoning (text - JSON string)

Stores **AI's explanations** for WHY each exercise was selected.

```json
{
  "sessionName": "Full Body Strength",
  "sessionDescription": "Balanced workout targeting major muscle groups",
  "generatedAt": "2025-12-23T10:30:00Z",
  "exerciseReasonings": [
    {
      "exerciseId": "uuid",
      "exerciseName": "Barbell Squat",
      "aiReasoning": {
        "reasons": [
          {
            "category": "goal_alignment",
            "explanation": "Compound movement for hypertrophy",
            "explanationKo": "근비대를 위한 복합 운동"
          }
        ],
        "historyConsideration": "Client did leg press last session, switching to squat for variety"
      }
    }
  ]
}
```

### session_exercises.sets

```json
[
  {
    "id": "set_1703311800000",
    "session_exercise_id": "uuid",
    "set_number": 1,
    "weight": 60.0,
    "reps": 10,
    "rpe": 7,
    "duration_seconds": null,
    "distance": null,
    "tags": ["warmup"],
    "notes": null,
    "completed_at": "2025-12-23T10:35:00Z"
  },
  {
    "id": "set_1703311900000",
    "session_exercise_id": "uuid",
    "set_number": 2,
    "weight": 70.0,
    "reps": 8,
    "rpe": 8,
    "completed_at": "2025-12-23T10:38:00Z"
  }
]
```

### session_exercises.notes

```json
{
  "targetSets": 4,
  "targetReps": "8-12",
  "targetRpe": 7,
  "restSeconds": 90,
  "aiReasoning": "Selected for progressive overload based on client history"
}
```

### workout_programs.muscle_group_history

```json
[
  { "muscleGroup": "upper_body", "date": "2025-12-23" },
  { "muscleGroup": "lower_body", "date": "2025-12-23" },
  { "muscleGroup": "core", "date": "2025-12-23" },
  { "muscleGroup": "upper_body", "date": "2025-12-21" }
]
```

---

## RLS Policies

All tables have Row Level Security enabled:

### sessions

```sql
-- Trainers can see sessions they created
CREATE POLICY "Trainers can view own sessions"
ON sessions FOR SELECT
USING (trainer_id = auth.uid());

-- Clients can see sessions where they are the client
CREATE POLICY "Clients can view own sessions"
ON sessions FOR SELECT
USING (client_id = auth.uid());
```

### session_exercises

```sql
-- Access through session relationship
CREATE POLICY "Users can view session exercises"
ON session_exercises FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM sessions
    WHERE sessions.id = session_exercises.session_id
    AND (sessions.trainer_id = auth.uid() OR sessions.client_id = auth.uid())
  )
);
```

---

## Query Patterns

### Get Session with Full Details

```dart
final response = await supabase.from('sessions').select('''
  *,
  accounts!sessions_client_id_fkey(full_name),
  session_exercises(
    *,
    exercises(*)
  )
''').eq('id', sessionId).single();
```

### Get Recent Sessions with Exercise History

```dart
final response = await supabase.from('sessions').select('''
  id,
  focus_area,
  completed_at,
  session_exercises(
    exercise_id,
    exercises(name, name_ko, category, movement_pattern, muscle_group)
  )
''')
.eq('client_id', clientId)
.eq('status', 'completed')
.order('completed_at', ascending: false)
.limit(5);
```

### Get Active Program for Client

```dart
final response = await supabase.from('workout_programs')
  .select()
  .eq('client_id', clientId)
  .eq('status', 'active')
  .maybeSingle();
```
