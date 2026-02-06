-- Add isometric flag and default timer settings for exercises
-- This enables support for bodyweight and isometric exercises (plank, wall sit, etc.)

-- Add is_isometric column with default false
ALTER TABLE exercises
ADD COLUMN IF NOT EXISTS is_isometric BOOLEAN DEFAULT false;

-- Add default_duration_seconds for isometric exercises (default 30 seconds)
ALTER TABLE exercises
ADD COLUMN IF NOT EXISTS default_duration_seconds INTEGER DEFAULT 30;

-- Flag known isometric exercises with their default hold times
-- Plank variations - 30 seconds default
UPDATE exercises SET is_isometric = true, default_duration_seconds = 30
WHERE name ILIKE '%plank%';

-- Dead bug and bird dog - 30 seconds default
UPDATE exercises SET is_isometric = true, default_duration_seconds = 30
WHERE name ILIKE '%dead bug%' OR name ILIKE '%bird dog%';

-- Wall sit - 60 seconds default
UPDATE exercises SET is_isometric = true, default_duration_seconds = 60
WHERE name ILIKE '%wall sit%';

-- Hollow hold and L-sit - 45 seconds default
UPDATE exercises SET is_isometric = true, default_duration_seconds = 45
WHERE name ILIKE '%hollow%hold%' OR name ILIKE '%l-sit%' OR name ILIKE '%l sit%';

-- Create index for filtering isometric exercises
CREATE INDEX IF NOT EXISTS idx_exercises_is_isometric ON exercises(is_isometric) WHERE is_isometric = true;

-- Add comments for documentation
COMMENT ON COLUMN exercises.is_isometric IS 'True for exercises measured by time held (plank, wall sit, etc.)';
COMMENT ON COLUMN exercises.default_duration_seconds IS 'Default countdown timer duration for isometric exercises';
