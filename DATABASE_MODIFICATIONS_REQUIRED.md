# 🗄️ Database Modifications Required - Backend Changes

**Document Date:** 2026-04-14  
**For:** Database/Backend Engineer  
**Priority:** 1 Critical + 1 High (blocking issues)  
**Estimated Effort:** 1-2 hours total  

---

## 📋 SUMMARY

Backend analysis identified **2 required database changes** to align with frontend implementation:

| Priority | Change | Status | Impact | Effort |
|----------|--------|--------|--------|--------|
| 🔴 CRITICAL | Add `no_show` to session status constraint | To Do | Frontend crash if used | 0.5h |
| 🟡 HIGH | Verify `rest_timer_seconds` column exists | To Do | Feature unusable from frontend | 0.5h |

---

## ✅ Overall Checklist

- [ ] `no_show` status constraint applied
- [ ] `rest_timer_seconds` column verified / added
- [ ] `notifications` table + RLS created
- [ ] `notification_preferences` table + RLS created
- [ ] `user_fcm_tokens` table + RLS created
- [ ] `send-push-notification` Edge Function deployed
- [ ] `clientId` vs `user_id` investigation resolved
- [ ] Session packages trigger fixed (oldest-first decrement)
- [ ] Duplicate migration files removed
- [ ] Frontend team notified of completion

---

## 🔴 CRITICAL: Add `no_show` Status to Session Constraint

**Problem:**
```sql
-- Current constraint:
CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'))

-- Frontend tries to use:
status = 'no_show'  ❌ REJECTED by constraint

-- Result:
INSERT/UPDATE fails → App crashes with constraint violation
```

**Current Constraint Location:**
```sql
-- In sessions table:
ALTER TABLE sessions 
  ADD CONSTRAINT sessions_status_check 
  CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'));
```

**Fix:**

Create migration file: `supabase/migrations/[timestamp]_add_no_show_status.sql`

```sql
-- Drop the old constraint
ALTER TABLE sessions 
  DROP CONSTRAINT sessions_status_check;

-- Add new constraint with no_show
ALTER TABLE sessions 
  ADD CONSTRAINT sessions_status_check 
  CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled', 'no_show'));

-- Update RLS policy comment if needed (for clarity)
COMMENT ON CONSTRAINT sessions_status_check ON sessions IS 
  'Valid session statuses: scheduled, active, completed, cancelled, no_show';
```

**How to apply:**
1. Create the migration file above
2. Run via Supabase dashboard: SQL Editor → paste → Execute
3. Verify constraint exists: `\d sessions` (in psql)
4. Test: Try inserting `status = 'no_show'` → should succeed

**Testing:**
```sql
-- Verify the constraint accepts no_show:
INSERT INTO sessions (id, trainer_id, client_id, status, created_at)
VALUES ('test-id', 'trainer-id', 'client-id', 'no_show', NOW());

-- Should succeed. Cleanup:
DELETE FROM sessions WHERE id = 'test-id';
```

**Frontend — already implemented (no frontend work needed):**

| File | What was done |
|---|---|
| `lib/features/active_session/domain/entities/session_entity.dart:9` | `noShow` case added to `SessionStatus` enum |
| `lib/features/active_session/domain/entities/session_entity.dart:23` | `displayName` returns `'No Show'` |
| `lib/features/active_session/data/models/session_model.dart:50–51` | `fromJson` reads `'no_show'` → `SessionStatus.noShow` |
| `lib/features/active_session/data/models/session_model.dart:126–127` | `_statusToString` serializes `noShow` → `'no_show'` |
| `lib/features/active_session/data/datasources/session_remote_datasource.dart:910–911` | Datasource status helper maps `noShow` → `'no_show'` |

Once the DB constraint is updated, the frontend will work automatically — no code changes needed.

**Checklist:**
- [ ] Migration file `20260414_add_no_show_status.sql` created
- [ ] Migration applied — no errors
- [ ] Constraint verified via `information_schema` query
- [ ] Test INSERT with `status = 'no_show'` succeeds and cleaned up
- [ ] Frontend team notified

