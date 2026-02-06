-- Add gif_url column to exercises table for animated GIF images
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS gif_url TEXT;

-- Add comment explaining the column
COMMENT ON COLUMN exercises.gif_url IS 'Animated GIF URL from ExerciseDB API';
