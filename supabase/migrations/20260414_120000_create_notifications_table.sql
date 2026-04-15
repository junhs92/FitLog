-- Migration: Create notifications table
-- Date: 2026-04-14
-- Purpose: Store system and user notifications for in-app notification center
-- Impact: Unblocks notifications_screen.dart and notification delivery system
-- Priority: P1 - CRITICAL (blocks notifications screen)

BEGIN;

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  -- Valid types: 'session_reminder' | 'session_complete' | 'report_ready' |
  --              'trainer_message' | 'client_log' | 'lifestyle_alert' |
  --              'achievement' | 'program_update'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ DEFAULT NULL
);

-- Create index for quick notification fetching
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users read their own notifications
CREATE POLICY "users_read_own_notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- RLS Policy: Users mark their own notifications as read
CREATE POLICY "users_update_own_notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- RLS Policy: Users delete their own notifications
CREATE POLICY "users_delete_own_notifications"
  ON notifications FOR DELETE
  USING (user_id = auth.uid());

-- Note: INSERT policy NOT set - only service role (Edge Functions) can insert notifications

-- Add comment for documentation
COMMENT ON TABLE notifications IS
  'System and user notifications. Only service role can insert (via Edge Functions). Users can read, update (mark as read), and delete their own.';

COMMENT ON COLUMN notifications.type IS
  'Notification type: session_reminder, session_complete, report_ready, trainer_message, client_log, lifestyle_alert, achievement, program_update';

COMMIT;
