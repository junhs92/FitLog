# Calendar Feature - Implementation Documentation

## 1. Feature Overview

### Purpose
Create a calendar section in FitLog Pro where trainers can schedule and manage appointments with their clients. This is a standalone scheduling system separate from the workout session recording feature.

### Target Users
- **Trainers**: Schedule, view, edit, and manage client appointments
- **Clients**: View their scheduled appointments (read-only)

### Key Features
- Calendar view with month/week/day modes
- Create appointment slots for clients
- View appointments in agenda format
- Filter by client
- Mark appointments as completed or cancelled
- Quick scheduling via bottom sheet
- Session package tracking with automatic deduction

---

## 2. Database Design

### 2.1 New Table: `client_schedules`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| `trainer_id` | UUID | NOT NULL, FK → accounts(id), ON DELETE CASCADE | The trainer who owns this schedule |
| `client_id` | UUID | NOT NULL, FK → accounts(id), ON DELETE CASCADE | The client being scheduled |
| `scheduled_at` | TIMESTAMPTZ | NOT NULL | Date and time of the appointment |
| `duration_minutes` | INTEGER | DEFAULT 60 | Expected duration (30/45/60/90 min) |
| `status` | TEXT | NOT NULL, DEFAULT 'scheduled', CHECK IN ('scheduled', 'completed', 'cancelled', 'no_show') | Current status |
| `notes` | TEXT | NULL | Optional notes about the appointment |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | When the record was created |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | When the record was last updated |

### Indexes
```sql
CREATE INDEX idx_client_schedules_trainer ON client_schedules(trainer_id);
CREATE INDEX idx_client_schedules_client ON client_schedules(client_id);
CREATE INDEX idx_client_schedules_scheduled_at ON client_schedules(scheduled_at);
CREATE INDEX idx_client_schedules_status ON client_schedules(status);
```

### Row-Level Security (RLS)

**Policy: `schedules_trainer_all`**
- Applies to: ALL operations (SELECT, INSERT, UPDATE, DELETE)
- Condition: `trainer_id` matches the current authenticated user's account ID
- Purpose: Trainers have full control over their own schedules

**Policy: `schedules_client_view`**
- Applies to: SELECT only
- Condition: `client_id` matches the current authenticated user's account ID
- Purpose: Clients can view appointments where they are the client

### Migration SQL
```sql
-- Migration: 20260118_create_client_schedules.sql

-- Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create client_schedules table
CREATE TABLE client_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Scheduling details
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_client_schedules_trainer ON client_schedules(trainer_id);
CREATE INDEX idx_client_schedules_client ON client_schedules(client_id);
CREATE INDEX idx_client_schedules_scheduled_at ON client_schedules(scheduled_at);
CREATE INDEX idx_client_schedules_status ON client_schedules(status);

-- Enable RLS
ALTER TABLE client_schedules ENABLE ROW LEVEL SECURITY;

-- Trainers can manage their own schedules
CREATE POLICY "schedules_trainer_all" ON client_schedules
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their appointments
CREATE POLICY "schedules_client_view" ON client_schedules
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Updated_at trigger
CREATE TRIGGER update_client_schedules_updated_at
  BEFORE UPDATE ON client_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

### 2.2 New Table: `session_packages`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier |
| `trainer_id` | UUID | NOT NULL, FK → accounts(id), ON DELETE CASCADE | The trainer selling the package |
| `client_id` | UUID | NOT NULL, FK → accounts(id), ON DELETE CASCADE | The client who purchased |
| `package_name` | TEXT | NOT NULL | Name of package (e.g., "10 Session Pack") |
| `total_sessions` | INTEGER | NOT NULL, CHECK > 0 | Total sessions in package |
| `sessions_used` | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 | Sessions consumed |
| `price` | DECIMAL(10,2) | NULL | Optional price tracking |
| `purchased_at` | TIMESTAMPTZ | DEFAULT NOW() | When package was purchased |
| `expires_at` | TIMESTAMPTZ | NULL | Optional expiry date |
| `is_active` | BOOLEAN | DEFAULT true | Whether package is currently active |
| `notes` | TEXT | NULL | Optional notes |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Record creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Record update time |

### Migration SQL
```sql
-- Migration: 20260118_create_session_packages.sql

CREATE TABLE session_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Package details
  package_name TEXT NOT NULL,
  total_sessions INTEGER NOT NULL CHECK (total_sessions > 0),
  sessions_used INTEGER NOT NULL DEFAULT 0 CHECK (sessions_used >= 0),
  price DECIMAL(10,2),

  -- Dates
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,

  -- Status
  is_active BOOLEAN DEFAULT true,
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_session_packages_trainer ON session_packages(trainer_id);
CREATE INDEX idx_session_packages_client ON session_packages(client_id);
CREATE INDEX idx_session_packages_active ON session_packages(trainer_id, client_id, is_active)
  WHERE is_active = true;

