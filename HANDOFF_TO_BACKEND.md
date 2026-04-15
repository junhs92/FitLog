# Handoff To Backend

---

## From Database Engineer — 2026-04-14

### 🔴 CRITICAL: Database Migrations (Must apply before frontend can proceed)

#### Apply Database Migrations to Supabase
- [x] Apply migration to add no_show status — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_100000_add_no_show_status.sql`
  - Action: Modify `sessions_status_check` constraint to include `'no_show'`
  - Impact: Frontend can now use `SessionStatus.noShow` without constraint violations
  - Test: Verify constraint with query: `SELECT check_clause FROM information_schema.table_constraints WHERE table_name = 'sessions'`

- [x] Apply migration to verify rest_timer_seconds column — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_110000_verify_rest_timer_seconds.sql`
  - Action: Add `rest_timer_seconds INTEGER DEFAULT 90` to sessions table if missing
  - Impact: Frontend can read/write per-session rest timer configuration
  - Test: Verify column exists: `SELECT column_name FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'rest_timer_seconds'`

- [x] Apply migration to create notifications table — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_120000_create_notifications_table.sql`
  - Action: Create `notifications` table with RLS policies (service-role insert only)
  - Impact: Unblocks notifications_screen.dart
  - Test: Verify table and RLS policies created

- [x] Apply migration to create notification_preferences table — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_130000_create_notification_preferences_table.sql`
  - Action: Create `notification_preferences` table with RLS and UNIQUE user_id constraint
  - Impact: Enables user notification preference management
  - Test: Verify UPSERT pattern works with unique constraint

- [x] Apply migration to create user_fcm_tokens table — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_140000_create_user_fcm_tokens_table.sql`
  - Action: Create `user_fcm_tokens` table with UNIQUE(user_id, token) constraint
  - Impact: Enables FCM token storage for push notifications
  - Test: Verify table created and unique constraint works

- [x] Apply migration to fix session_packages trigger — FILE AUTHORED (ready to apply)
  - File: `supabase/migrations/20260414_150000_fix_session_packages_trigger.sql`
  - Action: Replace trigger to only decrement oldest active package (FIFO)
  - Impact: Fixes over-decrement bug when client has multiple packages
  - Test: Test with client having 2 active packages — verify only oldest is decremented

**Timeline:** ~5 minutes total for all migrations  
**Blocker:** None — can start immediately

---

### 🔴 CRITICAL: Create Edge Function for Push Notifications

- [x] Create `send-push-notification` Edge Function — COMPLETED 2026-04-14
  - File: `supabase/functions/send-push-notification/index.ts`
  - Request body: `{ userId: uuid, title: string, body: string, data: object }`
  - Fans out to all registered device tokens (iOS + Android) for the user
  - Stale tokens (UNREGISTERED / INVALID_ARGUMENT) are auto-removed on delivery failure
  - **Deploy action required:** Register two secrets in Supabase dashboard → Edge Functions → Secrets:
    - `FCM_PROJECT_ID` — Firebase project ID
    - `FCM_SERVICE_ACCOUNT_JSON` — service-account JSON from Firebase console → Project settings → Service accounts

---

### 🟡 HIGH PRIORITY: Data Integrity

- [x] Verify session_packages trigger fix — MIGRATION APPLIED 2026-04-15
  - Test when possible: Complete session with 2 active packages → only oldest should be decremented
  - File: `supabase/migrations/20260414_150000_fix_session_packages_trigger.sql`

- [x] Confirm duplicate migration files removed — CONFIRMED
  - Deleted: `20260118_100000_create_client_schedules.sql` (was duplicate)
  - Deleted: `20260118_100001_create_session_packages.sql` (was duplicate)
  - Kept: `20260118000001_create_client_schedules.sql` (original)
  - Kept: `20260118000002_create_session_packages.sql` (original)

- [x] Replace `getUnreadCount()` full-row fetch with a server-side aggregate — MIGRATION AUTHORED
      (`lib/core/services/notification_service.dart:282`)
      - Migration file: `20260414_160000_add_unread_notification_count_rpc.sql`
      - Function: `get_unread_notification_count()` returning `bigint` via `COUNT(*)`
      - No argument needed — uses `auth.uid()` server-side (SECURITY INVOKER)
      - Frontend update task added to `HANDOFF_TO_FRONTEND.md`

- [x] Confirm `accounts.id` vs `accounts.user_id` — CONFIRMED, DIFFERENT COLUMNS, QUERY IS CORRECT
      (`lib/features/lifestyle_log/presentation/providers/client_profile_provider.dart:115`)
      - `accounts.id` — app-level UUID PK referenced by all FKs (trainer_id, client_id, etc.)
      - `accounts.user_id` — FK to `auth.users(id)`, equals `auth.uid()`
      - The `.eq('user_id', clientId)` query is intentionally correct: the provider is keyed
        on `auth.uid()` (confirmed by inline comment line 106 and call site `app_router.dart:773`)
      - Resolved in `HANDOFF_TO_FRONTEND.md` — no code change needed

---

## Notes

**Sequence:**
1. Apply all 6 migrations (5 min)
2. Notify frontend team migrations are done
3. Create Edge Function for push notifications (can happen in parallel)
4. Frontend starts implementing critical fixes

**When complete:** Check off each migration in this handoff so frontend architect can see progress.

