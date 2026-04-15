# Backend Architect Progress

_Last updated: 2026-04-14 (Edge Function added)_

---

## ✅ Completed Work

- [x] Authored migration `20260414_120000_create_notifications_table.sql`
  - `notifications` table: UUID PK, `user_id` FK → `auth.users` CASCADE,
    `type TEXT`, `title TEXT`, `body TEXT`, `data JSONB`,
    `is_read BOOLEAN DEFAULT false`, `created_at TIMESTAMPTZ`, `read_at TIMESTAMPTZ`
  - Indexes: `(user_id)`, composite `(user_id, is_read)` for unread-count queries,
    `(created_at DESC)` for feed ordering
  - RLS: users SELECT / UPDATE / DELETE own rows only; INSERT blocked for users —
    only service role (Edge Functions) may insert, preventing client-side spoofing
  - Resolves all items from the Frontend Architect handoff for this table

- [x] Authored migration `20260414_130000_create_notification_preferences_table.sql`
  - `notification_preferences` table: `user_id UNIQUE` (one row per user, UPSERT-safe),
    boolean flags matching `NotificationPreferences.toJson()` in
    `lib/core/services/notification_service.dart`, `reminder_minutes_before INTEGER DEFAULT 60`
  - RLS: full CRUD for own row only
  - Resolves Frontend Architect handoff item for this table

- [x] Authored migration `20260414_140000_create_user_fcm_tokens_table.sql`
  - Supports `NotificationService._saveFcmToken()` at
    `lib/core/services/notification_service.dart:178`
  - Resolves Frontend Architect handoff item for this table

- [x] Verified query patterns in `notification_service.dart` match the authored schema:
  - `getUnreadCount()` filtered SELECT on `(user_id, is_read)` — covered by composite index
  - `markAllAsRead()` UPDATE constrained to own `user_id` — matches RLS
  - `sendNotification()` INSERT — service-role only; client-side call in the service
    needs an Edge Function wrapper before production (TODO already noted in source at line 210)

- [x] While reviewing TrainerShell (`lib/navigation/app_router.dart:430`), identified that
  `NotificationBadge` (defined and complete in `lib/shared/screens/notifications_screen.dart:278`,
  watching `unreadNotificationCountProvider`) is not yet rendered anywhere in the trainer shell
  navigation bar — handed off to Frontend Architect (see below)

- [x] Authored migration `20260414_100000_add_no_show_status.sql`
  - Drops old `sessions_status_check` constraint, recreates with `'no_show'` included
  - Valid set: `scheduled | active | completed | cancelled | no_show`

- [x] Authored migration `20260414_110000_verify_rest_timer_seconds.sql`
  - `ADD COLUMN IF NOT EXISTS rest_timer_seconds INTEGER DEFAULT 90` on `sessions`
  - Back-fills NULL rows, then applies NOT NULL

- [x] Authored migration `20260414_150000_fix_session_packages_trigger.sql`
  - Drops and recreates `increment_sessions_used()` trigger function
  - New logic: on `sessions.status → 'completed'`, update only the oldest active
    package for that `client_id` (FIFO via `ORDER BY created_at ASC LIMIT 1`)
  - Prevents over-decrement when client has multiple active packages

- [x] Authored migration `20260414_160000_add_unread_notification_count_rpc.sql`
  - Postgres function `get_unread_notification_count()` returning `bigint`
  - SECURITY INVOKER (RLS on `notifications` table applies to the caller)
  - `GRANT EXECUTE TO authenticated`; no argument — uses `auth.uid()` server-side
  - Frontend update task added to `HANDOFF_TO_FRONTEND.md`

- [x] Verified `20260414_150000_fix_session_packages_trigger.sql` does not touch
  `notifications` table — it exclusively operates on `sessions` and `session_packages`

- [x] Confirmed duplicate migration files removed from `supabase/migrations/`:
  - `20260118_100000_create_client_schedules.sql` — absent (correctly removed)
  - `20260118_100001_create_session_packages.sql` — absent (correctly removed)
  - Originals `20260118000001_` and `20260118000002_` remain

- [x] Resolved `accounts.id` vs `accounts.user_id` question
  - These are two distinct columns on the `accounts` table
  - `accounts.id` — app-level UUID PK (used in all FKs)
  - `accounts.user_id` — FK to `auth.users(id)`, equals `auth.uid()` at runtime
  - `client_profile_provider.dart:115` query `.eq('user_id', clientId)` is correct;
    the provider is intentionally keyed on the auth UID
  - No code change needed; resolved in `HANDOFF_TO_FRONTEND.md`

---

## ⏳ Pending / In Progress

- [x] Create Edge Function `send-push-notification` — AUTHORED 2026-04-14
  - File: `supabase/functions/send-push-notification/index.ts`
  - Accepts `{ userId, title, body, data }` — matches call site at `notification_service.dart:346`
  - Reads all FCM tokens for the user from `user_fcm_tokens` (service-role, bypasses RLS)
  - Graceful no-op when user has no tokens (returns 200 + `skipped: true`)
  - Fan-out to all registered devices (a user may have both iOS and Android tokens)
  - Obtains short-lived Google OAuth2 access token via RS256 JWT + token exchange
    (uses `FCM_SERVICE_ACCOUNT_JSON` env var — no third-party FCM library required)
  - Calls FCM HTTP v1 API: `https://fcm.googleapis.com/v1/projects/{FCM_PROJECT_ID}/messages:send`
  - Auto-removes stale tokens (FCM error codes UNREGISTERED / INVALID_ARGUMENT)
  - Required environment variables (set in Supabase dashboard → Edge Functions → Secrets):
    - `FCM_PROJECT_ID` — Firebase project ID
    - `FCM_SERVICE_ACCOUNT_JSON` — full service-account JSON from Firebase console
    - `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` — auto-injected by runtime

- [x] Applied all 7 migration files to Supabase dashboard — 2026-04-15
  1. `20260414_100000_add_no_show_status.sql` ✅
  2. `20260414_110000_verify_rest_timer_seconds.sql` ✅
  3. `20260414_120000_create_notifications_table.sql` ✅
  4. `20260414_130000_create_notification_preferences_table.sql` ✅
  5. `20260414_140000_create_user_fcm_tokens_table.sql` ✅
  6. `20260414_150000_fix_session_packages_trigger.sql` ✅
  7. `20260414_160000_add_unread_notification_count_rpc.sql` ✅

---

## 🔁 Handoff from Frontend Architect

_Discovered during: router audit on 2026-04-14 — reviewing `NotificationsScreen` data dependencies_

- [x] Create `notifications` table — COMPLETED (see above)
- [x] Create `notification_preferences` table — COMPLETED (see above)
- [x] Create `user_fcm_tokens` table — COMPLETED (see above)
- [x] Create Edge Function `send-push-notification` — COMPLETED (see Completed section above)

_Source files for context:_
- `lib/core/services/notification_service.dart`
- `lib/shared/screens/notifications_screen.dart`
- `lib/navigation/app_router.dart` (route registered at line 106-110)

---

> Tasks assigned to other agents are tracked in their respective handoff files.
> Frontend tasks → **`HANDOFF_TO_FRONTEND.md`** | Backend tasks → **`HANDOFF_TO_BACKEND.md`**