-- RLS
ALTER TABLE session_packages ENABLE ROW LEVEL SECURITY;

-- Trainers can manage packages for their clients
CREATE POLICY "packages_trainer_all" ON session_packages
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their own packages
CREATE POLICY "packages_client_view" ON session_packages
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Updated_at trigger
CREATE TRIGGER update_session_packages_updated_at
  BEFORE UPDATE ON session_packages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 2.3 Auto-Increment Trigger for Session Completion

When a session is completed directly (via the active session flow, not through schedule completion), the `sessions_used` field must still be updated. A database trigger handles this automatically.

**Migration: `20260123_auto_increment_sessions_used.sql`**

```sql
-- Function to increment sessions_used when session completes
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

-- Trigger on sessions table
CREATE TRIGGER trigger_increment_sessions_used
AFTER INSERT OR UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION increment_sessions_used();
```

**Why Database Trigger?**
1. **Consistent** - All session completions update the package (direct or via schedule)
2. **No race conditions** - Database handles atomicity
3. **No Flutter code changes** - Works immediately for existing flows
4. **Future-proof** - Any new completion paths automatically work

**Fix Existing Data (one-time)**
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

## 3. Architecture Design

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Screens   │  │   Widgets   │  │    Providers    │  │
│  │ (CalendarS.)│  │ (Calendar   │  │ (calendarProv., │  │
│  │             │  │  View, etc.)│  │  schedulesProv.)│  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└───────────────────────────┬─────────────────────────────┘
                            │ depends on
┌───────────────────────────▼─────────────────────────────┐
│                      DOMAIN                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │  Entities   │  │  Usecases   │  │  Repositories   │  │
│  │ (Schedule   │  │ (GetSched., │  │  (interfaces)   │  │
│  │  Entry)     │  │  Create...)│  │                 │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└───────────────────────────┬─────────────────────────────┘
                            │ implements
┌───────────────────────────▼─────────────────────────────┐
│                       DATA                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Models    │  │ Datasources │  │  Repositories   │  │
│  │ (Schedule   │  │ (Remote     │  │  (impl)         │  │
│  │  Model)     │  │  Supabase)  │  │                 │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### File Structure

```
lib/features/calendar/
│
├── domain/
│   ├── entities/
│   │   ├── schedule_entry.dart
│   │   │   └── ScheduleEntry class (pure domain object)
│   │   │   └── ScheduleStatus enum
│   │   ├── schedule_filter.dart
│   │   │   └── ScheduleFilter class (filter criteria)
│   │   └── session_package.dart
│   │       └── SessionPackage class (client's session credits)
│   │       └── PackageWarningLevel enum
│   │
│   ├── repositories/
│   │   ├── schedule_repository.dart
│   │   │   └── ScheduleRepository abstract class (interface)
│   │   └── session_package_repository.dart
│   │       └── SessionPackageRepository abstract class
│   │
│   └── usecases/
│       ├── get_schedules_for_range.dart
│       ├── create_schedule.dart
│       ├── update_schedule.dart
│       ├── delete_schedule.dart
│       ├── complete_schedule.dart (marks complete + deducts session)
│       └── mark_no_show.dart (marks no_show + deducts session)
│
├── data/
│   ├── models/
│   │   ├── schedule_entry_model.dart
│   │   │   └── ScheduleEntryModel class (JSON serialization)
│   │   └── session_package_model.dart
│   │       └── SessionPackageModel class (JSON serialization)
│   │
│   ├── datasources/
│   │   ├── schedule_remote_datasource.dart
│   │   │   └── ScheduleRemoteDataSource class (Supabase API)
│   │   └── session_package_remote_datasource.dart
│   │       └── SessionPackageRemoteDataSource class
│   │
│   └── repositories/
│       ├── schedule_repository_impl.dart
│       │   └── ScheduleRepositoryImpl class
│       └── session_package_repository_impl.dart
│           └── SessionPackageRepositoryImpl class
│
└── presentation/
    ├── providers/
    │   ├── calendar_provider.dart
    │   │   └── CalendarNotifier (StateNotifier)
    │   │   └── calendarProvider
    │   │
    │   ├── schedules_provider.dart
    │   │   └── schedulesProvider (FutureProvider)
    │   │   └── schedulesByDayProvider
    │   │   └── selectedDaySchedulesProvider
    │   │
    │   ├── schedule_filter_provider.dart
    │   │   └── scheduleFilterProvider
    │   │
    │   └── session_package_provider.dart
    │       └── clientSessionPackageProvider (FutureProvider.family)
    │       └── clientSessionsRemainingProvider
    │
    ├── screens/
    │   ├── calendar_screen.dart
    │   │   └── CalendarScreen widget
    │   └── create_schedule_screen.dart
    │       └── CreateScheduleScreen widget (full-page form)
    │
    └── widgets/
        ├── calendar_view.dart
        │   └── CalendarView (table_calendar wrapper)
        ├── calendar_day_markers.dart
        │   └── CalendarDayMarkers (dots on calendar)
        ├── schedule_card.dart
        │   └── ScheduleCard (list item in agenda)
        ├── client_filter_chips.dart
        │   └── ClientFilterChips (filter by client)
        ├── view_mode_selector.dart
        │   └── ViewModeSelector (month/week/day toggle)
        └── quick_schedule_sheet.dart
            └── QuickScheduleSheet (bottom sheet for quick add)
```

