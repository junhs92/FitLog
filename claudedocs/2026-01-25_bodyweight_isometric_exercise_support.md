# Bodyweight & Isometric Exercise Support

**Date**: 2026-01-25
**Feature**: Support for bodyweight exercises and isometric (timed) exercises

---

## Overview

This feature adds specialized support for two types of exercises that don't fit the traditional "weight × reps" logging pattern:

1. **Bodyweight Exercises** (Push-ups, Pull-ups, Dips)
   - Weight defaults to 0 kg
   - Weight input is de-emphasized but still available (for weighted vest/belt)

2. **Isometric Exercises** (Plank, Wall Sit, Hollow Hold, L-Sit)
   - Measured by time held instead of reps
   - Countdown timer with visual feedback

3. **Reps/Timer Toggle**
   - Any exercise can be logged as either reps or timed
   - Provides flexibility for different training styles

---

## Architecture

### Database Schema Changes

**Migration**: `supabase/migrations/20260125_add_exercise_type.sql`

```sql
-- New columns on exercises table
ALTER TABLE exercises
ADD COLUMN is_isometric BOOLEAN DEFAULT false,
ADD COLUMN default_duration_seconds INTEGER DEFAULT 30;

-- Index for efficient filtering
CREATE INDEX idx_exercises_is_isometric ON exercises(is_isometric)
WHERE is_isometric = true;
```

**Flagged Exercises**:
| Exercise Pattern | Default Duration |
|-----------------|------------------|
| `%plank%` | 30 seconds |
| `%dead bug%`, `%bird dog%` | 30 seconds |
| `%wall sit%` | 60 seconds |
| `%hollow%hold%`, `%l-sit%`, `%l sit%` | 45 seconds |

### Entity Layer

**ExerciseEntity** (`exercise_entity.dart`):
```dart
class ExerciseEntity {
  // New fields
  final bool isIsometric;
  final int defaultDurationSeconds;

  // New helper getter
  bool get isBodyweight => equipment == 'bodyweight';
}
```

### State Management

**ActiveSessionState** additions:
```dart
// Timer mode state
final bool isTimerMode;              // Toggle: false = reps, true = timer
final Duration currentDuration;       // Target duration from exercise default
final Duration countdownRemaining;    // Current countdown value
final bool isCountdownRunning;        // Timer active state
```

**ActiveSessionNotifier** new methods:
```dart
void toggleTimerMode();                    // Switch between reps and timer
void setDuration(Duration duration);       // Set target duration
void startCountdown();                     // Start the countdown
void pauseCountdown();                     // Pause the countdown
void resetCountdown();                     // Reset to target duration
void updateCountdownRemaining(Duration);   // Update remaining time (called by timer)
```

### UI Components

#### CountdownTimer Widget

**File**: `presentation/widgets/countdown_timer.dart`

**Features**:
- Quick preset buttons: 15s, 30s, 45s, 60s, 90s, 120s
- Circular progress indicator with color feedback:
  - Green (>50% remaining)
  - Yellow (25-50% remaining)
  - Red (<25% remaining)
- Start/Pause toggle button
- Reset button
- Haptic feedback when timer completes

**Layout**:
```
┌─────────────────────────────────┐
│    [15] [30] [45] [60]          │  <- Quick presets
│         [90] [120]              │
├─────────────────────────────────┤
│                                 │
│         ╭───────────╮           │
│         │   0:45    │           │  <- Countdown display
│         │ of 1:00   │           │
│         ╰───────────╯           │
│                                 │
│    [▶ Start]    [↻ Reset]       │  <- Controls
└─────────────────────────────────┘
```

#### Reps/Timer Toggle

**Widget**: `_RepsTimerToggle` (in active_session_screen.dart)

```
┌────────────────────────────────┐
│   Reps  ──●──  🕐 Timer        │
└────────────────────────────────┘
```

- Default state based on `exercise.isIsometric`
- User can override for any exercise

#### Weight Label for Bodyweight

