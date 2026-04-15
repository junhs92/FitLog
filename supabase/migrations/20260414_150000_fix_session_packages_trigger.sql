-- Migration: Fix session_packages trigger for correct decrement logic
-- Date: 2026-04-14
-- Purpose: Fix over-decrement issue when clients have multiple active packages
-- Impact: Prevents double-counting of session usage across packages
-- Priority: P3 - HIGH (data integrity before production)

BEGIN;

-- Drop the existing trigger that causes over-decrement
DROP TRIGGER IF EXISTS trigger_increment_sessions_used ON sessions;

-- Drop the function so we can recreate it
DROP FUNCTION IF EXISTS increment_sessions_used();

-- Create fixed function that only decrements the oldest active package
CREATE OR REPLACE FUNCTION increment_sessions_used()
RETURNS TRIGGER AS $$
BEGIN
  -- Only decrement if session status changed to 'completed'
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Update ONLY the oldest active package (oldest-first FIFO)
    -- This prevents over-decrement when client has multiple packages
    UPDATE session_packages
    SET sessions_used = sessions_used + 1
    WHERE id = (
      SELECT id FROM session_packages
      WHERE client_id = NEW.client_id
        AND is_active = true
        AND sessions_used < total_sessions
      ORDER BY created_at ASC
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trigger_increment_sessions_used
AFTER UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION increment_sessions_used();

-- Add comment for documentation
COMMENT ON FUNCTION increment_sessions_used() IS
  'Decrements sessions_used on the oldest active package when session is completed. Prevents over-decrement with multiple packages.';

COMMIT;
