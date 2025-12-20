-- MVP Features Migration
-- Features: AI Workout Generation, Session Recording, Quick Reports

-- =====================================================
-- 1. AI Generation Context Table
-- Stores client fitness profile for AI workout generation
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_generation_context (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Fitness Profile
  fitness_goals JSONB DEFAULT '[]'::jsonb,  -- e.g., ["strength", "hypertrophy"]
  available_equipment TEXT[] DEFAULT '{}',   -- e.g., {"barbell", "dumbbells", "bench"}
  experience_level TEXT DEFAULT 'intermediate' CHECK (experience_level IN ('beginner', 'intermediate', 'advanced', 'expert')),

  -- Physical Considerations
  injury_history JSONB DEFAULT '[]'::jsonb,  -- e.g., [{"area": "lower_back", "severity": "mild", "notes": "avoid deadlifts"}]
  limitations TEXT[],                         -- e.g., {"no_overhead_press", "limited_squats"}

  -- Preferences
  preferences JSONB DEFAULT '{}'::jsonb,      -- e.g., {"preferred_session_duration": 60, "favorite_exercises": [...]}

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure one context per client
  UNIQUE(client_id)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_ai_generation_context_client_id ON ai_generation_context(client_id);

-- RLS Policies
ALTER TABLE ai_generation_context ENABLE ROW LEVEL SECURITY;

-- Trainers can view and manage context for their clients
CREATE POLICY "Trainers can view client context" ON ai_generation_context
  FOR SELECT
  USING (
    client_id IN (
      SELECT tcr.client_id
      FROM trainer_client_relationships tcr
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE tcr.trainer_id = a.id AND tcr.status = 'active'
    )
  );

CREATE POLICY "Trainers can insert client context" ON ai_generation_context
  FOR INSERT
  WITH CHECK (
    client_id IN (
      SELECT tcr.client_id
      FROM trainer_client_relationships tcr
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE tcr.trainer_id = a.id AND tcr.status = 'active'
    )
  );

CREATE POLICY "Trainers can update client context" ON ai_generation_context
  FOR UPDATE
  USING (
    client_id IN (
      SELECT tcr.client_id
      FROM trainer_client_relationships tcr
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE tcr.trainer_id = a.id AND tcr.status = 'active'
    )
  );

-- Clients can view their own context
CREATE POLICY "Clients can view own context" ON ai_generation_context
  FOR SELECT
  USING (
    client_id IN (
      SELECT id FROM accounts WHERE user_id = auth.uid()
    )
  );

-- =====================================================
-- 2. Session Reports Table Updates
-- Add PDF URL column for report delivery
-- =====================================================

ALTER TABLE session_reports
  ADD COLUMN IF NOT EXISTS pdf_url TEXT,
  ADD COLUMN IF NOT EXISTS email_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS push_sent_at TIMESTAMPTZ;

-- =====================================================
-- 3. Session Exercise Feedback Table (if not exists)
-- Stores difficulty feedback during sessions for AI learning
-- =====================================================

CREATE TABLE IF NOT EXISTS session_exercise_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_exercise_id UUID NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id),

  -- Feedback data
  feedback TEXT NOT NULL CHECK (feedback IN ('too_easy', 'just_right', 'challenging', 'struggling')),
  notes TEXT,

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for aggregating feedback by exercise
CREATE INDEX IF NOT EXISTS idx_session_exercise_feedback_exercise_id ON session_exercise_feedback(exercise_id);
CREATE INDEX IF NOT EXISTS idx_session_exercise_feedback_session_exercise_id ON session_exercise_feedback(session_exercise_id);

-- RLS Policies
ALTER TABLE session_exercise_feedback ENABLE ROW LEVEL SECURITY;

-- Trainers can manage feedback for their sessions
CREATE POLICY "Trainers can manage session feedback" ON session_exercise_feedback
  FOR ALL
  USING (
    session_exercise_id IN (
      SELECT se.id
      FROM session_exercises se
      JOIN sessions s ON se.session_id = s.id
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE s.trainer_id = a.id
    )
  );

-- =====================================================
-- 4. Exercise Swap History Table (if not exists)
-- Tracks exercise swaps for AI learning
-- =====================================================

CREATE TABLE IF NOT EXISTS exercise_swap_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES accounts(id),
  session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,

  -- Swap details
  original_exercise_id UUID NOT NULL REFERENCES exercises(id),
  replacement_exercise_id UUID NOT NULL REFERENCES exercises(id),

  -- Reason
  feedback_reason TEXT CHECK (feedback_reason IN ('too_easy', 'just_right', 'challenging', 'struggling')),
  custom_reason TEXT,

  -- Timestamp
  swapped_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_exercise_swap_history_client_id ON exercise_swap_history(client_id);
CREATE INDEX IF NOT EXISTS idx_exercise_swap_history_original_exercise ON exercise_swap_history(original_exercise_id);

-- RLS Policies
ALTER TABLE exercise_swap_history ENABLE ROW LEVEL SECURITY;

-- Trainers can view and create swap history for their clients
CREATE POLICY "Trainers can manage swap history" ON exercise_swap_history
  FOR ALL
  USING (
    trainer_id IN (
      SELECT id FROM accounts WHERE user_id = auth.uid()
    )
    OR
    client_id IN (
      SELECT tcr.client_id
      FROM trainer_client_relationships tcr
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE tcr.trainer_id = a.id AND tcr.status = 'active'
    )
  );

-- =====================================================
-- 5. Trigger for updated_at on ai_generation_context
-- =====================================================

CREATE OR REPLACE FUNCTION update_ai_generation_context_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_ai_generation_context_updated_at ON ai_generation_context;
CREATE TRIGGER trigger_update_ai_generation_context_updated_at
  BEFORE UPDATE ON ai_generation_context
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_generation_context_updated_at();

-- =====================================================
-- 6. Add rest_timer_seconds to sessions table
-- Stores preferred rest timer duration for the session
-- =====================================================

ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS rest_timer_seconds INTEGER DEFAULT 90;
