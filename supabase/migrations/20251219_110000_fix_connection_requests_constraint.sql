-- Migration: Fix connection_requests unique constraint
-- Problem: UNIQUE (trainer_id, client_id, status) prevents approving new requests
--          when old approved requests exist for the same pair
-- Solution: Only prevent duplicate PENDING requests (approved/rejected are historical)

-- Step 1: Drop the old unique constraint
ALTER TABLE connection_requests
DROP CONSTRAINT IF EXISTS connection_requests_trainer_id_client_id_status_key;

-- Step 2: Create partial unique index for pending requests only
-- This allows multiple approved/rejected records but only ONE pending per pair
CREATE UNIQUE INDEX IF NOT EXISTS idx_connection_requests_pending_unique
ON connection_requests(trainer_id, client_id)
WHERE status = 'pending';

-- Step 3: Clean up old approved/rejected requests when same pair has a newer pending request
DELETE FROM connection_requests cr1
WHERE cr1.status IN ('approved', 'rejected')
AND EXISTS (
    SELECT 1 FROM connection_requests cr2
    WHERE cr2.trainer_id = cr1.trainer_id
    AND cr2.client_id = cr1.client_id
    AND cr2.status = 'pending'
    AND cr2.created_at > cr1.created_at
);
