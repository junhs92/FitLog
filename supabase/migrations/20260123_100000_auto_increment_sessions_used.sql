-- Migration: Auto-increment sessions_used when session completes
-- Problem: sessions_used in session_packages is not updated when sessions are completed directly
-- Solution: Database trigger that automatically increments sessions_used

-- Step 1: Create function to increment sessions_used when session completes
CREATE OR REPLACE FUNCTION increment_sessions_used()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger when status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE session_packages
    SET sessions_used = sessions_used + 1,
        updated_at = NOW()
    WHERE client_id = NEW.client_id
      AND is_active = true
      AND sessions_used < total_sessions;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create trigger on sessions table
CREATE TRIGGER trigger_increment_sessions_used
AFTER INSERT OR UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION increment_sessions_used();

-- Step 3: Fix existing data - update sessions_used based on actual completed sessions
-- This corrects any historical discrepancy
UPDATE session_packages sp
SET sessions_used = COALESCE((
  SELECT COUNT(*)
  FROM sessions s
  WHERE s.client_id = sp.client_id
    AND s.status = 'completed'
    AND s.created_at >= sp.purchased_at
), 0),
updated_at = NOW()
WHERE sp.is_active = true;
