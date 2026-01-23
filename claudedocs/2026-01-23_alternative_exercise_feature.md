# Alternative Exercise Feature

**Date**: 2026-01-23
**Author**: Claude
**Status**: Implemented

---

## Overview

Replaced the difficulty feedback buttons (힘듦, 적당함, 너무 쉬움) with a single "대체 운동" (Alternative Exercise) button that opens a bottom sheet showing exercise alternatives grouped by equipment type and movement pattern.

---

## Problem

The previous difficulty feedback system had several issues:
1. Users rarely used the 3-button difficulty rating during workouts
2. The feedback wasn't actionable - users wanted to swap exercises, not just rate them
3. The alternatives shown after feedback weren't grouped or organized intuitively

---

## Solution

Replaced the difficulty buttons with a simpler, action-oriented approach:
- Single "대체 운동" button that's clearly visible
- Bottom sheet with alternatives grouped by:
  - **Equipment type** ("다른 장비로"): Same movement pattern, different equipment
  - **Pattern variations** ("같은 패턴"): Same equipment, variation exercises

---

## Files Changed

### New Files

| File | Description |
|------|-------------|
| `lib/features/ai_workout/domain/entities/alternative_exercise.dart` | Entity classes for grouped alternatives |

### Modified Files

| File | Changes |
|------|---------|
| `ai_workout_remote_datasource.dart:679-791` | Added `getAlternativeExercises()` method |
| `ai_workout_repository.dart:121-127` | Added interface method signature |
| `ai_workout_repository_impl.dart:303-317` | Implemented repository method |
| `ai_workout_provider.dart:577-593` | Added `alternativeExercisesProvider` |
| `difficulty_feedback_widget.dart` | Complete replacement with new UI |
| `active_session_screen.dart:1616-1682` | Updated to use new button |

---

## Technical Details

### Entity Classes

**AlternativeExercisesResult**
```dart
class AlternativeExercisesResult {
  final List<EquipmentGroup> equipmentAlternatives;  // Different equipment
  final List<SessionAlternative> patternAlternatives; // Same equipment variations

  bool get isEmpty => equipmentAlternatives.isEmpty && patternAlternatives.isEmpty;
}
```

**EquipmentGroup**
```dart
class EquipmentGroup {
  final String equipment;        // 'dumbbell', 'barbell', 'cable', etc.
  final String equipmentLabel;   // '덤벨', '바벨', '케이블', etc.
  final List<SessionAlternative> exercises;
}
```

**EquipmentLabels** (utility class)
```dart
static const Map<String, String> _labels = {
  'dumbbell': '덤벨',
  'barbell': '바벨',
  'cable': '케이블',
  'machine': '머신',
  'bodyweight': '맨몸',
  'smith_machine': '스미스머신',
  'kettlebell': '케틀벨',
  'resistance_band': '밴드',
  'ez_bar': 'EZ바',
  'other': '기타',
};
```

### Database Queries

**Equipment Alternatives Query**
```sql
SELECT * FROM exercises
WHERE movement_group = :orig_group
  AND movement_detail = :orig_detail  -- if exists
  AND equipment != :orig_equipment
  AND id != :exerciseId
LIMIT 20
```

**Pattern Alternatives Query**
```sql
SELECT * FROM exercises
WHERE movement_group = :orig_group
  AND movement_detail = :orig_detail  -- if exists
  AND equipment = :orig_equipment
  AND id != :exerciseId
LIMIT 10
```

### Provider

```dart
final alternativeExercisesProvider = FutureProvider.family<
    AlternativeExercisesResult, String>(
  (ref, exerciseId) async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    final result = await repository.getAlternativeExercises(
      exerciseId: exerciseId,
    );
    return result.fold(
      (_) => AlternativeExercisesResult.empty(),
      (data) => data,
    );
  },
);
```

---

## UI Components

### AlternativeExerciseButton

Compact button displayed inline with exercise cards.

```
┌─────────────────────┐
│  🔄 대체 운동       │
└─────────────────────┘
```

- Primary color outline style
- Icon: `Icons.swap_horiz`
- Opens bottom sheet on tap

