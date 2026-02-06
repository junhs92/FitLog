-- =====================================================
-- FitLog Pro: Simplified Workout Structure Migration
-- =====================================================
-- This migration converts workout_programs from detailed
-- workout plans to training DIRECTIONS that guide AI
-- session generation dynamically.
--
-- Key Changes:
-- 1. workout_programs becomes a training direction/strategy
-- 2. Sessions track AI generation context (focus, gap, reasoning)
-- 3. Deprecated tables (workout_days, program_exercises) are dropped
-- =====================================================

-- Step 1: Add new columns to workout_programs
-- These columns enable dynamic AI session generation based on
-- training direction rather than pre-defined workout plans
ALTER TABLE workout_programs
ADD COLUMN IF NOT EXISTS training_split text DEFAULT 'full_body',
ADD COLUMN IF NOT EXISTS focus_areas jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS constraints jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS total_sessions integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS avg_sessions_per_week numeric(3,1) DEFAULT 0,
ADD COLUMN IF NOT EXISTS consistency_score numeric(3,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_session_focus text,
ADD COLUMN IF NOT EXISTS muscle_group_history jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS ai_guidelines jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS expires_at timestamptz;

-- Step 2: Add new columns to sessions
-- These columns track AI decision context for each session
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS session_number integer,
ADD COLUMN IF NOT EXISTS focus_area text,
ADD COLUMN IF NOT EXISTS days_since_last integer,
ADD COLUMN IF NOT EXISTS ai_reasoning text;

-- Step 3: Drop deprecated column from sessions
-- workout_day_id is no longer needed as sessions are generated dynamically
ALTER TABLE sessions DROP COLUMN IF EXISTS workout_day_id;

-- Step 4: Drop deprecated tables
-- These tables are replaced by dynamic AI session generation
DROP TABLE IF EXISTS program_exercises CASCADE;
DROP TABLE IF EXISTS workout_days CASCADE;

-- Step 5: Add comments for documentation
COMMENT ON COLUMN workout_programs.training_split IS 'Training split preference: full_body, upper_lower, push_pull_legs, bro_split, custom';
COMMENT ON COLUMN workout_programs.focus_areas IS 'Priority muscle groups or goals: ["chest", "back", "strength"]';
COMMENT ON COLUMN workout_programs.constraints IS 'Client limitations: {"avoid_exercises": [], "max_duration_minutes": 60}';
COMMENT ON COLUMN workout_programs.total_sessions IS 'Count of completed sessions in this program';
COMMENT ON COLUMN workout_programs.avg_sessions_per_week IS 'Rolling average sessions per week';
COMMENT ON COLUMN workout_programs.consistency_score IS 'Client consistency rating 0-1';
COMMENT ON COLUMN workout_programs.last_session_focus IS 'Focus area of most recent session';
COMMENT ON COLUMN workout_programs.muscle_group_history IS 'Recent muscle groups worked with dates';
COMMENT ON COLUMN workout_programs.ai_guidelines IS 'AI memory: learned preferences, adjustments, notes';
COMMENT ON COLUMN workout_programs.expires_at IS 'Program expiration date (default 3 months from creation)';

COMMENT ON COLUMN sessions.session_number IS 'Sequential session number within program';
COMMENT ON COLUMN sessions.focus_area IS 'Primary focus of this session (e.g., chest, pull, legs)';
COMMENT ON COLUMN sessions.days_since_last IS 'Days gap from previous session';
COMMENT ON COLUMN sessions.ai_reasoning IS 'AI explanation for exercise selection';

-- Step 6: Create index for performance on frequently queried columns
CREATE INDEX IF NOT EXISTS idx_workout_programs_expires_at ON workout_programs(expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_focus_area ON sessions(focus_area);
CREATE INDEX IF NOT EXISTS idx_sessions_program_id ON sessions(program_id);
