-- Migration: Add server-side RPC for unread notification count
-- Date: 2026-04-14
-- Purpose: Replace client-side full-row fetch with a COUNT(*) aggregate on the server.
--          The current implementation in notification_service.dart:282 fetches all unread
--          rows and measures (response as List).length in Dart — wasteful at scale.
-- Impact:  Reduces data transfer from O(N rows) to O(1) bigint response.
--          Frontend must update getUnreadCount() to call rpc('get_unread_notification_count').
-- Notify: frontend-architect — update notification_service.dart:getUnreadCount() to use RPC

BEGIN;

-- Create the aggregate RPC function
-- Callable as: supabase.rpc('get_unread_notification_count')
-- RLS is enforced inside the function via the auth.uid() check,
-- ensuring callers can only count their own notifications.
CREATE OR REPLACE FUNCTION get_unread_notification_count()
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT COUNT(*)::bigint
  FROM notifications
  WHERE user_id = auth.uid()
    AND is_read = false;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_unread_notification_count() TO authenticated;

-- Add documentation comment
COMMENT ON FUNCTION get_unread_notification_count() IS
  'Returns the count of unread notifications for the currently authenticated user. '
  'Uses SECURITY INVOKER so RLS on the notifications table is fully enforced. '
  'Replaces the client-side full-row fetch pattern in notification_service.dart.';

COMMIT;