---

## 4. Entity Definitions

### 4.1 ScheduleEntry

```dart
/// Schedule status representing the current state of an appointment
enum ScheduleStatus {
  scheduled,  // Blue - active appointment
  completed,  // Green - finished appointment
  cancelled,  // Gray - cancelled appointment
  noShow,     // Orange - client didn't show up (session deducted)
}

/// Pure domain entity for a scheduled appointment
class ScheduleEntry extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String clientName;        // From joined accounts table
  final String? clientPhotoUrl;   // From joined accounts table
  final DateTime scheduledAt;
  final int durationMinutes;      // Default 60
  final ScheduleStatus status;
  final String? notes;
  final DateTime createdAt;

  // Computed Properties
  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
           scheduledAt.month == now.month &&
           scheduledAt.day == now.day;
  }

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  bool get isUpcoming => status == ScheduleStatus.scheduled && !isPast;

  @override
  List<Object?> get props => [id, trainerId, clientId, scheduledAt, status];
}
```

### 4.2 ScheduleFilter

```dart
/// Filter criteria for schedule queries
class ScheduleFilter extends Equatable {
  final List<String> clientIds;           // Empty = all clients
  final List<ScheduleStatus> statuses;    // Default: all statuses
  final String? searchQuery;              // Optional text search

  // Computed Properties
  bool get hasActiveFilters =>
      clientIds.isNotEmpty ||
      statuses.length < ScheduleStatus.values.length ||
      (searchQuery?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [clientIds, statuses, searchQuery];
}
```

### 4.3 SessionPackage

```dart
/// Warning level for session package status
enum PackageWarningLevel {
  none,      // 3+ sessions remaining, no warning
  low,       // 1-2 sessions remaining, yellow warning
  critical,  // 0 sessions remaining, red warning
  expired,   // Package expired, show expired badge
}

/// Domain entity for a client's session package
class SessionPackage extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String packageName;       // e.g., "10 Session Pack"
  final int totalSessions;
  final int sessionsUsed;
  final double? price;            // Optional
  final DateTime purchasedAt;
  final DateTime? expiresAt;      // Optional
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  // Computed Properties
  int get sessionsRemaining => totalSessions - sessionsUsed;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isDepleted => sessionsUsed >= totalSessions;

  bool get isValid => isActive && !isExpired && !isDepleted;

  PackageWarningLevel get warningLevel {
    if (isExpired) return PackageWarningLevel.expired;
    if (sessionsRemaining <= 0) return PackageWarningLevel.critical;
    if (sessionsRemaining <= 2) return PackageWarningLevel.low;
    return PackageWarningLevel.none;
  }

  @override
  List<Object?> get props => [id, trainerId, clientId, totalSessions, sessionsUsed];
}
```

---

## 5. Repository Interfaces

### 5.1 ScheduleRepository

```dart
/// Abstract interface for schedule data operations
abstract class ScheduleRepository {
  /// Get schedules within a date range with optional filters
  Future<Result<List<ScheduleEntry>>> getSchedulesForRange({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
    List<ScheduleStatus>? statuses,
  });

  /// Create a new schedule entry
  Future<Result<ScheduleEntry>> createSchedule({
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  });

  /// Update an existing schedule
  Future<Result<ScheduleEntry>> updateSchedule({
    required String scheduleId,
    DateTime? scheduledAt,
    int? durationMinutes,
    ScheduleStatus? status,
    String? notes,
  });

  /// Delete a schedule
  Future<Result<void>> deleteSchedule(String scheduleId);

  /// Get appointment counts by day for calendar markers
  Future<Result<Map<DateTime, int>>> getScheduleCountsByDay({
    required DateTime month,
    List<String>? clientIds,
  });
}
```

### 5.2 SessionPackageRepository

