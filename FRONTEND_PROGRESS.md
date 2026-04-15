# Frontend Architect Progress

_Last updated: 2026-04-14_

---

## ✅ Completed Work

- [x] Audited `lib/navigation/app_router.dart` and `lib/navigation/routes.dart` for shell registration issues
- [x] Audited `lib/shared/screens/notifications_screen.dart` and `lib/core/services/notification_service.dart` for data dependency gaps
- [x] Confirmed `/client/record` (`Routes.clientRecord`) is already declared **inside** the `ClientShell` `ShellRoute` — the bottom nav bar renders correctly for this route (no missing-shell bug)
- [x] Identified active UX defect: `ClientShell._getCurrentIndex()` has no branch for `Routes.clientRecord` (`/client/record`), so the bottom nav highlights "Today" (index 0) instead of no tab or a dedicated tab while the record screen is active
- [x] Added `noShow` to `SessionStatus` enum with correct DB serialization `'no_show'` — `lib/features/active_session/domain/entities/session_entity.dart`
- [x] Added `restSeconds` field to `SessionEntity` and `SessionModel`; provider now reads from `session.restSeconds` instead of hardcoded 90
- [x] Created `SessionExerciseFeedbackEntity` and `SessionExerciseFeedbackModel` with datasource methods (`getFeedbackForSessionExercise`, `submitExerciseFeedback`)
- [x] Created `ExerciseSwapHistoryEntity` and `ExerciseSwapHistoryModel` with datasource methods (`getSwapHistoryForClient`, `logExerciseSwap`)
- [x] Added `pdfUrl`, `emailSentAt`, `pushSentAt` to `SessionReportEntity` and `SessionReportModel`
- [x] Created `TrainerProfileScreen` — `lib/features/trainer_home/presentation/screens/trainer_profile_screen.dart`
- [x] Created `ForgotPasswordScreen` — `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- [x] Created `SettingsScreen` — `lib/shared/screens/settings_screen.dart`
- [x] Added `resetPassword()` to `AuthNotifier`; wired "비밀번호를 잊으셨나요?" button on login screen
- [x] Wired `/notifications`, `/settings`, `/forgot-password` routes in `app_router.dart`
- [x] Replaced `TrainerProfilePlaceholder` with `TrainerProfileScreen` in router
- [x] Fixed `ClientShell._getCurrentIndex()` — added explicit guard for `/client/record` → highlights Today (index 0)
- [x] Wired `NotificationBadge` into `TrainerShell` — mobile: Stack/Positioned overlay top-right; tablet: `NavigationRail` trailing
- [x] Implemented deep-link navigation in `NotificationsScreen._handleNotificationTap()` — `report_ready`/`session_complete`/`achievement` route to `clientSessionReport`
- [x] Updated `getUnreadCount()` to use `get_unread_notification_count` RPC — `lib/core/services/notification_service.dart`

---

## ⏳ Pending / In Progress

- [ ] Verify `NotificationsScreen` compiles cleanly after DB migrations are applied — pending Supabase migration run by backend

---

## Notes

> Tasks assigned to this agent by other agents are tracked in **`HANDOFF_TO_FRONTEND.md`** at the project root.



**`/client/record` shell placement** — confirmed correct as of this audit. The route sits at lines 378-383 inside the `ClientShell` `ShellRoute` block (lines 353-384 of `app_router.dart`). No move is needed. The only actionable frontend fix is the `_getCurrentIndex` highlight gap described above.

**`/notifications` placement** — intentionally outside both shells (lines 106-110). Full-screen modal pattern is correct. The screen is fully implemented; it was blocked only by missing DB infrastructure, which backend has now resolved.
