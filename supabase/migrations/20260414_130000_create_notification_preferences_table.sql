-- Migration: Create notification_preferences table
-- Date: 2026-04-14
-- Purpose: Store user's notification preference settings
-- Impact: Unblocks settings_screen.dart notification settings (알림 설정)
-- Priority: P1 - CRITICAL (blocks settings screen)

BEGIN;

-- Create notification_preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  session_reminders BOOLEAN NOT NULL DEFAULT true,
  report_notifications BOOLEAN NOT NULL DEFAULT true,
  trainer_messages BOOLEAN NOT NULL DEFAULT true,
  client_logs BOOLEAN NOT NULL DEFAULT true,
  achievements BOOLEAN NOT NULL DEFAULT true,
  marketing_emails BOOLEAN NOT NULL DEFAULT false,
  reminder_minutes_before INTEGER NOT NULL DEFAULT 60,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index for user lookup
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- Enable RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users manage their own preferences
CREATE POLICY "users_manage_own_preferences"
  ON notification_preferences FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Add comment for documentation
COMMENT ON TABLE notification_preferences IS
  'User notification preferences. Users can read/update/delete their own settings. Supports UPSERT operations.';

COMMENT ON COLUMN notification_preferences.reminder_minutes_before IS
  'Minutes before session to send reminder (e.g., 60 = 1 hour before)';

COMMIT;