---

## 🟡 HIGH: Verify `rest_timer_seconds` Column Exists

**Problem:**
Frontend code assumes `sessions.rest_timer_seconds` column exists and has default value.

**Column Requirements:**
```sql
-- Column should be:
rest_timer_seconds INTEGER DEFAULT 90

-- Location:
sessions table
```

**Verification:**

```sql
-- Check if column exists and has correct type:
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'sessions' 
  AND column_name = 'rest_timer_seconds';

-- Expected output:
-- column_name          | data_type | column_default
-- rest_timer_seconds   | integer   | 90
```

**If column is missing:**

Create migration: `supabase/migrations/[timestamp]_add_rest_timer_seconds.sql`

```sql
ALTER TABLE sessions
  ADD COLUMN rest_timer_seconds INTEGER DEFAULT 90;

-- Add comment for clarity
COMMENT ON COLUMN sessions.rest_timer_seconds IS 
  'Default rest duration in seconds between sets (per session)';
```

**If column exists but doesn't have default:**

```sql
ALTER TABLE sessions
  ALTER COLUMN rest_timer_seconds SET DEFAULT 90;
```

**Testing:**
```sql
-- Insert session without specifying rest_timer_seconds
INSERT INTO sessions (id, trainer_id, client_id, status, created_at)
VALUES ('test-id', 'trainer-id', 'client-id', 'scheduled', NOW())
RETURNING id, rest_timer_seconds;

-- Should return rest_timer_seconds = 90 (default)
```

**Why Frontend Needs This:**
- Frontend SessionEntity has field: `restSeconds`
- Queries expect this column in SELECT results
- Used by rest timer widget to show correct duration
- Can be customized per session by trainer

**Checklist:**
- [ ] Verified `rest_timer_seconds` column exists on `sessions` table
- [ ] If missing: migration file created and applied
- [ ] If missing default: `ALTER COLUMN ... SET DEFAULT 90` applied
- [ ] Test INSERT without `rest_timer_seconds` defaults to 90
- [ ] Frontend team notified

---

## 📋 MIGRATION CHECKLIST

### Step 1: Create Migration Files

```bash
cd supabase
# Create two new migration files:
# - 20260414_add_no_show_status.sql
# - 20260414_verify_rest_timer_column.sql
```

### Step 2: Write Migration SQL

Copy the SQL from sections above into respective files.

### Step 3: Apply via Supabase Dashboard

1. Go to Supabase Dashboard → SQL Editor
2. Copy migration content
3. Execute
4. Verify no errors

### Step 4: Verify in Production

```sql
-- Verify no_show status is accepted:
SELECT constraint_name, check_clause
FROM information_schema.table_constraints
WHERE table_name = 'sessions'
  AND constraint_name = 'sessions_status_check';

-- Verify rest_timer_seconds column exists:
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'sessions'
  AND column_name = 'rest_timer_seconds';
```

### Step 5: Document Changes

Update project migration log with:
- Migration timestamp
- What changed
- Why (frontend alignment)
- Tested date

---

## 🔒 RLS Policy Review

**No RLS changes needed** — both columns already covered by existing policies.

Current RLS for sessions table:
```sql
-- Trainers can read/write own sessions
CREATE POLICY "trainer_sessions" 
  ON sessions FOR ALL 
  USING (trainer_id = auth.uid());

-- Clients can read own sessions
CREATE POLICY "client_sessions" 
  ON sessions FOR SELECT 
  USING (client_id = auth.uid());
```

Both work for `status` and `rest_timer_seconds` columns without changes.

---

## ✅ Validation Checklist

After applying migrations:

- [ ] Migration files created in `supabase/migrations/`
- [ ] Both migrations applied successfully via dashboard
- [ ] No errors in Supabase logs
- [ ] `sessions_status_check` constraint includes `'no_show'`
- [ ] `rest_timer_seconds` column exists with type INTEGER
- [ ] `rest_timer_seconds` has default value of 90
- [ ] RLS policies still work correctly
- [ ] Test INSERT with `status = 'no_show'` succeeds
- [ ] Test INSERT without `rest_timer_seconds` defaults to 90
- [ ] Notify frontend team migrations are applied

