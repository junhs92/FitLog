-- Migration: Simplify workout_programs to store client preferences
-- Purpose: Change from storing fitness goals to storing client preferences for AI exercise recommendations
-- Fitness goals already exist in accounts.fitness_goals, so the active program should store:
-- - Body part focus (focusAreas) - already exists
-- - Movement pattern preferences (preferredMovementPatterns) - new

-- Add new column for preferred movement patterns
-- Available patterns: squat, hinge, horizontal_push, horizontal_pull, vertical_push, vertical_pull, carry, rotation, isolation, cardio
ALTER TABLE workout_programs
ADD COLUMN IF NOT EXISTS preferred_movement_patterns JSONB DEFAULT '[]'::jsonb;

-- Add comment for documentation
COMMENT ON COLUMN workout_programs.preferred_movement_patterns IS 'Client preferred movement patterns: squat, hinge, horizontal_push, horizontal_pull, vertical_push, vertical_pull, carry, rotation, isolation, cardio';

-- Drop deprecated columns that are no longer needed
-- (Goals come from client profile, constraints/guidelines are simplified)
ALTER TABLE workout_programs
DROP COLUMN IF EXISTS primary_goal,
DROP COLUMN IF EXISTS secondary_goal,
DROP COLUMN IF EXISTS constraints,
DROP COLUMN IF EXISTS ai_guidelines;
