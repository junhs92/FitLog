# Session Flow Documentation

## Overview

This document describes the complete flow of workout sessions, from creation to completion, including:
1. Pre-session flow (client details + lifestyle summary)
2. AI-generated workout sessions
3. Copy previous session flow
4. Set logging and data storage

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATABASE TABLES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐       │
│  │    accounts     │     │workout_programs │     │   exercises     │       │
│  │  (users/clients)│     │(training plans) │     │   (library)     │       │
│  └────────┬────────┘     └────────┬────────┘     └────────┬────────┘       │
│           │                       │                       │                 │
│           │ trainer_id            │ program_id            │ exercise_id     │
│           │ client_id             │                       │                 │
│           ▼                       ▼                       ▼                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                           sessions                                  │    │
│  │  - id, trainer_id, client_id, program_id                           │    │
│  │  - status: 'scheduled' → 'active' → 'completed'                    │    │
│  │  - ai_recommended_exercises (JSONB) - original AI list             │    │
│  │  - ai_reasoning (text) - AI explanations                           │    │
│  └────────────────────────────────┬───────────────────────────────────┘    │
│                                   │                                         │
│                                   │ session_id                              │
│                                   ▼                                         │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                      session_exercises                              │    │
│  │  - id, session_id, exercise_id, order_index                        │    │
│  │  - target_sets (int), target_reps (text), target_weight (numeric)  │    │
│  │  - target_rpe (int), rest_seconds (int)                            │    │
│  │  - notes (aiReasoning only)                                        │    │
│  └────────────────────────────────┬───────────────────────────────────┘    │
│                                   │                                         │
│                                   │ session_exercise_id                     │
│                                   ▼                                         │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                        set_records                                  │    │
│  │  - id, session_exercise_id, set_number                             │    │
│  │  - weight, reps, rpe, duration_seconds, distance                   │    │
│  │  - tags (TEXT[]), pr_type, notes                                   │    │
│  │  - completed_at, created_at, updated_at                            │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Table Details

