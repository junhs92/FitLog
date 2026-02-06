-- Add ExerciseDB ID mapping to exercises table
-- This column stores the ExerciseDB API exercise ID for GIF lookup

ALTER TABLE exercises
ADD COLUMN IF NOT EXISTS exercisedb_id VARCHAR(30);

-- Create index for efficient lookup
CREATE INDEX IF NOT EXISTS idx_exercises_exercisedb_id
ON exercises(exercisedb_id) WHERE exercisedb_id IS NOT NULL;

COMMENT ON COLUMN exercises.exercisedb_id IS 'ExerciseDB API exercise ID for GIF lookup (e.g., exr_41n2hZZdH9uyYFGZ)';