```dart
/// Abstract interface for session package operations
abstract class SessionPackageRepository {
  /// Get active packages for a specific client
  Future<Result<List<SessionPackage>>> getClientPackages({
    required String clientId,
    bool activeOnly = true,
  });

  /// Get the primary active package (oldest non-expired, non-depleted)
  Future<Result<SessionPackage?>> getActivePackage(String clientId);

  /// Create a new session package
  Future<Result<SessionPackage>> createPackage({
    required String clientId,
    required String packageName,
    required int totalSessions,
    double? price,
    DateTime? expiresAt,
    String? notes,
  });

  /// Deduct a session from a package
  Future<Result<SessionPackage>> deductSession(String packageId);

  /// Update package details
  Future<Result<SessionPackage>> updatePackage({
    required String packageId,
    String? packageName,
    int? totalSessions,
    double? price,
    DateTime? expiresAt,
    bool? isActive,
    String? notes,
  });
}
```

---

## 6. Data Layer Implementation

### 6.1 ScheduleEntryModel

```dart
/// Data model extending ScheduleEntry with JSON serialization
class ScheduleEntryModel extends ScheduleEntry {
  const ScheduleEntryModel({
    required super.id,
    required super.trainerId,
    required super.clientId,
    required super.clientName,
    super.clientPhotoUrl,
    required super.scheduledAt,
    required super.durationMinutes,
    required super.status,
    super.notes,
    required super.createdAt,
  });

  /// Parse from Supabase JSON response
  factory ScheduleEntryModel.fromJson(Map<String, dynamic> json) {
    // Handle nested accounts join
    final clientAccount = json['accounts'] as Map<String, dynamic>?;

    return ScheduleEntryModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      clientName: clientAccount?['full_name'] as String? ?? 'Unknown',
      clientPhotoUrl: clientAccount?['avatar_url'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for INSERT operations
  Map<String, dynamic> toInsertJson() => {
    'trainer_id': trainerId,
    'client_id': clientId,
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    'status': status.name,
    'notes': notes,
  };

  /// Convert to JSON for UPDATE operations
  Map<String, dynamic> toUpdateJson() => {
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    'status': status.name,
    'notes': notes,
  };

  static ScheduleStatus _parseStatus(String status) {
    switch (status) {
      case 'scheduled': return ScheduleStatus.scheduled;
      case 'completed': return ScheduleStatus.completed;
      case 'cancelled': return ScheduleStatus.cancelled;
      case 'no_show': return ScheduleStatus.noShow;
      default: return ScheduleStatus.scheduled;
    }
  }
}
```

### 6.2 ScheduleRemoteDataSource

```dart
/// Remote data source for schedule operations via Supabase
class ScheduleRemoteDataSource {
  final SupabaseClient _client;

  ScheduleRemoteDataSource(this._client);

  /// Select query with client join
  static const String _selectQuery = '''
    id, trainer_id, client_id, scheduled_at, duration_minutes,
    status, notes, created_at,
    accounts!client_schedules_client_id_fkey(full_name, avatar_url)
  ''';

  /// Fetch schedules for a date range
  Future<List<ScheduleEntryModel>> getSchedulesForRange({
    required String trainerId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? clientIds,
    List<String>? statuses,
  }) async {
    var query = _client
        .from('client_schedules')
        .select(_selectQuery)
        .eq('trainer_id', trainerId)
        .gte('scheduled_at', startDate.toIso8601String())
        .lte('scheduled_at', endDate.toIso8601String());

    if (clientIds != null && clientIds.isNotEmpty) {
      query = query.inFilter('client_id', clientIds);
    }

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }

    final response = await query.order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => ScheduleEntryModel.fromJson(json))
        .toList();
  }

  /// Create a new schedule
  Future<ScheduleEntryModel> createSchedule({
    required String trainerId,
    required String clientId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  }) async {
    final response = await _client
        .from('client_schedules')
        .insert({
          'trainer_id': trainerId,
          'client_id': clientId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'duration_minutes': durationMinutes,
          'notes': notes,
        })
        .select(_selectQuery)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Update schedule status
  Future<ScheduleEntryModel> updateStatus({
    required String scheduleId,
    required String status,
  }) async {
    final response = await _client
        .from('client_schedules')
        .update({'status': status})
        .eq('id', scheduleId)
        .select(_selectQuery)
        .single();

    return ScheduleEntryModel.fromJson(response);
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _client
        .from('client_schedules')
        .delete()
        .eq('id', scheduleId);
  }
}
```

---

## 7. Provider Design

### 7.1 CalendarState