---

## 🔗 Related Schema References

**Current Sessions Table:**
```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY,
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'scheduled',
    -- ✓ Will be updated to include 'no_show'
  rest_timer_seconds INTEGER DEFAULT 90,
    -- ✓ Verify this exists
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  -- ... other columns
  CONSTRAINT sessions_status_check 
    CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'))
    -- ✓ Will be updated to include 'no_show'
);
```

---

## 📞 Communication

**Notify Frontend Team When:**
1. ✅ Migration `20260414_add_no_show_status.sql` is applied
   - They can now serialize `SessionStatus.noShow` successfully

2. ✅ Migration `20260414_verify_rest_timer_column.sql` is verified
   - They can include `rest_timer_seconds` in session queries

**Expected Timeline:**
- Migrations: 30 minutes
- Testing: 15 minutes
- Total: **~45 minutes**

---

## ❓ Rollback Plan (if needed)

If migrations need to be rolled back:

```sql
-- Rollback no_show status:
ALTER TABLE sessions 
  DROP CONSTRAINT sessions_status_check;
ALTER TABLE sessions 
  ADD CONSTRAINT sessions_status_check 
  CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'));

-- Rollback rest_timer_seconds (if needed):
ALTER TABLE sessions
  DROP COLUMN rest_timer_seconds;
```

However, **no rollback expected** — these are safe, additive changes.

---

**Document prepared by:** Backend Architect Agent
**For:** Database/Backend Engineer
**Status:** Ready for implementation
**Blocker for Frontend:** Yes - Frontend launch depends on these changes

---

---

# Additional Database Changes Required (Frontend Team Audit)

**Added:** 2026-04-14
**Source:** Frontend connectivity audit of existing screens

---

## P1 — Notification System Tables (Screens are broken without these)

### 1. `notifications` Table

**Screen affected:** `lib/shared/screens/notifications_screen.dart`
**Provider:** `notificationsProvider` in `lib/core/services/notification_service.dart`

All reads/writes fail silently — screen shows empty state permanently.

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  -- Valid types: 'session_reminder' | 'session_complete' | 'report_ready' |
  --              'trainer_message' | 'client_log' | 'lifestyle_alert' |
  --              'achievement' | 'program_update'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at TIMESTAMPTZ
);
```

**RLS policies:**
```sql
-- Users read their own notifications
CREATE POLICY "users_read_own_notifications"
  ON notifications FOR SELECT USING (user_id = auth.uid());

-- Users mark their own notifications as read
CREATE POLICY "users_update_own_notifications"
  ON notifications FOR UPDATE USING (user_id = auth.uid());

-- Users delete their own notifications
CREATE POLICY "users_delete_own_notifications"
  ON notifications FOR DELETE USING (user_id = auth.uid());

-- Only service role can insert (notifications created by system/Edge Functions)
-- No INSERT policy for authenticated users
```

---

### 2. `notification_preferences` Table

**Screen affected:** `lib/shared/screens/settings_screen.dart` → 알림 설정

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

**RLS policies:**
```sql
-- Users manage their own preferences
CREATE POLICY "users_manage_own_preferences"
  ON notification_preferences FOR ALL USING (user_id = auth.uid());
```

Note: App uses UPSERT — ensure `ON CONFLICT (user_id) DO UPDATE` is supported by the unique constraint.

**Checklist:**
- [ ] `notifications` table created
- [ ] All 4 RLS policies applied (SELECT, UPDATE, DELETE for owner; no INSERT for users)
- [ ] Test SELECT returns empty list for new user (not an error)
- [ ] Test INSERT via service role succeeds

**Checklist:**
- [ ] `notification_preferences` table created
- [ ] RLS policy applied
- [ ] UPSERT ON CONFLICT works correctly
- [ ] Test: first-time fetch returns defaults (no row needed)

---

### 3. `user_fcm_tokens` Table

**Used by:** `NotificationService._saveFcmToken()` in `lib/core/services/notification_service.dart`

Without this table, FCM token saves fail silently and push notifications cannot be delivered to any user.

```sql
CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'mobile',  -- 'ios' | 'android' | 'web'
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, token)
);
```

**RLS policies:**
```sql
-- Users manage their own FCM tokens
CREATE POLICY "users_manage_own_fcm_tokens"
  ON user_fcm_tokens FOR ALL USING (user_id = auth.uid());
