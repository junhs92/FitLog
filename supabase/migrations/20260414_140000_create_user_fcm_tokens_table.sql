-- Migration: Create user_fcm_tokens table
-- Date: 2026-04-14
-- Purpose: Store Firebase Cloud Messaging tokens for push notifications
-- Impact: Unblocks push notification delivery to users
-- Priority: P1 - CRITICAL (push notifications don't work without this)

BEGIN;

-- Create user_fcm_tokens table
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'mobile',
  -- Valid platforms: 'ios' | 'android' | 'web'
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, token)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_platform ON user_fcm_tokens(platform);

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users manage their own FCM tokens
CREATE POLICY "users_manage_own_fcm_tokens"
  ON user_fcm_tokens FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Add comment for documentation
COMMENT ON TABLE user_fcm_tokens IS
  'Firebase Cloud Messaging tokens for push notification delivery. Users can manage their own tokens across multiple devices.';

COMMENT ON COLUMN user_fcm_tokens.platform IS
  'Device platform: ios, android, or web. Allows per-platform notification configuration.';

COMMIT;