```dart
/// View modes for the calendar display
enum CalendarViewMode {
  month,  // Full month grid view
  week,   // 7-day view with times
  day,    // Single day with hourly slots
}

/// Immutable state for the calendar feature
class CalendarState {
  final DateTime focusedDay;           // Currently visible month/week center
  final DateTime? selectedDay;         // Tapped day for agenda
  final CalendarViewMode viewMode;     // month/week/day
  final ScheduleFilter filter;         // Active filters
  final bool isLoading;
  final String? error;

  const CalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.viewMode = CalendarViewMode.month,
    this.filter = const ScheduleFilter(),
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarViewMode? viewMode,
    ScheduleFilter? filter,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      viewMode: viewMode ?? this.viewMode,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,  // Allow clearing error by passing null
    );
  }
}
```

### 7.2 CalendarNotifier

```dart
/// State notifier for calendar interactions
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(
    focusedDay: DateTime.now(),
    selectedDay: DateTime.now(),
  ));

  /// Set the focused day (when navigating months)
  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  /// Set the selected day (when tapping a date)
  void setSelectedDay(DateTime? day) {
    state = state.copyWith(selectedDay: day);
  }

  /// Change view mode
  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Update filter
  void setFilter(ScheduleFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(filter: const ScheduleFilter());
  }

  /// Toggle client in filter
  void toggleClientFilter(String clientId) {
    final currentIds = List<String>.from(state.filter.clientIds);
    if (currentIds.contains(clientId)) {
      currentIds.remove(clientId);
    } else {
      currentIds.add(clientId);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(clientIds: currentIds),
    );
  }
}
```

### 7.3 Provider Definitions

```dart
// Calendar state provider
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});

// Schedules for current visible range
final schedulesProvider = FutureProvider<List<ScheduleEntry>>((ref) async {
  final calendarState = ref.watch(calendarProvider);
  final repository = ref.read(scheduleRepositoryProvider);

  // Calculate date range based on view mode
  final range = _calculateDateRange(
    calendarState.focusedDay,
    calendarState.viewMode,
  );

  final result = await repository.getSchedulesForRange(
    startDate: range.start,
    endDate: range.end,
    clientIds: calendarState.filter.clientIds.isEmpty
        ? null
        : calendarState.filter.clientIds,
    statuses: calendarState.filter.statuses.isEmpty
        ? null
        : calendarState.filter.statuses,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (schedules) => schedules,
  );
});

// Group schedules by day for calendar markers
final schedulesByDayProvider = Provider<Map<DateTime, List<ScheduleEntry>>>((ref) {
  final schedulesAsync = ref.watch(schedulesProvider);

  return schedulesAsync.when(
    data: (schedules) {
      final map = <DateTime, List<ScheduleEntry>>{};
      for (final schedule in schedules) {
        final dayKey = DateTime(
          schedule.scheduledAt.year,
          schedule.scheduledAt.month,
          schedule.scheduledAt.day,
        );
        map.putIfAbsent(dayKey, () => []).add(schedule);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Schedules for selected day (agenda view)
final selectedDaySchedulesProvider = Provider<List<ScheduleEntry>>((ref) {
  final selectedDay = ref.watch(calendarProvider).selectedDay;
  final schedulesByDay = ref.watch(schedulesByDayProvider);

  if (selectedDay == null) return [];

  final dayKey = DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
  );

  return schedulesByDay[dayKey] ?? [];
});

// Client's active session package
final clientSessionPackageProvider =
    FutureProvider.family<SessionPackage?, String>((ref, clientId) async {
  final repository = ref.read(sessionPackageRepositoryProvider);
  final result = await repository.getActivePackage(clientId);
  return result.fold((_) => null, (package) => package);
});

// Quick check for remaining sessions
final clientSessionsRemainingProvider =
    Provider.family<int, String>((ref, clientId) {
  final packageAsync = ref.watch(clientSessionPackageProvider(clientId));
  return packageAsync.when(
    data: (package) => package?.sessionsRemaining ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
```

---

## 8. UI Components

### 8.1 CalendarScreen Layout

```
┌─────────────────────────────────────────┐
│ AppBar                                  │
│ ┌─────────────────────────────────────┐ │
│ │ "Calendar"        [Filter] [M/W/D]  │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ FilterChips (if active)                 │
│ ┌─────────────────────────────────────┐ │
│ │ [John ✕] [Sarah ✕]       [Clear All]│ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ CalendarView (table_calendar)           │
│ ┌─────────────────────────────────────┐ │
│ │     < January 2026 >                │ │
│ │ Mo Tu We Th Fr Sa Su                │ │
│ │     1  2  3  4  5  6               │ │
│ │  7  8  9 10 11 12 13               │ │
│ │ 14 15 16[17]18 19 20  ← selected   │ │
│ │ 21 22 23 24 25 26 27               │ │
│ │ 28 29 30 31           • = has appt │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ Agenda (selected day's appointments)    │
│ ┌─────────────────────────────────────┐ │
│ │ Friday, January 17                  │ │
│ │                                     │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │ 🔵 9:00 AM - John Smith         │ │ │
│ │ │    60 min • Training            │ │ │
│ │ └─────────────────────────────────┘ │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │ 🔵 2:00 PM - Sarah Lee          │ │ │
│ │ │    45 min • Assessment          │ │ │
│ │ └─────────────────────────────────┘ │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│                              [+ FAB]    │
└─────────────────────────────────────────┘
```