```

**Checklist:**
- [ ] `user_fcm_tokens` table created
- [ ] RLS policy applied
- [ ] UPSERT ON CONFLICT `(user_id, token)` works correctly

---

## P1 — Missing Edge Function

### 4. `send-push-notification` Edge Function

**Called by:** `NotificationService.sendReportReadyNotification()` at `lib/core/services/notification_service.dart:352`

Currently wrapped in try/catch and fails silently. Push alerts to clients after session completion never fire.

**Expected request body:**
```json
{
  "userId": "uuid",
  "title": "string",
  "body": "string",
  "data": { "type": "report_ready", "session_id": "uuid" }
}
```

**What it should do:**
1. Look up user's FCM token from `user_fcm_tokens` WHERE `user_id = userId`
2. Call Firebase Cloud Messaging HTTP v1 API with the token
3. Return 200 on success

Note: Firebase Messaging SDK setup in the Flutter app is commented out in `notification_service.dart:156–169` pending this Edge Function.

**Checklist:**
- [ ] Edge Function `send-push-notification` created in `supabase/functions/`
- [ ] FCM credentials configured in Supabase secrets
- [ ] Edge Function deployed
- [ ] Test call with a valid `userId` delivers a push notification
- [ ] Frontend team notified — they will uncomment Firebase SDK setup

---

## P2 — Data Integrity

### 5. `clientId` vs `user_id` in `client_profile_provider.dart`

**File:** `lib/features/lifestyle_log/presentation/providers/client_profile_provider.dart:115`

All providers in the app treat `clientId` as `accounts.id`. But this query uses `.eq('user_id', clientId)` — treating it as the Supabase Auth UUID instead. One of them is wrong.

**Action needed:** Confirm whether `accounts.id == accounts.user_id` in your schema. If they are different columns, fix the query to use the correct one.

**Checklist:**
- [ ] Confirmed whether `accounts.id` == `accounts.user_id` in the schema
- [ ] If different: notified frontend team with the correct column to use
- [ ] Frontend team updated `client_profile_provider.dart:115` if needed

---

## P3 — Data Integrity (Before Production)

### 6. Session packages trigger — multi-package over-decrement

**Migration:** `supabase/migrations/20260123_100000_auto_increment_sessions_used.sql`

The trigger `trigger_increment_sessions_used` decrements **all** active packages simultaneously on session completion. If a client has >1 active package, all of them get decremented.

**Fix — decrement oldest-first only:**
```sql
-- Replace the trigger body with:
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

### 7. Duplicate migration files — deployment hazard

Two pairs of files define the same tables:

| Table | Keep | Remove |
|---|---|---|
| `client_schedules` | `20260118000001_create_client_schedules.sql` | `20260118_100000_create_client_schedules.sql` |
| `session_packages` | `20260118000002_create_session_packages.sql` | `20260118_100001_create_session_packages.sql` |

If both are applied to a fresh Supabase project the second will fail with "table already exists". Delete the `_100000` / `_100001` variants.

**Checklist:**
- [ ] `exercise_swap_history` trigger updated — only decrements oldest active package
- [ ] Tested: client with 2 active packages — only one is decremented per session

**Checklist:**
- [ ] `20260118_100000_create_client_schedules.sql` deleted
- [ ] `20260118_100001_create_session_packages.sql` deleted
- [ ] Verified remaining migrations apply cleanly on a fresh project

---

**Added by:** Frontend Team
**Priority:** P1 items block notification screen; P2/P3 are data integrity concerns before production launch
