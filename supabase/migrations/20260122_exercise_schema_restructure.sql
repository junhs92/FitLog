-- =====================================================
-- Exercise Schema Restructure Migration
-- Changes movement_pattern → movement_group + movement_detail
-- Adds family and angle columns
-- Updates muscle_group to include adductors
-- =====================================================

-- =====================================================
-- 1. ADD NEW COLUMNS
-- =====================================================

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS movement_group TEXT,
  ADD COLUMN IF NOT EXISTS movement_detail TEXT,
  ADD COLUMN IF NOT EXISTS family TEXT,
  ADD COLUMN IF NOT EXISTS angle TEXT;

-- =====================================================
-- 2. MIGRATE DATA: movement_pattern → movement_group + movement_detail
-- =====================================================

-- Direct mappings for compound movement patterns
UPDATE exercises SET movement_group = 'push', movement_detail = 'horizontal'
WHERE movement_pattern = 'horizontal_push';

UPDATE exercises SET movement_group = 'push', movement_detail = 'vertical'
WHERE movement_pattern = 'vertical_push';

UPDATE exercises SET movement_group = 'pull', movement_detail = 'horizontal'
WHERE movement_pattern = 'horizontal_pull';

UPDATE exercises SET movement_group = 'pull', movement_detail = 'vertical'
WHERE movement_pattern = 'vertical_pull';

UPDATE exercises SET movement_group = 'legs', movement_detail = 'squat'
WHERE movement_pattern = 'squat';

UPDATE exercises SET movement_group = 'legs', movement_detail = 'hinge'
WHERE movement_pattern = 'hinge';

-- Functional movements (carry, rotation) → core
UPDATE exercises SET movement_group = 'core'
WHERE movement_pattern IN ('carry', 'rotation', 'functional');

-- Set rotation detail for specific rotation exercises
UPDATE exercises SET movement_detail = 'rotation'
WHERE movement_pattern = 'rotation' OR name IN ('Cable Woodchop', 'Russian Twist');

-- Cardio → other
UPDATE exercises SET movement_group = 'other'
WHERE movement_pattern = 'cardio';

-- Isolation mappings by muscle_group
UPDATE exercises SET movement_group = 'pull'
WHERE movement_pattern = 'isolation' AND muscle_group IN ('biceps', 'back');

UPDATE exercises SET movement_group = 'push'
WHERE movement_pattern = 'isolation' AND muscle_group IN ('triceps', 'chest', 'shoulders');

UPDATE exercises SET movement_group = 'legs'
WHERE movement_pattern = 'isolation' AND muscle_group IN ('quadriceps', 'hamstrings', 'glutes', 'calves');

UPDATE exercises SET movement_group = 'core'
WHERE movement_pattern = 'isolation' AND muscle_group = 'core';

-- Handle forearms isolation → pull (accessory to pulling movements)
UPDATE exercises SET movement_group = 'pull'
WHERE movement_pattern = 'isolation' AND muscle_group = 'forearms';

-- Handle full_body → other
UPDATE exercises SET movement_group = 'other'
WHERE movement_pattern = 'isolation' AND muscle_group = 'full_body';

-- Catch-all for any remaining null movement_group
UPDATE exercises SET movement_group = 'other'
WHERE movement_group IS NULL;

-- =====================================================
-- 3. DROP OLD CONSTRAINT AND COLUMN
-- =====================================================

ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_movement_pattern_check;

-- =====================================================
-- 4. ADD NEW CONSTRAINTS
-- =====================================================

-- Make movement_group NOT NULL (after data migration)
ALTER TABLE exercises ALTER COLUMN movement_group SET NOT NULL;

-- movement_group constraint
ALTER TABLE exercises ADD CONSTRAINT exercises_movement_group_check
  CHECK (movement_group IN ('push', 'pull', 'legs', 'core', 'other'));

-- movement_detail constraint (conditional on movement_group)
ALTER TABLE exercises ADD CONSTRAINT exercises_movement_detail_check
  CHECK (
    movement_detail IS NULL OR
    (movement_group IN ('push', 'pull') AND movement_detail IN ('horizontal', 'vertical')) OR
    (movement_group = 'legs' AND movement_detail IN ('squat', 'hinge', 'lunge')) OR
    (movement_group = 'core' AND movement_detail IN ('anti_extension', 'anti_flexion', 'anti_lateral_flexion', 'rotation'))
  );

-- angle constraint
ALTER TABLE exercises ADD CONSTRAINT exercises_angle_check
  CHECK (angle IS NULL OR angle IN ('flat', 'incline', 'decline', 'neutral', 'na'));