### 8.2 QuickScheduleSheet Layout

```
┌─────────────────────────────────────────┐
│ ─────────  (drag handle)                │
│                                         │
│ Schedule Appointment                    │
│ ─────────────────────────────────────── │
│                                         │
│ Client *                                │
│ ┌─────────────────────────────────────┐ │
│ │ Select client...              ▼    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ⚠️ John has 0 remaining sessions       │ (warning if applicable)
│                                         │
│ Date *                                  │
│ ┌─────────────────────────────────────┐ │
│ │ Jan 17, 2026                  📅   │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Time *                                  │
│ ┌─────────────────────────────────────┐ │
│ │ 9:00 AM                       🕐   │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Duration                                │
│ ┌─────────────────────────────────────┐ │
│ │ [30] [45] [60] [90] min            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Notes (optional)                        │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │          Schedule                   │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 8.3 ScheduleCard Component

```
┌─────────────────────────────────────────┐
│ ┌───┐                                   │
│ │ 🔵│ 9:00 AM                    [•••] │
│ └───┘                                   │
│      John Smith                         │
│      60 min • "Focus on core work"      │
│                                         │
│      Sessions: 7 remaining              │ (optional package info)
└─────────────────────────────────────────┘

Status indicator colors (from AppColors):
🔵 = scheduled (primary - blue)
🟢 = completed (success - green)
⚫ = cancelled (neutral - gray)
🟠 = no_show (warning - orange)

[•••] overflow menu options:
  - Mark as Completed
  - Mark as No-Show
  - Reschedule
  - Cancel
  - Delete
```

---

## 9. Navigation Integration

### 9.1 Route Definitions

```dart
// In navigation/routes.dart
class Routes {
  // ... existing routes ...
  static const String trainerCalendar = '/trainer/calendar';
  static const String trainerScheduleCreate = '/trainer/calendar/create';
}

class RouteNames {
  // ... existing names ...
  static const String trainerCalendar = 'trainerCalendar';
  static const String trainerScheduleCreate = 'trainerScheduleCreate';
}
```

### 9.2 TrainerShell Tab Update

**Current tabs:** Home | Clients | Academy | Profile

**New tabs:** Home | **Calendar** | Clients | Academy | Profile

```dart
// In TrainerShell navigation destinations
NavigationDestination(
  icon: Icon(Icons.calendar_month_outlined),
  selectedIcon: Icon(Icons.calendar_month),
  label: 'Calendar',
),
```

### 9.3 Navigation Flow

```
TrainerShell
    │
    ├── Home (index 0)
    │
    ├── Calendar (index 1) ← NEW
    │   │
    │   ├── CalendarScreen
    │   │   └── FAB → QuickScheduleSheet (bottom sheet)
    │   │   └── Event tap → Schedule actions (bottom sheet)
    │   │
    │   └── CreateScheduleScreen (push route for full form)
    │
    ├── Clients (index 2, was index 1)
    │
    ├── Academy (index 3, was index 2)
    │
    └── Profile (index 4, was index 3)
```

---

## 10. Session Deduction Logic

### Complete/No-Show Flow

When `client_schedules.status` changes to `completed` or `no_show`:

```
1. Find active package for (trainer_id, client_id) where:
   - is_active = true
   - sessions_used < total_sessions
   - (expires_at IS NULL OR expires_at > NOW())
   - ORDER BY purchased_at ASC (use oldest package first)

2. If package found:
   - INCREMENT sessions_used by 1
   - Update schedule status
   - Return updated package info

3. If no package found:
   - Still allow status change
   - Show info: "No active session package to deduct from"
```

### Warning States

```dart
// Package warning display
if (package.warningLevel == PackageWarningLevel.low) {
  // 🟡 Yellow: "1-2 sessions remaining"
}
if (package.warningLevel == PackageWarningLevel.critical) {
  // 🔴 Red: "0 sessions remaining"
}
if (package.warningLevel == PackageWarningLevel.expired) {
  // ⚠️ "Package expired"
}
```

---

## 11. Error Handling

### Error Types
- **NetworkFailure**: Show snackbar with retry option, keep last successful data
- **ValidationFailure**: Inline form errors (client not selected, date in past)
- **PermissionFailure**: 403 - redirect to login if session expired
- **NotFoundFailure**: Schedule was deleted by another session

### User Feedback
```dart
// Success feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Appointment scheduled successfully')),
);

