# Session Package Auto-Increment Feature

**Version:** 1.0
**Created:** 2026-01-23
**Status:** Implemented

---

## Overview

This feature ensures that session packages are automatically updated when training sessions are completed, regardless of the completion path (direct session or via schedule).

### Problem Statement

Previously, the `sessions_used` field in `session_packages` was only incremented when a **schedule** was marked as completed via `deductSession()`. Sessions completed directly through the active session flow did not update the package count, causing incorrect "remaining sessions" displays.

**Example of the bug:**
- Client had package with `total_sessions=10`, `sessions_used=1`
- UI showed "남은 세션: 9회" (9 remaining)
- Database showed 12 completed sessions
- Actual remaining should be -2 (over-usage)

### Solution

A PostgreSQL database trigger that automatically increments `sessions_used` whenever a session's status changes to `'completed'`.

---

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     Session Completion Paths                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Path 1: Schedule-based                Path 2: Direct Session     │
│  ┌──────────────────┐                  ┌──────────────────┐      │
│  │ QuickScheduleSheet│                  │ ActiveSessionScreen│    │
│  │ marks 'completed' │                  │ completes session │     │
│  └────────┬─────────┘                  └────────┬─────────┘      │
│           │                                      │                │
│           │  (calls deductSession)               │                │
│           ▼                                      ▼                │
│  ┌──────────────────┐                  ┌──────────────────┐      │
│  │ client_schedules │                  │     sessions      │      │
│  │ status='completed'│                  │ status='completed'│     │
│  └────────┬─────────┘                  └────────┬─────────┘      │
│           │                                      │                │
│           │  (manual increment)                  │  (TRIGGER)     │
│           ▼                                      ▼                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              session_packages.sessions_used++            │    │
│  │                   (both paths now work)                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Database Components

#### 1. Trigger Function: `increment_sessions_used()`

```sql
CREATE OR REPLACE FUNCTION increment_sessions_used()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger when status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE session_packages
    SET sessions_used = sessions_used + 1,
        updated_at = NOW()
    WHERE client_id = NEW.client_id
      AND is_active = true
      AND sessions_used < total_sessions;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Behavior:**
- Fires on INSERT or UPDATE of `sessions` table
- Only activates when status transitions TO `'completed'`
- Prevents double-counting (checks `OLD.status != 'completed'`)
- Only updates active packages with remaining sessions

#### 2. Trigger: `trigger_increment_sessions_used`

```sql
CREATE TRIGGER trigger_increment_sessions_used
AFTER INSERT OR UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION increment_sessions_used();
```

**Timing:** `AFTER` - ensures session record is committed before package update

---

## Flutter Integration

### UI Component: Remaining Sessions Display

**Location:** `lib/features/client_management/presentation/widgets/client_detail_content.dart`

```dart
Widget _buildSessionsRemaining(WidgetRef ref) {
  final packageAsync = ref.watch(clientSessionPackageProvider(widget.client.id));

  return packageAsync.when(
    data: (package) {
      if (package == null) return const SizedBox(height: AppSpacing.xs);

      final remaining = package.sessionsRemaining;
      final total = package.totalSessions;
      final warningLevel = package.warningLevel;

      // Color coding based on warning level
      // ...
    },
    loading: () => CircularProgressIndicator(),
    error: (_, __) => const SizedBox.shrink(),
  );
}
```

### Warning Level Color Coding

| Warning Level | Condition | Text Color | Background |
|---------------|-----------|------------|------------|
| `none` | 3+ remaining | Green (`AppColors.success`) | Green 10% |
| `low` | 1-2 remaining | Yellow (`AppColors.warning`) | Yellow 10% |
| `critical` | 0 remaining | Red (`AppColors.error`) | Red 10% |
| `expired` | Past expiry date | Red (`AppColors.error`) | Red 10% |

### Display Format

```
🎫 남은 세션: X / Y회
```

Where:
- `X` = `sessionsRemaining` (can be negative if over-used)
- `Y` = `totalSessions`

---

## Domain Entity

### `SessionPackage` Class

**Location:** `lib/features/calendar/domain/entities/session_package.dart`

```dart
class SessionPackage extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String packageName;
  final int totalSessions;
  final int sessionsUsed;
  final double? price;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  /// Computed: remaining sessions
  int get sessionsRemaining => totalSessions - sessionsUsed;

  /// Computed: package validity check
  bool get isValid => isActive && !isExpired && !isDepleted;

  /// Computed: warning level for UI
  PackageWarningLevel get warningLevel {
    if (isExpired) return PackageWarningLevel.expired;
    if (sessionsRemaining <= 0) return PackageWarningLevel.critical;
    if (sessionsRemaining <= 2) return PackageWarningLevel.low;
    return PackageWarningLevel.none;
  }
}
```

### `PackageWarningLevel` Enum

```dart
enum PackageWarningLevel {
  none,      // 3+ sessions remaining
  low,       // 1-2 sessions remaining
  critical,  // 0 sessions remaining
  expired,   // Past expiration date
}
```

---

## Provider Integration

### `clientSessionPackageProvider`

**Location:** `lib/features/calendar/presentation/providers/calendar_provider.dart`

```dart
final clientSessionPackageProvider = FutureProvider.family<SessionPackage?, String>(
  (ref, clientId) async {
    final repository = ref.watch(sessionPackageRepositoryProvider);
    if (repository == null) return null;

    final result = await repository.getActivePackage(clientId);
    return result.fold((_) => null, (package) => package);
  },
);
```

**Usage:**
```dart
final package = ref.watch(clientSessionPackageProvider(clientId));
```

---

## Migration Guide

### Apply Migration

**Option 1: Supabase CLI**
```bash
cd FitLog_Pro_app
supabase db push
```

**Option 2: SQL Editor**
Run the contents of `supabase/migrations/20260123_100000_auto_increment_sessions_used.sql` in Supabase Dashboard → SQL Editor.

### Verify Installation

```sql
-- Check trigger exists
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'sessions';

