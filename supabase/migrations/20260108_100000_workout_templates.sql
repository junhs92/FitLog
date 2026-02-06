-- =====================================================
-- Workout Templates: Trainer-created reusable workouts
-- =====================================================

-- Main templates table
CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Template Details
  name TEXT NOT NULL,
  name_ko TEXT,
  description TEXT,

  -- Metadata
  estimated_duration_minutes INTEGER,
  focus_area TEXT, -- chest, back, legs, full_body, push, pull, upper, lower, etc.

  -- Usage Tracking
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Template exercises (normalized - references exercises table)
CREATE TABLE IF NOT EXISTS workout_template_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,

  -- Ordering
  order_index INTEGER NOT NULL DEFAULT 0,

  -- Target values
  target_sets INTEGER,
  target_reps TEXT, -- Can be "8-12", "10", "AMRAP", etc.
  target_weight NUMERIC,
  target_rpe INTEGER CHECK (target_rpe IS NULL OR (target_rpe >= 1 AND target_rpe <= 10)),
  rest_seconds INTEGER,

  -- Notes
  notes TEXT,

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_templates_creator ON workout_templates(creator_id);
CREATE INDEX IF NOT EXISTS idx_workout_templates_focus_area ON workout_templates(focus_area);
CREATE INDEX IF NOT EXISTS idx_workout_templates_created_at ON workout_templates(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_template_exercises_template ON workout_template_exercises(template_id);
CREATE INDEX IF NOT EXISTS idx_template_exercises_order ON workout_template_exercises(template_id, order_index);

-- RLS
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_template_exercises ENABLE ROW LEVEL SECURITY;

-- Policy: Creator can manage their own templates
DROP POLICY IF EXISTS "Creator manages own templates" ON workout_templates;
CREATE POLICY "Creator manages own templates" ON workout_templates
  FOR ALL USING (
    creator_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Policy: Creator can manage exercises in their templates
DROP POLICY IF EXISTS "Creator manages template exercises" ON workout_template_exercises;
CREATE POLICY "Creator manages template exercises" ON workout_template_exercises
  FOR ALL USING (
    template_id IN (
      SELECT id FROM workout_templates
      WHERE creator_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
    )
  );

-- Trigger for updated_at on workout_templates
CREATE OR REPLACE FUNCTION update_workout_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_workout_templates_updated_at ON workout_templates;
CREATE TRIGGER trigger_workout_templates_updated_at
  BEFORE UPDATE ON workout_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_templates_updated_at();

-- Helper function: Increment usage count when template is used
CREATE OR REPLACE FUNCTION increment_template_usage(p_template_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE workout_templates
  SET usage_count = usage_count + 1,
      last_used_at = NOW()
  WHERE id = p_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
