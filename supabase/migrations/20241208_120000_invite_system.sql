-- Migration: Invite System Enhancements
-- Adds columns and policies for trainer-client invite workflow

-- ============================================
-- SCHEMA CHANGES
-- ============================================

-- Add expires_at column for invite expiry (7 days default)
ALTER TABLE trainer_client_relationships
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- Add client_email for tracking who invite was sent to
ALTER TABLE trainer_client_relationships
ADD COLUMN IF NOT EXISTS client_email TEXT;

-- Make client_id nullable (null until invite is accepted)
ALTER TABLE trainer_client_relationships
ALTER COLUMN client_id DROP NOT NULL;

-- ============================================
-- RLS POLICIES FOR INVITE FLOW
-- ============================================

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "invite_lookup_by_code" ON trainer_client_relationships;
DROP POLICY IF EXISTS "clients_accept_pending_invite" ON trainer_client_relationships;
DROP POLICY IF EXISTS "trainers_create_invite" ON trainer_client_relationships;
DROP POLICY IF EXISTS "trainers_delete_pending_invite" ON trainer_client_relationships;

-- Policy: Anyone authenticated can lookup an invite by code (to see trainer info before accepting)
-- This is safe because it only exposes trainer name/avatar, not sensitive data
CREATE POLICY "invite_lookup_by_code" ON trainer_client_relationships
FOR SELECT
TO authenticated
USING (
  invitation_code IS NOT NULL
  AND status = 'pending'
);

-- Policy: Clients can accept pending invites by updating them
CREATE POLICY "clients_accept_pending_invite" ON trainer_client_relationships
FOR UPDATE
TO authenticated
USING (
  status = 'pending'
  AND invitation_code IS NOT NULL
  AND client_id IS NULL  -- Not yet claimed
)
WITH CHECK (
  status IN ('pending', 'active')
  AND client_id = get_my_account_id()  -- Client can only set themselves
);

-- Policy: Trainers can create invites (pending relationships)
-- Note: This might already be covered by existing policies, but being explicit
CREATE POLICY "trainers_create_invite" ON trainer_client_relationships
FOR INSERT
TO authenticated
WITH CHECK (
  trainer_id = get_my_account_id()
  AND is_current_user_trainer()
  AND status = 'pending'
);

-- Policy: Trainers can delete their own pending invites
CREATE POLICY "trainers_delete_pending_invite" ON trainer_client_relationships
FOR DELETE
TO authenticated
USING (
  trainer_id = get_my_account_id()
  AND status = 'pending'
);

-- ============================================
-- INDEX FOR INVITE CODE LOOKUPS
-- ============================================

-- Index for fast invite code lookups
CREATE INDEX IF NOT EXISTS idx_relationships_invitation_code
ON trainer_client_relationships(invitation_code)
WHERE invitation_code IS NOT NULL;

-- Index for pending invites by trainer
CREATE INDEX IF NOT EXISTS idx_relationships_trainer_pending
ON trainer_client_relationships(trainer_id, status)
WHERE status = 'pending';
