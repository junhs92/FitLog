-- Migration: Connection Requests System
-- Simplified trainer-client connection flow (trainer sends request, client accepts/rejects)

-- ============================================
-- CREATE CONNECTION_REQUESTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS connection_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,

    -- Prevent duplicate pending requests
    UNIQUE (trainer_id, client_id, status)
);

-- ============================================
-- INDEXES
-- ============================================

-- Index for client to see their pending requests
CREATE INDEX IF NOT EXISTS idx_connection_requests_client_pending
ON connection_requests(client_id, status)
WHERE status = 'pending';

-- Index for trainer to see their sent requests
CREATE INDEX IF NOT EXISTS idx_connection_requests_trainer
ON connection_requests(trainer_id, created_at DESC);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE connection_requests ENABLE ROW LEVEL SECURITY;

-- Trainers can view their own sent requests
CREATE POLICY "trainers_view_own_requests" ON connection_requests
FOR SELECT
TO authenticated
USING (trainer_id = get_my_account_id());

-- Clients can view requests sent to them
CREATE POLICY "clients_view_received_requests" ON connection_requests
FOR SELECT
TO authenticated
USING (client_id = get_my_account_id());

-- Trainers can create requests (only to clients, not to themselves)
CREATE POLICY "trainers_create_requests" ON connection_requests
FOR INSERT
TO authenticated
WITH CHECK (
    trainer_id = get_my_account_id()
    AND client_id != get_my_account_id()
    AND is_current_user_trainer()
    AND status = 'pending'
);

-- Clients can update requests sent to them (accept/reject)
CREATE POLICY "clients_respond_to_requests" ON connection_requests
FOR UPDATE
TO authenticated
USING (
    client_id = get_my_account_id()
    AND status = 'pending'
)
WITH CHECK (
    client_id = get_my_account_id()
    AND status IN ('approved', 'rejected')
);

-- Trainers can delete their own pending requests (cancel)
CREATE POLICY "trainers_cancel_pending_requests" ON connection_requests
FOR DELETE
TO authenticated
USING (
    trainer_id = get_my_account_id()
    AND status = 'pending'
);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE connection_requests IS 'Stores trainer-to-client connection requests for the simplified approval flow';
COMMENT ON COLUMN connection_requests.status IS 'pending = awaiting client response, approved = client accepted (relationship created), rejected = client declined';

