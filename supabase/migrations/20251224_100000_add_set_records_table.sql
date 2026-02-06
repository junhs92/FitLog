-- Migration: Add set_records table and target columns to session_exercises
-- Date: 2024-12-24
-- Description:
--   1. Add target columns (target_sets, target_reps, target_weight) to session_exercises
--   2. Create set_records table to replace JSONB sets storage
--   3. Migrate existing JSONB data to set_records table

-- ============================================
-- Part 1: Add target columns to session_exercises
-- ============================================

ALTER TABLE session_exercises
ADD COLUMN IF NOT EXISTS target_sets integer,
ADD COLUMN IF NOT EXISTS target_reps text,
ADD COLUMN IF NOT EXISTS target_weight numeric;

COMMENT ON COLUMN session_exercises.target_sets IS 'Target number of sets for this exercise';
COMMENT ON COLUMN session_exercises.target_reps IS 'Target reps (can be range like "8-12")';
COMMENT ON COLUMN session_exercises.target_weight IS 'Recommended weight in kg';

-- ============================================
-- Part 2: Create set_records table
-- ============================================

CREATE TABLE IF NOT EXISTS set_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_exercise_id UUID NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
  set_number SMALLINT NOT NULL,

  -- Performance data
  weight NUMERIC,
  reps INTEGER,
  rpe NUMERIC(3,1),
  duration_seconds INTEGER,
  distance NUMERIC,

  -- Tags (array of predefined values)
  tags TEXT[] DEFAULT '{}',

  -- PR tracking
  pr_type TEXT, -- 'weight', 'volume', 'reps', null if not PR

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

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_set_records_session_exercise ON set_records(session_exercise_id);
CREATE INDEX IF NOT EXISTS idx_set_records_completed_at ON set_records(completed_at);
CREATE INDEX IF NOT EXISTS idx_set_records_pr_type ON set_records(pr_type) WHERE pr_type IS NOT NULL;

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_set_records_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_records_updated_at ON set_records;
CREATE TRIGGER set_records_updated_at
  BEFORE UPDATE ON set_records
  FOR EACH ROW
  EXECUTE FUNCTION update_set_records_updated_at();

-- ============================================
-- Part 3: Migrate existing JSONB data to set_records
-- ============================================

-- Migrate existing sets from JSONB to set_records table
-- This handles the case where sets column contains valid JSONB array data
INSERT INTO set_records (
  session_exercise_id,
  set_number,
  weight,
  reps,
  rpe,
  duration_seconds,
  distance,
  tags,
  notes,
  completed_at,
  created_at
)
SELECT
  se.id,
  COALESCE((set_data->>'set_number')::SMALLINT, 1),
  (set_data->>'weight')::NUMERIC,
  (set_data->>'reps')::INTEGER,
  (set_data->>'rpe')::NUMERIC,
  (set_data->>'duration_seconds')::INTEGER,
  (set_data->>'distance')::NUMERIC,
  COALESCE(
    ARRAY(SELECT jsonb_array_elements_text(set_data->'tags')),
    '{}'
  ),
  set_data->>'notes',
  COALESCE((set_data->>'completed_at')::TIMESTAMPTZ, NOW()),
  COALESCE((set_data->>'completed_at')::TIMESTAMPTZ, NOW())
FROM session_exercises se,
LATERAL jsonb_array_elements(se.sets) AS set_data
WHERE se.sets IS NOT NULL
  AND se.sets::text != '[]'
  AND se.sets::text != 'null'
  AND jsonb_typeof(se.sets) = 'array'
  AND jsonb_array_length(se.sets) > 0
ON CONFLICT DO NOTHING;

-- ============================================
-- Part 4: Enable RLS on set_records
-- ============================================

ALTER TABLE set_records ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view set_records for sessions they have access to
CREATE POLICY "Users can view their set_records"
  ON set_records
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM session_exercises se
      JOIN sessions s ON se.session_id = s.id
      JOIN accounts a ON (s.trainer_id = a.id OR s.client_id = a.id)
      WHERE se.id = set_records.session_exercise_id
        AND a.user_id = auth.uid()
    )
  );

-- Policy: Users can insert set_records for their sessions
CREATE POLICY "Users can insert set_records"
  ON set_records
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM session_exercises se
      JOIN sessions s ON se.session_id = s.id
      JOIN accounts a ON s.trainer_id = a.id
      WHERE se.id = set_records.session_exercise_id
        AND a.user_id = auth.uid()
    )
  );

-- Policy: Users can update their set_records
CREATE POLICY "Users can update their set_records"
  ON set_records
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM session_exercises se
      JOIN sessions s ON se.session_id = s.id
      JOIN accounts a ON s.trainer_id = a.id
      WHERE se.id = set_records.session_exercise_id
        AND a.user_id = auth.uid()
    )
  );

-- Policy: Users can delete their set_records
CREATE POLICY "Users can delete their set_records"
  ON set_records
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM session_exercises se
      JOIN sessions s ON se.session_id = s.id
      JOIN accounts a ON s.trainer_id = a.id
      WHERE se.id = set_records.session_exercise_id
        AND a.user_id = auth.uid()
    )
  );
