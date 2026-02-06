-- Migration: Merge carry and rotation movement patterns into functional
-- This consolidates two rarely-used patterns into a single 'functional' pattern

-- 1. Drop existing check constraint first
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_movement_pattern_check;

-- 2. Update exercises with carry or rotation movement pattern to functional (BEFORE adding new constraint)
UPDATE exercises
SET movement_pattern = 'functional'
WHERE movement_pattern IN ('carry', 'rotation');

-- 3. Add updated check constraint with 'functional' instead of 'carry' and 'rotation'
ALTER TABLE exercises ADD CONSTRAINT exercises_movement_pattern_check
  CHECK (movement_pattern = ANY (ARRAY['squat', 'hinge', 'horizontal_push', 'horizontal_pull', 'vertical_push', 'vertical_pull', 'functional', 'isolation', 'cardio']));

-- 4. Update preferred_movement_patterns in workout_programs (jsonb array)
-- Replace 'carry' with 'functional'
UPDATE workout_programs
SET preferred_movement_patterns = (
  SELECT jsonb_agg(
    CASE WHEN elem::text = '"carry"' THEN '"functional"'::jsonb
         WHEN elem::text = '"rotation"' THEN '"functional"'::jsonb
         ELSE elem
    END
  )
  FROM jsonb_array_elements(preferred_movement_patterns) AS elem
)
WHERE preferred_movement_patterns @> '["carry"]'::jsonb
   OR preferred_movement_patterns @> '["rotation"]'::jsonb;

-- 5. Remove duplicates from preferred_movement_patterns (if both carry and rotation existed)
UPDATE workout_programs
SET preferred_movement_patterns = (
  SELECT jsonb_agg(DISTINCT elem)
  FROM jsonb_array_elements(preferred_movement_patterns) AS elem
)
WHERE preferred_movement_patterns @> '["functional"]'::jsonb;

-- 6. Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