-- Expected result:
-- trigger_increment_sessions_used | UPDATE | AFTER
-- trigger_increment_sessions_used | INSERT | AFTER
```

### Fix Existing Data

The migration includes a data fix query that runs automatically:

```sql
UPDATE session_packages sp
SET sessions_used = COALESCE((
  SELECT COUNT(*)
  FROM sessions s
  WHERE s.client_id = sp.client_id
    AND s.status = 'completed'
    AND s.created_at >= sp.purchased_at
), 0),
updated_at = NOW()
WHERE sp.is_active = true;
```

---

## Testing

### Manual Test Cases

1. **Complete a session directly**
   - Start session via Active Session Screen
   - Complete the session
   - Verify `sessions_used` incremented in database
   - Verify UI shows updated remaining count

2. **Complete via schedule**
   - Create a schedule entry
   - Mark as completed
   - Verify no double-counting (trigger + manual)

3. **Boundary conditions**
   - Test with 0 remaining sessions (should still work)
   - Test with expired package (should not update)
   - Test with multiple packages (oldest active gets updated)

### SQL Verification

```sql
-- Before completing a session
SELECT client_id, total_sessions, sessions_used,
       total_sessions - sessions_used as remaining
FROM session_packages WHERE is_active = true;

-- Complete a session for a client
UPDATE sessions SET status = 'completed' WHERE id = '<session_id>';

-- After - sessions_used should be incremented
SELECT client_id, total_sessions, sessions_used,
       total_sessions - sessions_used as remaining
FROM session_packages WHERE is_active = true;
```

---

## Design Decisions

### Why Database Trigger?

| Approach | Pros | Cons |
|----------|------|------|
| **Database Trigger** (chosen) | Atomic, consistent, no code changes needed | Requires migration, less visible |
| Flutter service layer | Visible in code, testable | Race conditions, must update all paths |
| Supabase Edge Function | Flexible, can add logic | Additional latency, another service |

**Decision:** Database trigger provides the most reliable solution with guaranteed atomicity and zero changes to existing Flutter code.

### Why AFTER trigger?

Using `AFTER INSERT OR UPDATE` ensures:
1. The session record is fully committed
2. Transaction isolation is maintained
3. Rollback behavior is predictable

---

## Related Files

| File | Purpose |
|------|---------|
| `supabase/migrations/20260123_100000_auto_increment_sessions_used.sql` | Migration with trigger |
| `lib/features/calendar/domain/entities/session_package.dart` | Domain entity |
| `lib/features/calendar/presentation/providers/calendar_provider.dart` | Riverpod providers |
| `lib/features/client_management/presentation/widgets/client_detail_content.dart` | UI display |
| `claudedocs/calendar_feature_implementation.md` | Feature documentation |

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-23 | 1.0 | Initial implementation with trigger and UI display |