// Error with retry
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Failed to load schedules'),
    action: SnackBarAction(
      label: 'Retry',
      onPressed: () => ref.refresh(schedulesProvider),
    ),
  ),
);
```

---

## 12. Dependencies

### New Package
```yaml
# pubspec.yaml
dependencies:
  table_calendar: ^3.1.2
```

### Existing Dependencies Used
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `supabase_flutter` - Backend API
- `intl` - Date formatting
- `dartz` - Either/Result pattern
- `equatable` - Entity comparison

---

## 13. Implementation Checklist

### Phase 1: Database Setup
- [ ] Apply migration for `client_schedules` table via Supabase MCP
- [ ] Apply migration for `session_packages` table via Supabase MCP
- [ ] Verify RLS policies work correctly
- [ ] Test queries manually in Supabase dashboard

### Phase 2: Domain Layer
- [ ] Create `lib/features/calendar/domain/entities/schedule_entry.dart`
- [ ] Create `lib/features/calendar/domain/entities/schedule_filter.dart`
- [ ] Create `lib/features/calendar/domain/entities/session_package.dart`
- [ ] Create `lib/features/calendar/domain/repositories/schedule_repository.dart`
- [ ] Create `lib/features/calendar/domain/repositories/session_package_repository.dart`

### Phase 3: Data Layer
- [ ] Create `lib/features/calendar/data/models/schedule_entry_model.dart`
- [ ] Create `lib/features/calendar/data/models/session_package_model.dart`
- [ ] Create `lib/features/calendar/data/datasources/schedule_remote_datasource.dart`
- [ ] Create `lib/features/calendar/data/datasources/session_package_remote_datasource.dart`
- [ ] Create `lib/features/calendar/data/repositories/schedule_repository_impl.dart`
- [ ] Create `lib/features/calendar/data/repositories/session_package_repository_impl.dart`

### Phase 4: Presentation Layer - Providers
- [ ] Create `lib/features/calendar/presentation/providers/calendar_provider.dart`
- [ ] Create `lib/features/calendar/presentation/providers/schedules_provider.dart`
- [ ] Create `lib/features/calendar/presentation/providers/session_package_provider.dart`

### Phase 5: Presentation Layer - Widgets
- [ ] Add `table_calendar: ^3.1.2` to pubspec.yaml
- [ ] Create `lib/features/calendar/presentation/widgets/calendar_view.dart`
- [ ] Create `lib/features/calendar/presentation/widgets/schedule_card.dart`
- [ ] Create `lib/features/calendar/presentation/widgets/quick_schedule_sheet.dart`
- [ ] Create `lib/features/calendar/presentation/widgets/client_filter_chips.dart`
- [ ] Create `lib/features/calendar/presentation/widgets/view_mode_selector.dart`

### Phase 6: Presentation Layer - Screens
- [ ] Create `lib/features/calendar/presentation/screens/calendar_screen.dart`
- [ ] Create `lib/features/calendar/presentation/screens/create_schedule_screen.dart` (optional full form)

### Phase 7: Navigation
- [ ] Add routes to `lib/navigation/routes.dart`
- [ ] Add routes to `lib/navigation/app_router.dart`
- [ ] Update TrainerShell with Calendar tab (insert at index 1)

### Phase 8: Testing & Validation
- [ ] Run `flutter analyze`
- [ ] Test on emulator/device
- [ ] Verify schedule CRUD operations
- [ ] Verify session deduction flow
- [ ] Test warning displays for low/zero sessions

---

## 14. API Query Examples

### Fetch Schedules for Date Range
```dart
final response = await _client
    .from('client_schedules')
    .select('''
      id, trainer_id, client_id, scheduled_at, duration_minutes,
      status, notes, created_at,
      accounts!client_schedules_client_id_fkey(full_name, avatar_url)
    ''')
    .eq('trainer_id', trainerId)
    .gte('scheduled_at', startDate.toIso8601String())
    .lte('scheduled_at', endDate.toIso8601String())
    .order('scheduled_at', ascending: true);
```

### Create New Schedule
```dart
final response = await _client
    .from('client_schedules')
    .insert({
      'trainer_id': trainerId,
      'client_id': clientId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': 60,
      'notes': 'Initial assessment',
    })
    .select(/* full select query */)
    .single();
```

### Mark as Completed with Session Deduction
```dart
// 1. Update schedule status
await _client
    .from('client_schedules')
    .update({'status': 'completed'})
    .eq('id', scheduleId);

// 2. Find and update active package
final packageResponse = await _client
    .from('session_packages')
    .select()
    .eq('trainer_id', trainerId)
    .eq('client_id', clientId)
    .eq('is_active', true)
    .lt('sessions_used', _client.raw('total_sessions'))
    .order('purchased_at', ascending: true)
    .limit(1)
    .maybeSingle();