### 1. `sessions` (Primary session table)

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID REFERENCES accounts(id),
    client_id UUID REFERENCES accounts(id),
    program_id UUID REFERENCES workout_programs(id),
    session_type TEXT,
    status TEXT DEFAULT 'scheduled', -- 'scheduled' → 'active' → 'completed'
    focus_area TEXT,
    days_since_last INTEGER,
    ai_recommended_exercises JSONB, -- Original AI exercise list (before modifications)
    ai_reasoning TEXT,              -- AI explanations for exercise selection
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    -- Summary stats (populated on completion)
    total_exercises INTEGER,
    total_sets INTEGER,
    total_volume NUMERIC,
    avg_reps NUMERIC,
    avg_rpe NUMERIC,
    ...
);
```

### 2. `session_exercises` (Exercise-session junction)

```sql
CREATE TABLE session_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES sessions(id),
    exercise_id UUID REFERENCES exercises(id),
    order_index INTEGER DEFAULT 0,
    -- Target values (from AI or previous session)
    target_sets INTEGER,           -- e.g., 3
    target_reps TEXT,              -- e.g., '8-12' (range format supported)
    target_weight NUMERIC,         -- e.g., 60.0 (kg)
    -- Target RPE and rest period (proper columns since migration)
    target_rpe INTEGER,            -- e.g., 7 (scale 1-10)
    rest_seconds INTEGER,          -- e.g., 90
    -- AI reasoning (stored as plain text)
    notes TEXT,                    -- Only stores aiReasoning now
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    ...
);
```

### 3. `set_records` (Individual set data - NEW)

```sql
CREATE TABLE set_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_exercise_id UUID REFERENCES session_exercises(id) ON DELETE CASCADE,
    set_number SMALLINT NOT NULL,
    -- Performance data
    weight NUMERIC,
    reps INTEGER,
    rpe NUMERIC(3,1),
    duration_seconds INTEGER,
    distance NUMERIC,
    -- Tags and PR tracking
    tags TEXT[] DEFAULT '{}',      -- ['warmup', 'pr', 'drop_set', etc.]
    pr_type TEXT,                  -- 'weight', 'volume', 'reps', or NULL
    -- Metadata
    notes TEXT,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraints
    CONSTRAINT valid_set_number CHECK (set_number > 0),
    CONSTRAINT valid_rpe CHECK (rpe IS NULL OR (rpe >= 1 AND rpe <= 10)),
    CONSTRAINT valid_pr_type CHECK (pr_type IS NULL OR pr_type IN ('weight', 'volume', 'reps'))
);
```

### 4. `exercises` (Exercise library)

```sql
CREATE TABLE exercises (
    id UUID PRIMARY KEY,
    name TEXT,
    name_ko TEXT,
    category TEXT,           -- 'compound', 'isolation', etc.
    movement_pattern TEXT,   -- 'squat', 'hinge', 'horizontal_push', etc.
    movement_group TEXT,     -- 'push', 'pull', 'squat', 'hinge', etc.
    movement_detail TEXT,    -- 'horizontal', 'vertical', 'hip_dominant', etc.
    muscle_group TEXT,       -- 'chest', 'back', 'legs', etc.
    secondary_muscles TEXT[],-- Array of secondary muscle groups
    equipment TEXT,          -- 'barbell', 'dumbbell', 'bodyweight', etc.
    difficulty TEXT,
    -- Media fields (added 2026-01-25)
    gif_url TEXT,            -- ExerciseDB CDN GIF URL
    video_url TEXT,          -- ExerciseDB video URL
    image_url TEXT,          -- Static thumbnail URL
    exercisedb_id VARCHAR(30), -- ExerciseDB API ID for lookup
    -- Exercise type fields (added 2026-01-25)
    is_isometric BOOLEAN DEFAULT false,  -- Timed exercises (plank, wall sit)
    default_duration_seconds INTEGER DEFAULT 30, -- Default hold time for isometric
    ...
);
```

### 5. `workout_programs` (Training direction with client preferences)

```sql
CREATE TABLE workout_programs (
    id UUID PRIMARY KEY,
    client_id UUID REFERENCES accounts(id),
    trainer_id UUID REFERENCES accounts(id),
    training_split TEXT,                      -- 'full_body', 'upper_lower', 'push_pull_legs'
    focus_areas JSONB,                        -- Body parts to prioritize: chest, back, legs, etc.
    preferred_movement_patterns JSONB,        -- squat, hinge, horizontal_push, etc.
    last_session_focus TEXT,
    muscle_group_history JSONB,
    ...
);
-- Note: Fitness goals are fetched from accounts.fitness_goals, not stored in program
```

---

## Flow 0: Pre-Session (Client Details)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PRE-SESSION FLOW                                         │
└─────────────────────────────────────────────────────────────────────────────┘

Trainer selects a client from client list
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  CLIENT DETAILS SCREEN                                                       │
│  ─────────────────────                                                       │
│  1. General Information                                                      │
│     - Name, age, goals, body metrics                                         │
│     [accounts] table                                                         │
│                                                                              │
│  2. Recent 7-Day Lifestyle Summary                                           │
│     - Sleep: avg hours, quality          [sleep_logs]                        │
│     - Mood & Energy levels               [mood_logs]                         │
│     - Nutrition: meals, water intake     [meal_logs], [water_logs]           │
│     - Weight trend                       [weight_logs]                       │
│     - Activity: steps, active minutes    [activity_logs]                     │
│     (Data recorded by client on client-side app)                             │
│                                                                              │
│  3. Recent 3 Workout Sessions (RecentSessionsCard)                           │
│     - Focus area, date, exercise count, sets, volume, PR count               │
│     - Expandable: exercise details with set records (weight x reps)          │
│     [sessions], [session_exercises], [set_records]                           │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User clicks "세션 시작" (Session Start)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  SESSION TYPE SELECTION (ProgramSelectionSheet)                              │
│  ─────────────────────────────────────────────────                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │  빈 세션 시작    │  │  AI 세션 제작    │  │   나의 운동     │              │
│  │  (Empty Session)│  │  (AI Generate)  │  │  (My Templates) │              │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘              │
│           │                    │                    │                        │
│           ▼                    ▼                    ▼                        │
│      → Flow 4             → Flow 1              → Flow 2                     │
│   (Active Session       (AI Generation)       (Template)                     │
│    directly)                                                                 │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    이전 운동 (Previous Sessions)                     │    │
│  │  Shows up to 5 recent completed sessions → Flow 3 (Copy Previous)   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Sources for Lifestyle Summary

| Data Type | Table | Fields |
|-----------|-------|--------|
| Sleep | `sleep_logs` | bedtime, wake_time, quality |
| Mood | `mood_logs` | mood, energy, stress_level |
| Meals | `meal_logs` | meal_type, calories, protein, carbs, fat |
| Water | `water_logs` | amount_ml |
| Weight | `weight_logs` | weight |
| Activity | `activity_logs` | steps, active_minutes |

### Query Pattern
```sql
-- Fetch 7-day lifestyle summary for a client
SELECT * FROM sleep_logs WHERE client_id = ? AND log_date >= NOW() - INTERVAL '7 days';
SELECT * FROM mood_logs WHERE client_id = ? AND log_date >= NOW() - INTERVAL '7 days';
SELECT * FROM meal_logs WHERE client_id = ? AND log_date >= NOW() - INTERVAL '7 days';
-- etc.
```

---

## Flow 1: AI Session Generation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     AI SESSION GENERATION FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

User clicks "AI 세션 제작" (ProgramSelectionSheet)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Check for active program                                                    │
│  [workout_programs] WHERE status='active' AND client_id=?                   │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ├─────────────────────────────────────────────────────────┐
         │                                                         │
    [No program]                                          [Program exists]
         │                                                         │
         ▼                                                         ▼
Navigate to GenerateProgramScreen                    Show choice dialog
         │                                                         │
         ▼                                              ┌──────────┴──────────┐
Create program in [workout_programs]                   │                     │
         │                                        "목표 변경"         "현재 프로그램 유지"
         │                                             │                     │
         └──────────────────┬──────────────────────────┘                     │
                            │                                                │
                            ▼                                                │
              Navigate to ProgramReviewScreen                                │
              User reviews & clicks "활성화"                                  │
                            │                                                │
                            └────────────────────┬───────────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AI Edge Function (generate-workout)                                         │
│  ├── Read [accounts] - client context + fitness_goals (primary goal)        │
│  ├── Read [workout_programs] - training split, focus_areas,                 │
│  │                             preferred_movement_patterns                   │
│  ├── Read [sessions] + [session_exercises] - recent history                  │
│  ├── Read [exercises] - exercise library                                     │
│  ├── Call OpenAI GPT-4o-mini                                                │
│  ├── validateAndFixExerciseIds() - Fix AI-hallucinated UUIDs (2026-01-26)   │
│  │   └── Auto-correct by: name match → OCR fix (l→1, O→0) → error           │
│  └── INSERT INTO [sessions]:                                                 │
│      - ai_recommended_exercises (JSONB)                                      │
│      - ai_reasoning (text)                                                   │
│      - status: 'scheduled'                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
              Navigate to AIExerciseReviewScreen
              (User can swap/modify exercises)
                                                 │
                                                 ▼
              User clicks "Start Session"
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  activateSession (datasource)                                                │
│  ├── INSERT INTO [session_exercises]:                                        │
│  │   - session_id, exercise_id, order_index                                  │
│  │   - target_sets, target_reps, target_weight                               │
│  │   - target_rpe, rest_seconds (proper columns)                             │
│  │   - notes (aiReasoning only)                                              │
│  └── UPDATE [sessions] SET status='active', started_at=NOW()                │
└─────────────────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
              Navigate to ActiveSessionScreen
```

