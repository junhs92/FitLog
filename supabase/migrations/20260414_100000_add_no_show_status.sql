-- Migration: Add 'no_show' status to sessions table
-- Date: 2026-04-14
-- Purpose: Frontend uses SessionStatus.noShow enum, database constraint must allow it
-- Impact: Trainers can now mark sessions as 'no_show' without constraint violation

BEGIN;

-- Drop the old constraint that doesn't include 'no_show'
ALTER TABLE sessions
  DROP CONSTRAINT IF EXISTS sessions_status_check;

-- Add new constraint that includes all valid statuses including 'no_show'
ALTER TABLE sessions
  ADD CONSTRAINT sessions_status_check
  CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled', 'no_show'));

-- Update constraint comment for documentation
COMMENT ON CONSTRAINT sessions_status_check ON sessions IS
  'Valid session statuses: scheduled (upcoming), active (in progress), completed (finished), cancelled (trainer cancelled), no_show (client no-show)';

COMMIT;
