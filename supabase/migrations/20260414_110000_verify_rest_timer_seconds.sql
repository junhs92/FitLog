-- Migration: Verify rest_timer_seconds column exists in sessions table
-- Date: 2026-04-14
-- Purpose: Frontend SessionEntity expects this column for per-session rest timer configuration
-- Impact: Trainers can customize rest duration per session instead of using global default

BEGIN;

-- Add rest_timer_seconds column if it doesn't exist
-- This column allows per-session customization of rest time between sets
ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS rest_timer_seconds INTEGER DEFAULT 90;

-- Update constraint if column already exists but has no default
-- Ensure all existing rows have a sensible default
UPDATE sessions
SET rest_timer_seconds = 90
WHERE rest_timer_seconds IS NULL;

-- Add NOT NULL constraint to ensure all rows have a value
ALTER TABLE sessions
  ALTER COLUMN rest_timer_seconds SET NOT NULL;

-- Update column comment for documentation
COMMENT ON COLUMN sessions.rest_timer_seconds IS
  'Rest duration in seconds between sets (default: 90 seconds / 1.5 minutes). Can be customized per session by trainer.';

COMMIT;