**Widget**: `_WeightLabel` (in active_session_screen.dart)

- Shows "Weight (optional)" for bodyweight exercises
- Weight input has 60% opacity when bodyweight

---

## Data Flow

### Exercise Initialization

```
goToExercise(index)
    │
    ├─ Check exercise.isBodyweight
    │   └─ If true: weight = 0.0
    │
    ├─ Check exercise.isIsometric
    │   └─ isTimerMode = exercise.isIsometric
    │
    └─ Set currentDuration = exercise.defaultDurationSeconds
```

### Set Logging

```
logSet()
    │
    ├─ If isTimerMode:
    │   ├─ duration = currentDuration
    │   └─ reps = null
    │
    └─ If NOT isTimerMode:
        ├─ duration = null
        └─ reps = currentReps
```

### Set Display (SetRow)

```
if (set.duration != null)
    → Display: "Time: 0:30"
else
    → Display: "Reps: 10"
```

---

## File Changes Summary

| File | Changes |
|------|---------|
| `supabase/migrations/20260125_add_exercise_type.sql` | **NEW** - Database migration |
| `domain/entities/exercise_entity.dart` | Added `isIsometric`, `defaultDurationSeconds`, `isBodyweight` |
| `data/models/exercise_model.dart` | Parse new fields from JSON |
| `presentation/providers/session_provider.dart` | Timer state + methods, updated logSet |
| `presentation/widgets/countdown_timer.dart` | **NEW** - Countdown timer widget |
| `presentation/widgets/set_row.dart` | Conditional duration/reps display |
| `presentation/screens/active_session_screen.dart` | Toggle, conditional UI rendering |

---

## Testing Checklist

### Database
- [ ] Run migration successfully
- [ ] Verify `is_isometric` column exists
- [ ] Verify `default_duration_seconds` column exists
- [ ] Verify plank exercises are flagged as isometric

### Bodyweight Exercise
- [ ] Select "Push Up" exercise
- [ ] Verify weight defaults to 0 kg
- [ ] Verify weight label shows "(optional)"
- [ ] Verify weight input is de-emphasized (60% opacity)
- [ ] Can still adjust weight (for weighted vest scenario)

### Isometric Exercise
- [ ] Select "Plank" exercise
- [ ] Verify toggle defaults to "Timer" mode
- [ ] Verify countdown timer UI shows (not weight/reps)
- [ ] Test quick preset buttons (15s, 30s, 45s, etc.)
- [ ] Start countdown, verify it counts down
- [ ] Pause countdown, verify it pauses
- [ ] Resume countdown, verify it continues
- [ ] Reset countdown, verify it resets to selected duration
- [ ] Complete countdown, verify haptic feedback
- [ ] Log a set, verify duration is recorded
- [ ] Verify set row shows "Time: 0:30" format

### Toggle Behavior
- [ ] Select regular exercise (e.g., "Squat")
- [ ] Verify toggle defaults to "Reps" mode
- [ ] Toggle to "Timer" mode, verify countdown UI appears
- [ ] Log a set with timer, verify duration is saved
- [ ] Toggle back to "Reps" mode, verify reps UI returns
- [ ] Log a set with reps, verify reps is saved

### Edge Cases
- [ ] Toggle during countdown (should pause timer)
- [ ] Navigate between exercises (state should reset properly)
- [ ] Log set when timer is at 0 seconds
- [ ] Very long duration (2+ minutes) display formatting

---

## Future Enhancements

1. **Audio Alert**: Optional sound when timer completes
2. **Auto-log on Complete**: Option to automatically log set when countdown finishes
3. **Custom Duration Input**: Allow typing custom duration instead of just presets
4. **Timer History**: Show last used durations for quick re-selection
5. **Rest Timer Integration**: Auto-start rest timer after isometric set

---

## Related Files

- `exercise_set_entity.dart` - Already had `Duration? duration` field
- `session_repository.dart` - Already supports `duration` parameter in logSet
- `session_remote_datasource.dart` - Already handles duration in database operations
