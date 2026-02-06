# Deployment Guide

## Edge Function Deployment

The `generate-workout` edge function has been updated. To deploy:

### Option 1: Using Supabase CLI

```bash
cd FitLog_Pro_app/supabase

# Deploy the edge function
supabase functions deploy generate-workout --project-ref YOUR_PROJECT_REF
```

### Option 2: Using Supabase Dashboard

1. Go to Supabase Dashboard → Edge Functions
2. Click on `generate-workout`
3. Copy the contents of `supabase/functions/generate-workout/index.ts`
4. Replace the existing code
5. Click "Deploy"

---

## Required Environment Variables

Ensure these are set in your Supabase project:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Auto-set by Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set by Supabase |
| `OPENAI_API_KEY` | Your OpenAI API key |

To set `OPENAI_API_KEY`:

```bash
supabase secrets set OPENAI_API_KEY=sk-your-key-here
```

Or via Dashboard: Settings → Edge Functions → Secrets

---

## Changes Made in This Update

### Database Migration

New migration: `20251223_add_ai_recommended_exercises.sql`

```sql
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS ai_recommended_exercises JSONB DEFAULT NULL;
```

**Column Purpose:**
- `ai_recommended_exercises` (JSONB): Original exercise list from AI before user modifications
- `ai_reasoning` (text): AI's explanations for WHY exercises were selected

### Edge Function (`generate-workout/index.ts`)

1. **Session Creation**: Now only creates `sessions` record (no `session_exercises`)
2. **Separate Storage**:
   - `ai_recommended_exercises`: JSONB array of exercises (the WHAT)
   - `ai_reasoning`: Text with AI explanations (the WHY)
3. **Response Format**: Returns `ai_recommendations` object for client to display
4. **Exercise Rules**:
   - Always 6 exercises
   - Full body: 3 upper + 2 lower + 1 core
   - Non-full-body: compounds before isolation
   - Checks workout history for variety

### Client-Side Changes

| File | Change |
|------|--------|
| `ai_workout_remote_datasource.dart` | Parse `ai_recommendations` from response |
| `session_remote_datasource.dart` | `activateSession` now creates `session_exercises` |
| `session_repository.dart` | Added `exercises` parameter to `activateSession` |
| `session_repository_impl.dart` | Pass exercises through |
| `session_provider.dart` | `activateExistingSession` accepts exercises |
| `ai_exercise_review_screen.dart` | Pass exercises to activation |

---

## Testing the Flow

### 1. Test AI Generation

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate-workout \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "uuid",
    "programId": "uuid",
    "trainerId": "uuid",
    "primaryGoal": "hypertrophy"
  }'
```

Expected response:
```json
{
  "id": "session-uuid",
  "status": "scheduled",
  "ai_recommended_exercises": [...],
  "ai_reasoning": "...",
  "ai_recommendations": {
    "sessionName": "...",
    "sessionDescription": "...",
    "exercises": [...]
  }
}
```

### 2. Verify Database

After generation, check:
- `sessions` table has new row with `status='scheduled'`
- `sessions.ai_recommended_exercises` contains JSONB array of exercises
- `sessions.ai_reasoning` contains AI explanations
- `session_exercises` is EMPTY (created on activation)

After activation (clicking "Start Session"):
- `sessions.status` changes to `'active'`
- `session_exercises` has rows for each exercise (may differ from ai_recommended_exercises if user modified)

---

## Rollback Plan

If issues occur, revert to previous edge function version:

```bash
# List function versions
supabase functions list --project-ref YOUR_PROJECT_REF

# Deploy specific version
supabase functions deploy generate-workout --version 9 --project-ref YOUR_PROJECT_REF
```

Or restore from Git:
```bash
git checkout HEAD~1 -- supabase/functions/generate-workout/index.ts
supabase functions deploy generate-workout
```