if (packageResponse != null) {
  await _client
      .from('session_packages')
      .update({'sessions_used': packageResponse['sessions_used'] + 1})
      .eq('id', packageResponse['id']);
}
```

---

## 15. Theme Integration

Use existing theme constants from the codebase:

```dart
// Colors (from lib/core/theme/colors.dart)
AppColors.primary      // Schedule status: scheduled (blue)
AppColors.success      // Schedule status: completed (green)
AppColors.warning      // Schedule status: no_show (orange)
AppColors.neutral500   // Schedule status: cancelled (gray)

// Spacing (from lib/core/theme/spacing.dart)
AppSpacing.sm          // 8px - compact padding
AppSpacing.md          // 12px - standard padding
AppSpacing.lg          // 16px - card padding
AppSpacing.xl          // 24px - section spacing

// Typography
Theme.of(context).textTheme.titleMedium  // Card titles
Theme.of(context).textTheme.bodyMedium   // Card descriptions
Theme.of(context).textTheme.labelSmall   // Time labels
```

---

## 16. Client Detail Quick Schedule Flow

### Overview
Trainers can quickly schedule appointments directly from the client detail screen, with the client automatically pre-selected.

### Entry Points

#### 1. AppBar Calendar Icon
- Location: Client detail screen AppBar
- Icon: `Icons.calendar_month`
- Opens QuickScheduleSheet with client pre-filled

#### 2. FAB Button (Recommended)
- Location: Client detail screen, stacked FABs
- Layout:
  ```
  ┌──────────────┐
  │  ➕  예약    │  ← Schedule FAB (light background)
  └──────────────┘
  ┌──────────────┐
  │  ▶️  세션 시작 │  ← Start Session FAB (primary)
  └──────────────┘
  ```
- Both FABs: 130px width × 48px height

### Data Flow
```
Client Detail Screen
       │
       ▼ (tap 예약 FAB or calendar icon)
QuickScheduleSheet(initialClientId: clientId)
       │
       ▼ (client auto-selected, shows remaining sessions)
       │
       ▼ (conflict check)
hasConflictingSchedule() → if conflict → show error, block submit
       │
       ▼ (no conflict)
ScheduleRepository.createSchedule()
       │
       ▼
client_schedules table (Supabase)
       │
       ▼ (invalidate schedulesProvider)
Calendar Screen shows new appointment
```

### Features

#### Remaining Sessions Display
Shows remaining sessions below client dropdown:
- **Blue** (🎫): 3+ sessions remaining
- **Yellow** (⚠️): 1-2 sessions remaining
- **Red** (⚠️): 0 sessions remaining

```dart
Widget _buildRemainingSessions() {
  final remainingSessions = ref.watch(clientSessionsRemainingProvider(clientId));
  // Display: "남은 세션: 10회"
}
```

#### Conflict Detection
Prevents double-booking same client at overlapping times:

```dart
// In schedule_remote_datasource.dart
Future<bool> hasConflictingSchedule({
  required String trainerId,
  required String clientId,
  required DateTime scheduledAt,
  required int durationMinutes,
}) async {
  // Check for time overlap with existing schedules
  // Returns true if conflict exists
}
```

Error message when conflict detected:
```
"송고객님은 이미 해당 시간에 예약이 있습니다"
```

### Files Modified

| File | Changes |
|------|---------|
| `client_detail_screen.dart` | Added calendar FAB, _showScheduleSheet method |
| `client_detail_content.dart` | Added calendar FAB for master-detail layout |
| `quick_schedule_sheet.dart` | Added _buildRemainingSessions, conflict check in submit |
| `schedule_remote_datasource.dart` | Added hasConflictingSchedule method |
| `schedule_repository.dart` | Added hasConflictingSchedule interface |
| `schedule_repository_impl.dart` | Added hasConflictingSchedule implementation |
| `calendar_provider.dart` | Fixed currentTrainerIdProvider to use accounts.id |

### Provider Fix
The `currentTrainerIdProvider` was returning `auth.uid` instead of `accounts.id`, causing session package lookups to fail:

```dart
// Before (incorrect)
final currentTrainerIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.id;  // auth.uid - wrong!
});

// After (correct)
final currentTrainerIdProvider = Provider<String?>((ref) {
  final trainerIdAsync = ref.watch(trainerIdProvider);
  return trainerIdAsync.valueOrNull;  // accounts.id - correct!
});
```

---

*Document created: 2026-01-18*
*Updated: 2026-01-18 - Added Client Detail Quick Schedule Flow*
*Based on FitLog Pro codebase patterns and calendar feature requirements*
