-- Add session summary columns for quick retrieval of workout stats
-- These are calculated and saved when a session is completed

ALTER TABLE sessions ADD COLUMN IF NOT EXISTS total_exercises INTEGER;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS total_sets INTEGER;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS total_volume NUMERIC;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS avg_reps NUMERIC;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS avg_rpe NUMERIC;

-- Add comments for documentation
COMMENT ON COLUMN sessions.total_exercises IS 'Number of exercises completed in session';
COMMENT ON COLUMN sessions.total_sets IS 'Total number of sets logged across all exercises';
COMMENT ON COLUMN sessions.total_volume IS 'Sum of (weight * reps) across all sets';
COMMENT ON COLUMN sessions.avg_reps IS 'Average reps per set across all exercises';
COMMENT ON COLUMN sessions.avg_rpe IS 'Average RPE across all sets that have RPE logged';
