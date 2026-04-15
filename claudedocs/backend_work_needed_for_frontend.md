# Backend Work Required for Frontend Screens

> **Created:** 2026-04-14
> **Author:** Frontend team audit
> **For:** Backend Architect
> **Priority order:** P1 = blocks a working screen, P2 = degrades a working screen, P3 = data integrity risk

---

## Summary

The following frontend screens exist and are routed, but will silently fail, show empty states, or crash at runtime because the required database tables, RLS policies, or Edge Functions do not exist yet.

---

## P1 — Blocks a Working Screen

### 1. `notifications` table (missing migration)

**Screen affected:** `lib/shared/screens/notifications_screen.dart`
**Provider:** `notificationsProvider` in `lib/core/services/notification_service.dart:422`

The `NotificationService` queries a `notifications` table that has no migration file. All reads and writes will fail silently (the provider catches errors and returns empty list).

**Required table schema:**
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,  -- maps to NotificationType enum: 'session_reminder' | 'session_complete' | 'report_ready' | 'trainer_message' | 'client_log' | 'lifestyle_alert' | 'achievement' | 'program_update'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);
```

**RLS policies needed:**
- Users can only SELECT their own notifications (`user_id = auth.uid()`)
- Users can UPDATE their own notifications to mark as read
- Users can DELETE their own notifications
- INSERT is restricted to service role (notifications are created by the system/Edge Functions, not the user directly)

---

### 2. `notification_preferences` table (missing migration)

**Screen affected:** `lib/shared/screens/settings_screen.dart` → 알림 설정 → `NotificationsScreen`
**Provider:** `notificationPreferencesProvider` in `lib/core/services/notification_service.dart:434`

The `NotificationService.getPreferences()` and `updatePreferences()` methods query a `notification_preferences` table that has no migration.

**Required table schema:**
```sql
CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  session_reminders BOOLEAN NOT NULL DEFAULT true,
  report_notifications BOOLEAN NOT NULL DEFAULT true,
  trainer_messages BOOLEAN NOT NULL DEFAULT true,
  client_logs BOOLEAN NOT NULL DEFAULT true,
  achievements BOOLEAN NOT NULL DEFAULT true,
  marketing_emails BOOLEAN NOT NULL DEFAULT false,
  reminder_minutes_before INT NOT NULL DEFAULT 60,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**RLS policies needed:**
- Users can SELECT, INSERT, UPDATE their own row (`user_id = auth.uid()`)
- Use `UPSERT` in the app — ensure `ON CONFLICT (user_id) DO UPDATE` works

---

### 3. `user_fcm_tokens` table (missing migration)

**Used by:** `NotificationService._saveFcmToken()` in `lib/core/services/notification_service.dart:178`

This table stores Firebase Cloud Messaging tokens for push notification delivery. Without it, FCM token saves fail silently and push notifications cannot be targeted.

**Required table schema:**
```sql
CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'mobile',  -- 'ios' | 'android' | 'web' | 'mobile'
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, token)
);
```

**RLS policies needed:**
- Users can SELECT, INSERT, UPDATE their own tokens (`user_id = auth.uid()`)
- Use `UPSERT` on `(user_id, token)` conflict key

---

## P1 — Missing Edge Function

### 4. `send-push-notification` Edge Function (not created)

**Called by:** `NotificationService.sendReportReadyNotification()` at `lib/core/services/notification_service.dart:352`

Currently the call is wrapped in a try/catch and fails silently. Push notifications to clients after session completion will never fire.

**What it needs to do:**
- Accept `{ userId, title, body, data }` in request body
- Look up the user's FCM token from `user_fcm_tokens`
- Call Firebase Cloud Messaging HTTP v1 API to send the push
- Return 200 on success, 4xx on bad input

**Note:** Firebase Messaging SDK setup in the Flutter app is also currently commented out in `notification_service.dart:156–169`. Frontend will wire it up once the Edge Function and FCM project credentials are in place.

---

## P2 — Degrades a Working Screen

### 5. `clientId` vs `user_id` inconsistency in `client_profile_provider.dart`

**Screen affected:** `lib/features/lifestyle_log/presentation/screens/client_profile_screen.dart`
**File:** `lib/features/lifestyle_log/presentation/providers/client_profile_provider.dart:115`

All providers in the app treat `clientId` as `accounts.id` (the app-level UUID). However, the `clientProfileProvider` at line 115 queries:
```dart
.eq('user_id', clientId)
```
This treats `clientId` as the Supabase Auth `user_id` UUID — a different value.

**Decision needed from backend architect:**
- Confirm which ID is correct: `accounts.id` or `auth.users.id`
- Check if `accounts.user_id` == `accounts.id` (some setups use the same UUID for both)
- If they differ, fix the query in `client_profile_provider.dart:115` to match the correct column

---

## P3 — Data Integrity Risk

### 6. Session packages trigger decrements ALL active packages simultaneously

**Migration file:** `supabase/migrations/20260123_100000_auto_increment_sessions_used.sql`

The trigger `trigger_increment_sessions_used` fires on `sessions` status change to `'completed'` and runs:
```sql
WHERE client_id = NEW.client_id
  AND is_active = true
  AND sessions_used < total_sessions
```

If a client has more than one active package, **all** of them get decremented. The application-side `getActivePackage()` uses "oldest first" ordering, but the trigger has no such ordering.

**Fix:** Update the trigger to only decrement the single oldest active package:
```sql
-- Decrement only the oldest active package
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
```

---

## P3 — Deployment Hazard

### 7. Duplicate migration files for `client_schedules` and `session_packages`

Two pairs of migration files define the same tables with only comment/whitespace differences. If applied in sequence to a fresh Supabase project, the second file in each pair will fail with "table already exists" or trigger conflict errors.

**Duplicates to resolve:**

| Table | File A (keep) | File B (remove or guard with IF NOT EXISTS) |
|---|---|---|
| `client_schedules` | `20260118000001_create_client_schedules.sql` | `20260118_100000_create_client_schedules.sql` |
| `session_packages` | `20260118000002_create_session_packages.sql` | `20260118_100001_create_session_packages.sql` |

**Recommended fix:** Delete the `_100000` / `_100001` variants (they appear to be re-exports), keeping the `000001` / `000002` numbered variants which have cleaner sequential ordering.

---

## Not a Backend Issue (for completeness)

| Item | Status |
|---|---|
| Forgot password email flow | ✅ Works via Supabase Auth built-in — no custom backend needed |
| `trainer_messages` table | ✅ Migration exists (`20241208_100000_create_sessions_messages.sql`) |
| `client_schedules` table | ✅ Migration exists (see duplicate issue above) |
| `session_packages` table | ✅ Migration exists (see duplicate issue above) |
| Session completion decrement | ✅ DB trigger exists — but see P3 multi-package issue |
| All client screen provider wiring | ✅ Connected to real Supabase queries |
| Trainer profile `clientsProvider` | ✅ Uses existing `client_management` datasource |

---

## Quick Priority Checklist

```
P1 — Do these first (screens are broken without them):
[ ] Create migrations: notifications, notification_preferences, user_fcm_tokens
[ ] Add RLS policies for all three tables
[ ] Create send-push-notification Edge Function

P2 — Do these next (screens work but show wrong data):
[ ] Investigate and fix clientId vs user_id in client_profile_provider.dart:115

P3 — Do these before production (data integrity):
[ ] Fix session_packages trigger to decrement oldest-first only
[ ] Remove duplicate migration files for client_schedules and session_packages
```
