# Exercise Recommendation System Updates

**Date**: 2026-01-19
**Author**: Claude
**Status**: Implemented

---

## Overview

This document covers recent updates to the exercise recommendation system and program management flow in FitLog Pro.

---

## 1. Smart Exercise Recommendations Based on Active Program

### Problem
When users changed their active workout program, the exercise recommendations in the "Empty Session" flow did not reflect the new program's preferences (focus areas, preferred movement patterns).

### Solution
Updated the recommendation system to incorporate active program preferences.

### Files Modified

| File | Changes |
|------|---------|
| `lib/features/active_session/domain/services/exercise_recommendation_service.dart` | Added program preference support |
| `lib/features/active_session/presentation/providers/session_provider.dart` | Fetch active program in recommendations provider |
| `lib/features/ai_workout/presentation/screens/generate_program_screen.dart` | Invalidate recommendations on program save |
| `lib/features/ai_workout/presentation/screens/program_review_screen.dart` | Invalidate recommendations on program activation |

### Technical Details

#### ExerciseRecommendationService Updates

**New Parameters** added to `getRecommendedPatternOrder()` and `getRecommendedExercises()`:
- `preferredMovementPatterns`: List of movement patterns from active program
- `focusAreas`: Priority muscle groups from active program

**New Scoring**:
```dart
// Exercises matching focus areas: +25 points
if (focusAreas != null && focusAreas.isNotEmpty) {
  final muscleGroup = exercise.muscleGroup?.toLowerCase() ?? '';
  for (final focus in focusAreas) {
    if (muscleGroup.contains(focus.toLowerCase())) {
      score += 25.0;
      reason = '프로그램 집중 부위';
      break;
    }
  }
}

// Exercises with preferred movement patterns: +20 points
if (preferredMovementPatterns != null &&
    preferredMovementPatterns.contains(exercise.movementPattern)) {
  score += 20.0;
  reason = '선호 동작 패턴';
}
```

**Focus Area to Movement Pattern Mapping**:
```dart
static const Map<String, List<String>> _focusAreaToPatterns = {
  // Upper body
  'chest' / '가슴': [horizontalPush, isolation],
  'back' / '등': [horizontalPull, verticalPull],
  'shoulders' / '어깨': [verticalPush, isolation],
  'arms' / '팔': [isolation, horizontalPush, horizontalPull],

  // Lower body
  'legs' / '하체' / '다리': [squat, hinge, carry],
  'glutes' / '엉덩이': [hinge, squat],

  // Core
  'core' / '코어': [rotation, carry],
  'abs' / '복근': [rotation, isolation],
};
```

#### Provider Updates

`exerciseRecommendationsProvider` now:
1. Fetches active program using `ref.watch(activeProgramProvider(clientId).future)`
2. Extracts `preferredMovementPatterns` and `focusAreas`
3. Passes these to the recommendation service

Using `ref.watch` (instead of `ref.read`) creates a reactive dependency, so recommendations automatically update when the active program changes.

#### Invalidation Points

Added `ref.invalidate(exerciseRecommendationsProvider(clientId))` in:
- `generate_program_screen.dart` - when program is saved/created
- `program_review_screen.dart` - when program is activated

---

## 2. Exercise Picker Dialog Enhancements

### Problem
The exercise picker in "Empty Session" flow was not grouped by movement pattern and had no smart recommendations.

### Solution
Complete rewrite of `ExercisePickerDialog` with:
- Movement pattern grouping
- Smart recommendations section ("맞춤 추천")
- Visual indicators for recommended patterns

### Files Modified

| File | Changes |
|------|---------|
| `lib/shared/widgets/exercise_picker_dialog.dart` | Complete rewrite with recommendations |
| `lib/features/active_session/presentation/widgets/program_selection_sheet.dart` | Pass clientId to dialog |
| `lib/features/active_session/presentation/screens/previous_session_review_screen.dart` | Pass clientId to dialog |

### UI Features

1. **Top Recommendations Section** ("맞춤 추천")
   - Shows top 5 recommended exercises with reasons
   - Green gradient badge with sparkle icon
   - Displays recommendation reason (e.g., "프로그램 집중 부위", "근력 향상에 효과적")

