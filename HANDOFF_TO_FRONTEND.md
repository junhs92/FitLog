# Handoff To Frontend Architect

_Items assigned to frontend-architect by other agents. Check off each item when complete._

---

## From Backend Architect — Navigation wiring (2026-04-14)

- [x] Wire `NotificationBadge` into the `TrainerShell` navigation bar
      (`lib/navigation/app_router.dart` — `_TrainerShellState`)
      - Mobile: Stack + Positioned overlay in top-right corner (avoids double AppBar)
      - Tablet: added to `NavigationRail` `trailing` parameter
      - On tap: `context.push(Routes.notifications)`

- [x] Implement deep-link navigation in `NotificationsScreen._handleNotificationTap()`
      (`lib/shared/screens/notifications_screen.dart`)
      - `report_ready` / `session_complete` / `achievement` -> navigate to `Routes.clientSessionReport`
      - All other types: mark as read and dismiss only

---

## From Frontend Architect — Router audit (2026-04-14)

- [x] Fix `ClientShell._getCurrentIndex()` to handle `/client/record` route
      (`lib/navigation/app_router.dart` — `_getCurrentIndex` method)
      - Decision: highlight "Today" (index 0) — Record is a Today sub-flow
      - Added explicit `if (location.startsWith(Routes.clientRecord)) return 0;`

- [ ] Verify `NotificationsScreen` compiles cleanly — DB IS NOW LIVE (2026-04-15)
      (`lib/shared/screens/notifications_screen.dart`)
      - All 7 migrations applied to Supabase; notifications table + RLS are live
      - Can now test the screen end-to-end without runtime errors

---

## From Backend Architect — clientId investigation (2026-04-14)

- [x] Confirm correct column in `client_profile_provider.dart:115` — RESOLVED, NO CHANGE NEEDED
      - `accounts.id` is app-level UUID PK; `accounts.user_id` is FK to `auth.users(id)`
      - The `.eq('user_id', clientId)` query is correct; provider is keyed on `auth.uid()`

---

## From Backend Architect — RPC migration (2026-04-14)

- [x] Update `getUnreadCount()` in `notification_service.dart` to call the new RPC
      (`lib/core/services/notification_service.dart`)
      - Now calls `_client.rpc('get_unread_notification_count')` — no full-row fetch
      - Note: backend must apply `20260414_160000_add_unread_notification_count_rpc.sql` first
