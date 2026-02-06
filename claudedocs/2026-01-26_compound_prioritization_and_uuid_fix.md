# Compound Exercise Prioritization & AI UUID Validation

**Date**: 2026-01-26
**Author**: Claude
**Status**: Implemented

---

## Overview

This update addresses two issues:
1. **Compound exercises not prioritized** in the exercise picker "맞춤 추천" section
2. **AI-generated UUID corruption** causing session creation failures

---

## 1. Compound Exercise Prioritization in Recommendations

### Problem

In the exercise picker dialog's "맞춤 추천" (personalized recommendations) section, isolation exercises were often dominating the list despite compound exercises being more suitable for most training goals.

**Root Cause**: The scoring system only gave compound exercises a weak +15 bonus for strength/hypertrophy goals, which was easily overridden by other factors (+50 for split focus, etc.).

### Solution

Implemented a hard filter approach similar to session generation: prioritize compound exercises first, use isolation only as fallback.

### File Modified

| File | Changes |
|------|---------|
| `lib/features/active_session/domain/services/exercise_recommendation_service.dart` | Compound-first filtering in `getRecommendedExercises()` |

### Technical Details

**Before** (Line 531-534):
```dart
// Sort by score and return top recommendations
scoredExercises.sort((a, b) => b.score.compareTo(a.score));
return scoredExercises.take(limit).toList();
```

**After**:
```dart
// Sort by score
scoredExercises.sort((a, b) => b.score.compareTo(a.score));

// Prioritize compound exercises for main recommendations
// Isolation exercises only appear if we don't have enough compounds
final compounds = scoredExercises
    .where((e) => e.exercise.category == ExerciseCategory.compound)
    .take(limit)
    .toList();

// Only add isolation if we don't have enough compounds
if (compounds.length < limit) {
  final isolations = scoredExercises
      .where((e) => e.exercise.category != ExerciseCategory.compound)
      .take(limit - compounds.length);
  compounds.addAll(isolations);
}

return compounds;
```

### Behavior Change

| Scenario | Before | After |
|----------|--------|-------|
| 맞춤 추천 list | Mixed compound/isolation based on score | Compounds first, isolation only as fallback |
| Movement group sections | Unchanged | Unchanged (still shows all exercises) |

---

## 2. AI UUID Validation in Edge Function

### Problem

Session creation was failing with the error:
```
PostgrestException(message: invalid input syntax for type uuid:
"la1ddc1e-2d4f-4b1d-bc3a-46c2d3bc3e3a", code: 22P02)
```

**Root Cause**: OpenAI (GPT-4o-mini) was hallucinating/corrupting UUIDs when generating workout recommendations. The first character `l` (lowercase L) should have been `1` (number one). UUIDs only allow hexadecimal characters (0-9, a-f).

### Solution

Added a `validateAndFixExerciseIds()` function to the edge function that validates and auto-corrects exercise IDs before saving to the database.

### File Modified

| File | Changes |
|------|---------|
| `supabase/functions/generate-workout/index.ts` | Added UUID validation and auto-correction |

### Technical Details

**New Function** `validateAndFixExerciseIds()`:

```typescript
async function validateAndFixExerciseIds(
  supabase: ReturnType<typeof createClient>,
  workoutData: any,
  availableExercises: Array<{ id: string; name: string; nameKo: string }>,
  requestId: string
): Promise<void>
```

**Correction Strategy** (in priority order):
1. Check if exercise ID is valid (exists in exercises table)
2. If invalid, try to find correct ID by exact name match (Korean or English)
3. If no name match, try partial name match
4. Apply OCR-like corrections: `l`→`1`, `O`→`0`
5. If still invalid, throw error with clear message

**Integration Point** (after OpenAI response, before database save):
```typescript
console.log(`[${requestId}] Calling OpenAI...`);
const workoutData = await callOpenAI(openaiApiKey, prompt);
console.log(`[${requestId}] OpenAI response received`);

// NEW: Validate and fix exercise IDs
console.log(`[${requestId}] Validating exercise IDs...`);
await validateAndFixExerciseIds(supabase, workoutData, exercises, requestId);

// Continue with database save...
```

### Edge Cases Handled

| Scenario | Handling |
|----------|----------|
| `la1ddc1e-...` (l instead of 1) | OCR correction: `l`→`1` |
| `O1234567-...` (O instead of 0) | OCR correction: `O`→`0` |
| Completely hallucinated UUID | Name lookup to find correct ID |
| Valid UUID | Pass through unchanged |
| Uncorrectable UUID | Throw error with message to retry |

### Logging

The function logs all corrections for debugging:
```
[abc12345] ⚠️ Invalid exercise ID detected: la1ddc1e-2d4f-4b1d-bc3a-46c2d3bc3e3a for "어시스티드 풀업"
[abc12345] ✅ Auto-corrected to: 1a1ddc1e-2d4f-4b1d-bc3a-46c2d3bc3e3a
```

---

## Deployment

### Edge Function Deployment

```bash
cd FitLog_Pro_app
npx supabase functions deploy generate-workout --no-verify-jwt
```

**Deployment Status**: ✅ Deployed to project `cqgqzefzgcrvfnjushwk`

### Flutter App Changes

No deployment needed - the `exercise_recommendation_service.dart` changes take effect on hot restart.

---

## Testing Checklist

### Compound Prioritization
- [ ] Hot restart the app
- [ ] Open exercise picker (운동 선택)
- [ ] Verify "맞춤 추천" section shows mostly compound exercises
- [ ] Check that isolation exercises appear lower in movement group sections
- [ ] Verify recommendations still respect training split focus

### UUID Validation
- [ ] Generate AI workout for a client
- [ ] Verify session creation succeeds
- [ ] Check edge function logs for any UUID corrections
- [ ] If correction occurs, verify session still has correct exercises

---

## Related Files

### Compound Prioritization
- `exercise_recommendation_service.dart` - Main service with scoring logic
- `exercise_picker_dialog.dart` - UI that displays recommendations

### UUID Validation
- `generate-workout/index.ts` - Edge function with validation
- `ai_workout_remote_datasource.dart` - Flutter client that calls edge function
- `session_exercise_input.dart` - DTO that uses exercise IDs

---

## Future Improvements

1. **Prompt Engineering**: Improve OpenAI prompt to reduce UUID hallucination
2. **Retry Logic**: Auto-retry workout generation if validation fails
3. **Monitoring**: Track UUID correction frequency to measure AI reliability
4. **Caching**: Cache exercise ID lookups to improve validation performance
