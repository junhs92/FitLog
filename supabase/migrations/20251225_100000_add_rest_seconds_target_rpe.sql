-- Add rest_seconds and target_rpe columns to session_exercises table
-- These columns support the unified session start flow template pattern

ALTER TABLE session_exercises
ADD COLUMN IF NOT EXISTS rest_seconds INTEGER,
ADD COLUMN IF NOT EXISTS target_rpe INTEGER;

COMMENT ON COLUMN session_exercises.rest_seconds IS 'Rest time in seconds between sets';
COMMENT ON COLUMN session_exercises.target_rpe IS 'Target RPE (Rate of Perceived Exertion) 1-10';
