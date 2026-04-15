# FitLog Pro Alignment Checklist

**Last Updated:** 2026-04-15
**Overall Status:** 🟡 IN PROGRESS

---

## Phase 1: Database Migrations
**Status:** ✅ COMPLETE — All 7 migrations applied to Supabase (2026-04-15)

- [x] 20260414_100000_add_no_show_status.sql
- [x] 20260414_110000_verify_rest_timer_seconds.sql
- [x] 20260414_120000_create_notifications_table.sql
- [x] 20260414_130000_create_notification_preferences_table.sql
- [x] 20260414_140000_create_user_fcm_tokens_table.sql
- [x] 20260414_150000_fix_session_packages_trigger.sql
- [x] 20260414_160000_add_unread_notification_count_rpc.sql
- [x] Duplicate migration files removed

---

## Phase 2: Frontend Critical Fixes
**Status:** ✅ COMPLETE

- [x] `SessionStatus.noShow` + `'no_show'` serialization — `session_entity.dart`
- [x] `restSeconds` field on `SessionEntity` / `SessionModel` / provider — reads `rest_timer_seconds` from DB
- [x] `SessionExerciseFeedbackEntity` + model + datasource methods
- [x] `ExerciseSwapHistoryEntity` + model + datasource methods
- [x] `SessionReportEntity` `pdfUrl` / `emailSentAt` / `pushSentAt` fields
- [x] `clientId` vs `user_id` resolved — `.eq('user_id', clientId)` in `client_profile_provider.dart:115` is correct

---

## Phase 3: Notification System
**Status:** 🟡 MOSTLY COMPLETE — 1 item remaining

- [x] `NotificationsScreen` fully built — list, mark-as-read, swipe-to-delete
- [x] `NotificationBadge` wired into `TrainerShell` (mobile: overlay; tablet: NavigationRail trailing)
- [x] Deep-link navigation in `NotificationsScreen._handleNotificationTap()`
- [x] `getUnreadCount()` updated to use `get_unread_notification_count` RPC
- [x] Notification service has `getPreferences()` / `updatePreferences()` methods
- [ ] **Notification preferences screen** — settings "알림 설정" currently navigates to the
      notifications list; needs a dedicated screen with toggles for each preference type
      (session reminders, report notifications, trainer messages, etc.)
      Service methods exist at `lib/core/services/notification_service.dart`

---

## Phase 4: Edge Function
**Status:** ⏳ BACKEND PENDING

- [ ] `send-push-notification` Edge Function (Owner: @Jass)

---

## Auth & Navigation Screens
**Status:** ✅ COMPLETE

- [x] `ForgotPasswordScreen` created + wired
- [x] `SettingsScreen` created + wired
- [x] `TrainerProfileScreen` created, replaces placeholder
- [x] `/client/record` `_getCurrentIndex` fix — highlights Today tab
- [x] All routes: `/notifications`, `/settings`, `/forgot-password` registered

---

## Data Integrity
**Status:** ✅ COMPLETE

- [x] Session packages trigger — FIFO oldest-first decrement
- [x] Duplicate migration files removed
- [x] `clientId` vs `user_id` column confirmed correct

---

## Remaining Work Summary

| Item | Owner | Blocked By |
|------|-------|-----------|
| Notification preferences screen | Frontend | Nothing — ready now |
| `send-push-notification` Edge Function | Backend | Nothing — ready now |