---

## Flow 2: Workout Template

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     WORKOUT TEMPLATE FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

User clicks "나의 운동" (ProgramSelectionSheet)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  TemplateSelectionDialog                                                     │
│  SELECT FROM [workout_templates]                                             │
│    JOIN [workout_template_exercises]                                         │
│    JOIN [exercises]                                                          │
│  WHERE creator_id = current_user_id                                          │
│  ORDER BY last_used_at DESC, usage_count DESC                                │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User selects a template
         │
         ▼
Navigate to TemplateReviewScreen
(Shows template name, description, exercises with target sets/reps/weight)
         │
         ▼
User clicks "세션 시작"
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  createSession (provider)                                                    │
│  ├── Convert template exercises → SessionExerciseInput                       │
│  │   - exerciseId, name, orderIndex                                          │
│  │   - targetSets, targetReps, targetWeight                                  │
│  │   - targetRpe, restSeconds                                                │
│  ├── INSERT INTO [sessions]: status='active', started_at=NOW()              │
│  ├── INSERT INTO [session_exercises]: using toInsertMap()                   │
│  └── UPDATE [workout_templates]: increment usage_count, last_used_at        │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
Navigate to ActiveSessionScreen
```

### Workout Template Tables

```sql
-- Templates created by trainers
CREATE TABLE workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES accounts(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    focus_area TEXT,
    estimated_duration_minutes INTEGER,
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exercises within templates
CREATE TABLE workout_template_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES workout_templates(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercises(id) NOT NULL,
    order_index INTEGER DEFAULT 0,
    target_sets INTEGER,
    target_reps TEXT,
    target_weight NUMERIC,
    target_rpe INTEGER,
    rest_seconds INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/features/workout_templates/presentation/widgets/template_selection_dialog.dart` | Template selection bottom sheet |
| `lib/features/workout_templates/presentation/screens/template_review_screen.dart` | Review screen before starting session |
| `lib/features/workout_templates/presentation/providers/workout_template_provider.dart` | Template state management |

---

## Flow 3: Copy Previous Session

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     COPY PREVIOUS SESSION FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

User clicks "이전 운동 복사" (ProgramSelectionSheet)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Fetch previous sessions                                                     │
│  SELECT FROM [sessions]                                                      │
│    JOIN [session_exercises]                                                  │
│    JOIN [set_records]                                                        │
│  WHERE client_id=? AND status='completed'                                   │
│  ORDER BY completed_at DESC LIMIT 10                                        │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
Navigate to PreviousSessionReviewScreen
(Shows exercises with historical weight/reps/sets)
         │
         ▼
User clicks "세션 시작"
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  startSession (datasource)                                                   │
│  ├── INSERT INTO [sessions]: status='active', started_at=NOW()              │
│  └── INSERT INTO [session_exercises]:                                        │
│      - session_id, exercise_id, order_index                                  │
│      - target_sets: historical sets count                                    │
│      - target_reps: historical avg reps                                      │
│      - target_weight: historical best weight                                 │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
Navigate to ActiveSessionScreen
```

---

## Flow 4: Active Session (Logging Sets)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ACTIVE SESSION FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────┘

ActiveSessionScreen loaded
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  getSessionById (datasource)                                                 │
│  SELECT FROM [sessions]                                                      │
│    JOIN [session_exercises]                                                  │
│    JOIN [exercises]                                                          │
│    JOIN [set_records]  ← New: fetches sets from normalized table            │
│  WHERE id=?                                                                  │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User performs exercise, logs a set
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  logSet (datasource)                                                         │
│  INSERT INTO [set_records]:                                                  │
│    - session_exercise_id                                                     │
│    - set_number, weight, reps, rpe                                           │
│    - duration_seconds, distance                                              │
│    - tags, pr_type, notes                                                    │
│    - completed_at (NOW())                                                    │
│  RETURNING * ← Returns new record with id, created_at, updated_at           │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User modifies a set
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  updateSet (datasource)                                                      │
│  UPDATE [set_records]                                                        │
│  SET weight=?, reps=?, rpe=?, tags=?, pr_type=?, notes=?                    │
│  WHERE id=?                                                                  │
│  RETURNING *                                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User deletes a set
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  deleteSet (datasource)                                                      │
│  DELETE FROM [set_records] WHERE id=?                                        │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
User completes session
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  completeSession (datasource)                                                │
│  ├── Calculate summary from [set_records] via [session_exercises]           │
│  └── UPDATE [sessions]:                                                      │
│      - status: 'completed'                                                   │
│      - completed_at: NOW()                                                   │
│      - total_exercises, total_sets, total_volume, avg_reps, avg_rpe         │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
Navigate to SessionSummaryScreen

─────────────────────────────────────────────────────────────────────────────────
                              CANCEL SESSION FLOW
─────────────────────────────────────────────────────────────────────────────────

User clicks back button (←) in ActiveSessionScreen
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Show Confirmation Dialog                                                    │
│  ─────────────────────────                                                   │
│  Title: "세션 취소"                                                           │
│  Content: "이 세션을 취소하시겠습니까? 모든 기록이 삭제됩니다."                │
│  Actions:                                                                    │
│    - "계속하기" → Dismiss dialog                                              │
│    - "세션 취소" → Cancel session                                             │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼ (if confirmed)
┌─────────────────────────────────────────────────────────────────────────────┐
│  cancelSession (provider → datasource)                                       │
│  UPDATE [sessions] SET status = 'cancelled' WHERE id = ?                    │
│  ├── Session status changes from 'active' → 'cancelled'                     │
│  └── All set_records remain in DB (soft delete via status)                  │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
context.go('/trainer')
(Navigates to trainer home, clears navigation stack)
```

### Session Status Values

| Status | Description |
|--------|-------------|
| `scheduled` | AI-generated session waiting to be started |
| `active` | Session currently in progress |
| `completed` | Session finished successfully |
| `cancelled` | Session discarded by user (back button) |

### Isometric Exercise Mode (Timer Mode)

For exercises flagged as `is_isometric = true` (e.g., Plank, Wall Sit, Hollow Hold):

```
Exercise selected (e.g., Plank)
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Mode Selection (default based on exercise.isIsometric)                      │
│  ─────────────────────────────────────────────────────                       │
│  ┌─────────────────┐         ┌─────────────────┐                            │
│  │    Reps Mode    │ ←─────→ │   Timer Mode    │  ← Toggle available        │
│  │  (weight x reps)│         │ (time-based)    │                            │
│  └─────────────────┘         └────────┬────────┘                            │
│                                       │                                      │
│                                       ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Countdown Timer UI                                                  │    │
│  │  - Preset buttons: 15s, 30s, 45s, 60s, 90s, 120s                    │    │
│  │  - Circular progress (green → yellow → red)                         │    │
│  │  - Start/Pause/Reset controls                                       │    │
│  │  - Haptic feedback on completion                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  logSet (Timer Mode)                                                         │
│  INSERT INTO [set_records]:                                                  │
│    - duration_seconds = selected_duration (NOT NULL)                         │
│    - reps = NULL                                                             │
│    - weight = 0 (bodyweight exercises)                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Differences**:
| Aspect | Reps Mode | Timer Mode |
|--------|-----------|------------|
| Primary input | Reps count | Duration (seconds) |
| Weight | Required | Optional (default 0) |
| UI | Weight/Reps inputs | Countdown timer |
| Stored in set_records | `reps` field | `duration_seconds` field |

---

## Data Flow Summary

| Step | Action | Tables Affected |
|------|--------|-----------------|
| **AI Flow (Flow 1)** |||
| 1 | Edge function generates exercises | `sessions` INSERT (ai_recommended_exercises, ai_reasoning) |
| 2 | User reviews in AIExerciseReviewScreen | No DB change |
| 3 | User starts session | `session_exercises` INSERT, `sessions` UPDATE (status='active') |
| **Template Flow (Flow 2)** |||
| 1 | Fetch user's templates | `workout_templates`, `workout_template_exercises`, `exercises` SELECT |
| 2 | User reviews in TemplateReviewScreen | No DB change |
| 3 | User starts session | `sessions` INSERT, `session_exercises` INSERT, `workout_templates` UPDATE (usage_count, last_used_at) |
| **Copy Flow (Flow 3)** |||
| 1 | Fetch previous sessions | `sessions`, `session_exercises`, `set_records` SELECT |
| 2 | User reviews in PreviousSessionReviewScreen | No DB change |
| 3 | User starts session | `sessions` INSERT, `session_exercises` INSERT |
| **Active Session (Flow 4)** |||
| 1 | Load session | `sessions`, `session_exercises`, `set_records` SELECT |
| 2 | Log set | `set_records` INSERT |
| 3 | Update set | `set_records` UPDATE |
| 4 | Delete set | `set_records` DELETE |
| 5 | Complete session | `sessions` UPDATE (status='completed', summary stats) |
| 6 | Cancel session (back button) | `sessions` UPDATE (status='cancelled') |

---

## Query Patterns

### Fetch Session with All Data
```sql
SELECT *,
  accounts!sessions_client_id_fkey(full_name),
  session_exercises(
    *,
    exercises(*),
    set_records(*)  -- Normalized set data
  )
FROM sessions
WHERE id = ?
```

### Insert Set Record
```sql
INSERT INTO set_records (
  session_exercise_id, set_number, weight, reps, rpe,
  duration_seconds, distance, tags, pr_type, notes, completed_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
RETURNING *
```

### Session Summary Calculation
```sql
SELECT
  COUNT(DISTINCT se.id) as total_exercises,
  COUNT(sr.id) as total_sets,
  SUM(sr.weight * sr.reps) as total_volume,
  AVG(sr.reps) as avg_reps,
  AVG(sr.rpe) as avg_rpe
FROM session_exercises se
LEFT JOIN set_records sr ON sr.session_exercise_id = se.id
WHERE se.session_id = ?
```

---

## Key Design Decisions

### Why `set_records` table instead of JSONB?

| Aspect | JSONB (Old) | Normalized Table (New) |
|--------|-------------|------------------------|
| Querying | Complex JSON operators | Standard SQL |
| Indexing | Limited | Full index support |
| Analytics | Difficult aggregations | Easy JOINs and GROUP BY |
| PR Detection | App-level logic | Can use SQL queries |
| History | Hard to track changes | `created_at`, `updated_at` |
| Referential Integrity | None | Foreign key constraints |
| Cascade Delete | Manual handling | Automatic with ON DELETE CASCADE |

### Why target columns in `session_exercises`?

1. **Query Performance**: Direct column access vs JSON parsing
2. **Type Safety**: Proper integer/numeric types vs string parsing
3. **Indexing**: Can create indexes on target columns
4. **Analytics**: Easy to aggregate target vs actual performance

### Why `target_rpe` and `rest_seconds` are proper columns now?

These values were moved from JSON `notes` to proper columns to:
1. Enable direct SQL queries for RPE-based analytics
2. Support rest time optimization queries
3. Improve type safety (INTEGER vs parsed strings)

The `notes` column now only stores `aiReasoning` as plain text.

---

## Unified Session Start Pattern (Template Pattern)

All 3 session start flows now use a unified template pattern with consistent data format:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    UNIFIED SESSION START FLOW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐           │
│  │   AI Flow       │   │ Previous Flow   │   │  Empty Flow     │           │
│  └────────┬────────┘   └────────┬────────┘   └────────┬────────┘           │
│           │                     │                     │                     │
│           ▼                     ▼                     ▼                     │
│  SessionExerciseInput   SessionExerciseInput          null                  │
│     .fromAI()              .fromPrevious()       (no exercises)             │
│           │                     │                     │                     │
│           └─────────────────────┼─────────────────────┘                     │
│                                 │                                           │
│                                 ▼                                           │
│              ┌─────────────────────────────────────┐                        │
│              │     createSession() (Provider)      │                        │
│              │  ─────────────────────────────────  │                        │
│              │  clientId: required                 │                        │
│              │  exercises: List<SessionExercise-   │                        │
│              │             Input>? (optional)      │                        │
│              │  existingSessionId: String?         │                        │
│              │     (AI flow only)                  │                        │
│              │  programId: String?                 │                        │
│              │  aiReasoning: String?               │                        │
│              └──────────────┬──────────────────────┘                        │
│                             │                                               │
│                             ▼                                               │
│              ┌─────────────────────────────────────┐                        │
│              │   createSession() (Datasource)      │                        │
│              │  ─────────────────────────────────  │                        │
│              │  if (existingSessionId):            │                        │
│              │    UPDATE sessions SET status=      │                        │
│              │      'active'                       │                        │
│              │  else:                              │                        │
│              │    INSERT INTO sessions             │                        │
│              │                                     │                        │
│              │  if (exercises):                    │                        │
│              │    INSERT INTO session_exercises    │                        │
│              │      using toInsertMap() (snake_    │                        │
│              │      case format)                   │                        │
│              │                                     │                        │
│              │  RETURN session with all relations  │                        │
│              └─────────────────────────────────────┘                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### SessionExerciseInput DTO

```dart
class SessionExerciseInput {
  final String exerciseId;
  final String name;
  final int orderIndex;
  final int? targetSets;
  final String? targetReps;    // Can be "8-12" range
  final double? targetWeight;
  final int? targetRpe;        // Now a proper DB column
  final int? restSeconds;      // Now a proper DB column
  final String? aiReasoning;   // Only for AI flow

  // Factory constructors
  factory SessionExerciseInput.fromAI(GeneratedProgramExercise e, int index);
  factory SessionExerciseInput.fromPrevious(SessionExerciseEntity e, int index);

  /// Convert to database insert format (consistent snake_case)
  /// Note: target_rpe and rest_seconds are proper columns, not JSON
  Map<String, dynamic> toInsertMap(String sessionId) {
    return {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rpe': targetRpe,      // Proper column (not in notes JSON)
      'rest_seconds': restSeconds,   // Proper column (not in notes JSON)
      if (aiReasoning != null) 'notes': aiReasoning,  // Plain text, not JSON
    };
  }
}
```

### Benefits

1. **Consistent data format** - All flows use `toInsertMap()` → snake_case
2. **Single code path** - One provider method, one datasource method
3. **Type safety** - Factory constructors ensure proper data extraction per flow
4. **Clear separation** - Data extraction logic lives in factory constructors
5. **Extensibility** - Add new flows by creating new factory constructor

---

## Files Reference

| File | Purpose |
|------|---------|
| **AI Flow** ||
| `supabase/functions/generate-workout/index.ts` | Edge function for AI generation |
| `lib/features/ai_workout/presentation/screens/ai_exercise_review_screen.dart` | AI review screen (uses `fromAI()`) |
| **Template Flow** ||
| `supabase/migrations/20260108_100000_workout_templates.sql` | Workout templates migration |
| `lib/features/workout_templates/presentation/widgets/template_selection_dialog.dart` | Template selection bottom sheet |
| `lib/features/workout_templates/presentation/screens/template_review_screen.dart` | Template review before session start |
| `lib/features/workout_templates/presentation/providers/workout_template_provider.dart` | Template state management |
| **Copy Flow** ||
| `lib/features/active_session/presentation/screens/previous_session_review_screen.dart` | Copy session review (uses `fromPrevious()`) |
| **Active Session** ||
| `lib/features/active_session/presentation/screens/active_session_screen.dart` | Active workout screen (includes cancel flow) |
| `lib/features/active_session/presentation/providers/session_provider.dart` | Provider with `createSession()`, `cancelSession()` |
| `lib/features/active_session/data/datasources/session_remote_datasource.dart` | All database operations |
| **Shared** ||
| `lib/features/active_session/data/models/session_exercise_input.dart` | Unified DTO for session exercises |
| `lib/features/active_session/presentation/widgets/program_selection_sheet.dart` | Session type selection sheet |
| `supabase/migrations/20251224_100000_add_set_records_table.sql` | Set records table migration |
| **Timer Mode (Isometric Exercises)** ||
| `lib/features/active_session/presentation/widgets/countdown_timer.dart` | Countdown timer widget for isometric exercises |
| `supabase/migrations/20260125_add_exercise_type.sql` | Migration for is_isometric column |
| **Exercise Media (Video/GIF)** ||
| `lib/shared/widgets/common/exercise_gif_image.dart` | GIF thumbnail display widget |
| `lib/shared/widgets/common/exercise_video_player.dart` | Video player widget |
| `lib/shared/widgets/common/exercise_video_popup.dart` | Full-screen video popup modal |
| `supabase/functions/image-proxy/index.ts` | Edge function for CORS proxy |
| `supabase/migrations/20260125_add_exercisedb_mapping.sql` | Migration for exercisedb_id column |
| `supabase/migrations/20260125_add_gif_url_column.sql` | Migration for gif_url column |
| **Client Details (Pre-Session)** ||
| `lib/features/client_management/presentation/screens/client_detail_screen.dart` | Client details screen |
| `lib/features/client_management/presentation/widgets/recent_sessions_card.dart` | Recent 3 workout sessions widget |
| `lib/features/client_management/presentation/widgets/lifestyle_summary_card.dart` | 7-day lifestyle summary widget |

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Edge function fails | Show error in ProgramSelectionSheet, user can retry |
| OpenAI API fails | Edge function returns 500, client shows error |
| AI returns invalid exercise UUID | Auto-corrected by name/OCR fix, or returns error to retry |
| activateSession fails | Show error in review screen, session remains 'scheduled' |
| logSet fails | Show error toast, user can retry |
| set_records FK violation | Cascade delete handles orphaned records |
| Template fetch fails | Show error in TemplateSelectionDialog |
| createSession from template fails | Show error snackbar, stay on review screen |
| cancelSession fails | Show error, session remains 'active' |

---

## Migration Notes

### From JSONB to set_records

The migration (`20251224_100000_add_set_records_table.sql`) includes:

1. **Schema changes**: Add target columns to `session_exercises`
2. **New table**: Create `set_records` with all constraints and indexes
3. **Data migration**: Copy existing JSONB data to `set_records` table
4. **RLS policies**: Secure access based on session ownership

**Backward Compatibility**: The model code checks for both `set_records` (new) and `sets` (legacy JSONB) keys when parsing session data.

### 2026-01-25 Migrations

**Isometric Exercise Support** (`20260125_add_exercise_type.sql`):
- Added `is_isometric BOOLEAN DEFAULT false` to exercises table
- Added `default_duration_seconds INTEGER DEFAULT 30`
- Flagged plank, wall sit, hollow hold, l-sit exercises as isometric

**ExerciseDB Integration** (`20260125_add_exercisedb_mapping.sql`, `20260125_add_gif_url_column.sql`):
- Added `exercisedb_id VARCHAR(30)` for ExerciseDB API mapping
- Added `gif_url TEXT` for storing CDN GIF URLs
- Populated thumbnail URLs via `20260125_populate_exercisedb_thumbnails.sql`

### 2026-01-26 Updates

**Compound Exercise Prioritization** (`exercise_recommendation_service.dart`):
- Modified `getRecommendedExercises()` to prioritize compound exercises
- Isolation exercises only appear as fallback when not enough compounds available
- Affects "맞춤 추천" section in exercise picker dialog

**AI UUID Validation** (`generate-workout/index.ts`):
- Added `validateAndFixExerciseIds()` function to edge function
- Auto-corrects AI-hallucinated UUIDs by name lookup or OCR fixes (l→1, O→0)
- Prevents session creation failures from invalid exercise IDs