-- =====================================================
-- 5. UPDATE MUSCLE_GROUP CONSTRAINT (add adductors)
-- =====================================================

ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_muscle_group_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_muscle_group_check
  CHECK (muscle_group IN (
    'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
    'quadriceps', 'hamstrings', 'glutes', 'calves', 'adductors', 'core', 'full_body'
  ));

-- =====================================================
-- 6. DROP OLD COLUMN (after migration is complete)
-- =====================================================

ALTER TABLE exercises DROP COLUMN IF EXISTS movement_pattern;

-- =====================================================
-- 7. UPDATE INDEXES
-- =====================================================

DROP INDEX IF EXISTS idx_exercises_movement_pattern;
CREATE INDEX IF NOT EXISTS idx_exercises_movement_group ON exercises(movement_group);
CREATE INDEX IF NOT EXISTS idx_exercises_movement_detail ON exercises(movement_detail) WHERE movement_detail IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_exercises_family ON exercises(family) WHERE family IS NOT NULL;

-- =====================================================
-- 8. UPDATE WORKOUT_PROGRAMS TABLE
-- Rename preferred_movement_patterns → preferred_movement_groups
-- =====================================================

-- Rename the column
ALTER TABLE workout_programs
  RENAME COLUMN preferred_movement_patterns TO preferred_movement_groups;

-- Migrate JSONB values from old patterns to new groups
UPDATE workout_programs SET preferred_movement_groups = (
  SELECT COALESCE(jsonb_agg(DISTINCT
    CASE val
      WHEN 'horizontal_push' THEN 'push'
      WHEN 'vertical_push' THEN 'push'
      WHEN 'horizontal_pull' THEN 'pull'
      WHEN 'vertical_pull' THEN 'pull'
      WHEN 'squat' THEN 'legs'
      WHEN 'hinge' THEN 'legs'
      WHEN 'functional' THEN 'core'
      WHEN 'carry' THEN 'core'
      WHEN 'rotation' THEN 'core'
      WHEN 'isolation' THEN 'other'
      WHEN 'cardio' THEN 'other'
      -- Keep new values as-is
      WHEN 'push' THEN 'push'
      WHEN 'pull' THEN 'pull'
      WHEN 'legs' THEN 'legs'
      WHEN 'core' THEN 'core'
      WHEN 'other' THEN 'other'
      ELSE 'other'
    END
  ), '[]'::jsonb)
  FROM jsonb_array_elements_text(preferred_movement_groups) AS val
)
WHERE preferred_movement_groups IS NOT NULL
  AND jsonb_typeof(preferred_movement_groups) = 'array'
  AND jsonb_array_length(preferred_movement_groups) > 0;

-- Update column comment
COMMENT ON COLUMN workout_programs.preferred_movement_groups IS 'Client preferred movement groups: push, pull, legs, core, other';

-- =====================================================
-- 9. UPDATE COMMENT_USAGE TABLE
-- Rename movement_pattern → movement_group
-- =====================================================

ALTER TABLE comment_usage
  RENAME COLUMN movement_pattern TO movement_group;

-- Migrate values in comment_usage
UPDATE comment_usage SET movement_group =
  CASE movement_group
    WHEN 'horizontal_push' THEN 'push'
    WHEN 'vertical_push' THEN 'push'
    WHEN 'horizontal_pull' THEN 'pull'
    WHEN 'vertical_pull' THEN 'pull'
    WHEN 'squat' THEN 'legs'
    WHEN 'hinge' THEN 'legs'
    WHEN 'functional' THEN 'core'
    WHEN 'carry' THEN 'core'
    WHEN 'rotation' THEN 'core'
    WHEN 'isolation' THEN 'other'
    WHEN 'cardio' THEN 'other'
    ELSE movement_group
  END
WHERE movement_group IS NOT NULL;

-- Update index
DROP INDEX IF EXISTS idx_comment_usage_lookup;
CREATE INDEX IF NOT EXISTS idx_comment_usage_lookup
ON comment_usage(trainer_id, muscle_group, movement_group);

-- =====================================================
-- 10. ADD COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON COLUMN exercises.movement_group IS 'High-level movement category: push, pull, legs, core, other';
COMMENT ON COLUMN exercises.movement_detail IS 'Specific movement sub-type within the group';
COMMENT ON COLUMN exercises.family IS 'Exercise family name (e.g., bench_press, squat, deadlift)';
COMMENT ON COLUMN exercises.angle IS 'Bench/body angle: flat, incline, decline, neutral, na';