### AlternativeExerciseBottomSheet

Modal bottom sheet with grouped alternatives.

```
┌──────────────────────────────────────────┐
│           대체 운동 추천            [X]  │
├──────────────────────────────────────────┤
│  🔧 다른 장비로                           │
│  └─ 같은 움직임, 다른 장비                │
│  ┌────────────────────────────────────┐  │
│  │  [바벨]               2개          │  │
│  ├────────────────────────────────────┤  │
│  │  Barbell Bench Press    [추천]    →│  │
│  │  동일 패턴으로 장비 변경             │  │
│  ├────────────────────────────────────┤  │
│  │  Barbell Floor Press             →│  │
│  │  동일 패턴으로 장비 변경             │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │  [케이블]             1개          │  │
│  ├────────────────────────────────────┤  │
│  │  Cable Chest Press              →│  │
│  │  동일 패턴으로 장비 변경             │  │
│  └────────────────────────────────────┘  │
├──────────────────────────────────────────┤
│  🔁 같은 패턴                             │
│  └─ 같은 장비, 비슷한 운동                │
│  ┌────────────────────────────────────┐  │
│  │  Incline Dumbbell Press  [추천]  →│  │
│  │  같은 장비, 다른 변형                 │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## Edge Cases Handled

| Case | Behavior |
|------|----------|
| No alternatives available | Shows "대체 운동이 없습니다" message with icon |
| Only equipment alternatives | Shows only "다른 장비로" section |
| Only pattern alternatives | Shows only "같은 패턴" section |
| Loading state | Shows centered CircularProgressIndicator |
| Error state | Shows error icon with retry message |

---

## User Flow

```
1. User is on Active Session screen
   ↓
2. User taps "대체 운동" button
   ↓
3. Bottom sheet opens with loading indicator
   ↓
4. Alternatives are fetched and grouped
   ↓
5. User sees alternatives grouped by:
   - Equipment type (grouped cards)
   - Pattern variations (simple list)
   ↓
6. User taps an alternative exercise
   ↓
7. Confirmation dialog appears:
   "대체 운동으로 변경 - ${exerciseName}(으)로 변경하시겠습니까?"
   ↓
8. User confirms → Exercise is swapped
   ↓
9. Success snackbar: "${exerciseName}(으)로 변경되었습니다"
```

---

## Testing Checklist

- [ ] Button appears correctly on exercise cards
- [ ] Tapping button opens bottom sheet
- [ ] Loading state shows spinner
- [ ] Equipment alternatives grouped correctly
- [ ] Pattern alternatives listed correctly
- [ ] "추천" badge shows on first item of each group
- [ ] Tapping alternative shows confirmation dialog
- [ ] Confirming swap updates the exercise
- [ ] Success/error messages display correctly
- [ ] Empty state shows appropriate message
- [ ] Error state shows appropriate message

---

## Database Tables Used

- `exercises`: Exercise library
  - `movement_group`: Movement pattern group (push, pull, legs, core)
  - `movement_detail`: Sub-pattern (horizontal, vertical, squat, hinge, etc.)
  - `equipment`: Equipment type (dumbbell, barbell, cable, etc.)
  - `name`, `name_ko`: Exercise names

---

## Migration Notes

### DifficultyFeedbackCompact Deprecation

The `DifficultyFeedbackCompact` widget now returns `SizedBox.shrink()` and is deprecated. Any code using this widget should migrate to `AlternativeExerciseButton`.

### Backward Compatibility

The `DifficultyFeedbackWidget` class still exists with the same constructor signature but now internally uses `AlternativeExerciseButton`. This maintains backward compatibility for any existing usages.

---

## Future Improvements

1. **Smart sorting**: Sort alternatives by client's past preferences or success rate
2. **Equipment availability**: Filter by equipment available in client's gym
3. **Difficulty indicators**: Show difficulty comparison between original and alternative
4. **Usage tracking**: Track which alternatives are selected to improve recommendations
5. **Quick swap**: Allow direct swap without confirmation for trusted alternatives