2. **Movement Pattern Grouping**
   - Exercises grouped by pattern (스쿼트, 힌지, 수평 밀기, etc.)
   - Recommended patterns highlighted with green badge
   - Count shown for each pattern group

3. **Search Functionality**
   - Real-time search filtering
   - Maintains grouping in search results

---

## 3. Simplified Program Creation Flow

### Problem
When creating/editing a program, there was an unnecessary confirmation dialog and navigation to a review screen for exercise generation.

### Solution
Simplified the flow to just save program preferences directly.

### Files Modified

| File | Changes |
|------|---------|
| `lib/features/ai_workout/presentation/providers/ai_workout_provider.dart` | Added `saveProgramPreferencesOnly()` method |
| `lib/features/ai_workout/presentation/screens/generate_program_screen.dart` | Simplified save flow |

### Changes

**Removed**:
- `_showDirectionConfirmationDialog()` method
- `_executeCreateProgram()` method
- `_DirectionSummaryItem` widget
- `_getFocusAreaName()` method
- Navigation to review screen after save
- `ref.listen` for generation state changes

**New Flow**:
```
User fills program form → Clicks save → Program saved to DB → Pop back to previous screen
```

**New Method** `saveProgramPreferencesOnly()`:
```dart
Future<bool> saveProgramPreferencesOnly({
  required String clientId,
  required String trainerId,
  required String name,
  String? description,
  required TrainingSplit trainingSplit,
  List<String>? focusAreas,
  List<String>? preferredMovementPatterns,
  String? existingProgramId,
})
```

---

## Recommendation Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User clicks "빈 세션" (Empty Session)                     │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. ExercisePickerDialog opens with clientId                  │
│    → ref.watch(exerciseRecommendationsProvider(clientId))   │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. exerciseRecommendationsProvider fetches:                  │
│                                                              │
│    a) activeProgramProvider(clientId)                       │
│       → Query: workout_programs WHERE client_id=X           │
│                AND status='active'                          │
│       → Returns: preferredMovementPatterns, focusAreas      │
│                                                              │
│    b) clientProvider(clientId) → client's fitness_goals     │
│    c) clientRecentSessionsProvider → recent sessions        │
│    d) exerciseLibraryProvider → all exercises               │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. ExerciseRecommendationService.getRecommendedExercises()  │
│                                                              │
│    Score calculation:                                        │
│    + Pattern order score (goal-based)          ~10-100 pts  │
│    + Focus area match                          +25 pts      │
│    + Preferred movement pattern match          +20 pts      │
│    + Compound exercise (strength/hypertrophy)  +15 pts      │
│    + Cardio (weight loss goal)                 +20 pts      │
│    - Recently performed exercise               -30 pts      │
│    - Pattern in recent sessions                -50 pts      │
│    + Upper/lower body alternation              +25 pts      │
└─────────────────┬───────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Dialog displays:                                          │
│    - "맞춤 추천" section (top 5 with reasons)               │
│    - Exercises grouped by movement pattern                  │
│    - Recommended patterns highlighted                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Testing Checklist

- [ ] Change active program → Open empty session → Verify recommendations reflect new program's focus areas
- [ ] Create new program with specific focus areas → Set as active → Verify recommendations change
- [ ] Verify "맞춤 추천" section shows exercises matching program preferences
- [ ] Verify movement pattern badges show "추천" for program's preferred patterns
- [ ] Verify search still works correctly
- [ ] Verify program save flow completes without errors

---

## Related Database Tables

- `workout_programs`: Stores program preferences
  - `preferred_movement_patterns`: JSON array of movement pattern IDs
  - `focus_areas`: JSON array of focus area strings
  - `status`: Program status ('active', 'draft', 'completed', etc.)

- `exercises`: Exercise library
  - `movement_pattern`: Movement pattern classification
  - `muscle_group`: Target muscle group

---

## Future Improvements

1. **Cache invalidation optimization**: Consider more granular cache invalidation to avoid unnecessary re-fetches
2. **Recommendation explanations**: Show more detailed reasoning for why exercises are recommended
3. **Learning from user behavior**: Track which recommendations users actually select to improve future suggestions
