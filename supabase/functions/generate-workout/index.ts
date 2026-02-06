// Generate Workout Edge Function
// Uses OpenAI GPT-4 to create personalized workout sessions based on:
// 1. Client context (goals from accounts.fitness_goals, equipment, experience, injuries)
// 2. Workout history (recent sessions)
// 3. Program preferences (training split, focus areas, preferred movement groups)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface GenerateWorkoutRequest {
  clientId: string;
  trainerId: string;
  programId: string;
  trainingSplit?: string;
  focusAreas?: string[];
  preferredMovementGroups?: string[];
  sessionDurationMinutes?: number;
}

interface ClientContext {
  fitnessGoals: string[];
  experienceLevel: string;
  heightCm: number | null;
  weightKg: number | null;
  gender: string | null;
  limitations: string[];
}

interface RecentSession {
  id: string;
  focusArea: string | null;
  completedAt: string;
  exercises: Array<{
    exerciseId: string;
    exerciseName: string;
    category: string;
    movementGroup: string;
    movementDetail: string | null;
    muscleGroup: string;
  }>;
}

interface ProgramContext {
  trainingSplit: string;
  focusAreas: string[];
  preferredMovementGroups: string[];
  lastSessionFocus: string | null;
  muscleGroupHistory: Array<{ muscleGroup: string; date: string }>;
}

// Goal-based training parameters (research-backed)
const GOAL_PARAMETERS: Record<string, {
  reps: string;
  sets: number;
  restSeconds: number;
  targetRpe: number;
}> = {
  strength: { reps: '3-5', sets: 5, restSeconds: 180, targetRpe: 8 },
  hypertrophy: { reps: '8-12', sets: 4, restSeconds: 90, targetRpe: 7 },
  endurance: { reps: '15-20', sets: 3, restSeconds: 60, targetRpe: 6 },
  weight_loss: { reps: '12-15', sets: 3, restSeconds: 45, targetRpe: 7 },
  general_fitness: { reps: '10-12', sets: 3, restSeconds: 60, targetRpe: 7 },
  rehabilitation: { reps: '12-15', sets: 2, restSeconds: 90, targetRpe: 5 },
  athletic: { reps: '6-8', sets: 4, restSeconds: 120, targetRpe: 8 },
  athletic_performance: { reps: '6-8', sets: 4, restSeconds: 120, targetRpe: 8 },
};

// Movement group labels for UI
const MOVEMENT_GROUP_LABELS: Record<string, string> = {
  push: '밀기 (가슴/어깨/삼두)',
  pull: '당기기 (등/이두)',
  legs: '하체',
  core: '코어',
  other: '기타',
};

// Movement detail labels for more specific categorization
const MOVEMENT_DETAIL_LABELS: Record<string, string> = {
  horizontal: '수평',
  vertical: '수직',
  squat: '스쿼트',
  hinge: '힌지 (데드리프트류)',
  lunge: '런지',
  anti_extension: '항신전',
  anti_flexion: '항굴곡',
  anti_lateral_flexion: '항측굴',
  rotation: '회전',
};

serve(async (req: Request) => {
  const requestId = crypto.randomUUID().slice(0, 8);
  console.log(`[${requestId}] ====== GENERATE WORKOUT START ======`);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const request: GenerateWorkoutRequest = await req.json();
    const {
      clientId,
      trainerId,
      programId,
      trainingSplit: requestTrainingSplit,
      focusAreas: requestFocusAreas,
      preferredMovementGroups: requestMovementGroups,
      sessionDurationMinutes = 60
    } = request;

    console.log(`[${requestId}] Client: ${clientId}, Program: ${programId}`);
    console.log(`[${requestId}] Requested trainingSplit: ${requestTrainingSplit}`);
    console.log(`[${requestId}] Requested focusAreas: ${requestFocusAreas?.join(', ')}`);
    console.log(`[${requestId}] Requested movementGroups: ${requestMovementGroups?.join(', ')}`);

    // 1. Verify trainer authorization
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization token' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    // Verify trainer account
    const { data: account } = await supabase
      .from('accounts')
      .select('id, role')
      .eq('user_id', user.id)
      .single();

    if (!account || account.role !== 'trainer') {
      return new Response(
        JSON.stringify({ error: 'Only trainers can generate workouts' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      );
    }

    // Verify trainer-client relationship
    const { data: relation } = await supabase
      .from('trainer_client_relationships')
      .select('id')
      .eq('trainer_id', account.id)
      .eq('client_id', clientId)
      .eq('status', 'active')
      .single();

    if (!relation) {
      return new Response(
        JSON.stringify({ error: 'Not authorized for this client' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      );
    }

    const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured');
    }

    // 2. Fetch client context from accounts table (including fitness_goals as primary goal)
    console.log(`[${requestId}] Fetching client context...`);
    const clientContext = await fetchClientContext(supabase, clientId);

    // Determine primary goal from client's fitness_goals
    const primaryGoal = clientContext.fitnessGoals[0] || 'general_fitness';
    const secondaryGoal = clientContext.fitnessGoals[1] || null;
    console.log(`[${requestId}] Client's primary goal (from account): ${primaryGoal}`);
    console.log(`[${requestId}] Client's secondary goal (from account): ${secondaryGoal}`);

    // 3. Fetch program context (preferences)
    console.log(`[${requestId}] Fetching program context...`);
    const programContext = await fetchProgramContext(supabase, programId);

    // Merge request params with program context (request takes precedence)
    if (requestTrainingSplit) {
      programContext.trainingSplit = requestTrainingSplit;
    }
    if (requestFocusAreas && requestFocusAreas.length > 0) {
      programContext.focusAreas = requestFocusAreas;
    }
    if (requestMovementGroups && requestMovementGroups.length > 0) {
      programContext.preferredMovementGroups = requestMovementGroups;
    }

    console.log(`[${requestId}] Final trainingSplit: ${programContext.trainingSplit}`);
    console.log(`[${requestId}] Final focusAreas: ${programContext.focusAreas.join(', ')}`);
    console.log(`[${requestId}] Final preferredMovementGroups: ${programContext.preferredMovementGroups.join(', ')}`);

    // 4. Fetch recent sessions (last 5)
    console.log(`[${requestId}] Fetching recent sessions...`);
    const recentSessions = await fetchRecentSessions(supabase, clientId, 5);

    // 5. Calculate days since last session
    const daysSinceLastSession = calculateDaysSinceLastSession(recentSessions);
    console.log(`[${requestId}] Days since last session: ${daysSinceLastSession}`);

    // 6. Determine focus area based on split and history
    const focusArea = determineFocusArea(programContext, recentSessions);
    console.log(`[${requestId}] Determined focus area: ${focusArea}`);

    // 7. Fetch exercise library
    console.log(`[${requestId}] Fetching exercise library...`);
    const exercises = await fetchExerciseLibrary(supabase);

    // 8. Build prompt and call OpenAI
    console.log(`[${requestId}] Building prompt for OpenAI...`);
    const prompt = buildWorkoutPrompt({
      clientContext,
      programContext,
      recentSessions,
      daysSinceLastSession,
      focusArea,
      primaryGoal,
      secondaryGoal,
      sessionDurationMinutes,
      availableExercises: exercises,
    });

    console.log(`[${requestId}] Calling OpenAI...`);
    const workoutData = await callOpenAI(openaiApiKey, prompt);
    console.log(`[${requestId}] OpenAI response received`);

    // 8.5. Validate and fix exercise IDs (AI sometimes hallucinates/corrupts UUIDs)
    console.log(`[${requestId}] Validating exercise IDs...`);
    await validateAndFixExerciseIds(supabase, workoutData, exercises, requestId);

    // 9. Create session and session_exercises in database
    console.log(`[${requestId}] Saving session to database...`);
    const savedSession = await saveSessionToDatabase(
      supabase,
      clientId,
      account.id,
      programId,
      workoutData,
      focusArea,
      daysSinceLastSession
    );

    // 10. Update program's muscle group history and last session focus
    await updateProgramContext(supabase, programId, focusArea, workoutData.exercises);

    console.log(`[${requestId}] ====== GENERATE WORKOUT COMPLETE ======`);
    return new Response(JSON.stringify(savedSession), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error(`[${requestId}] Error:`, error);
    return new Response(
      JSON.stringify({ error: error.message || 'Failed to generate workout' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

async function fetchClientContext(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<ClientContext> {
  const { data, error } = await supabase
    .from('accounts')
    .select('fitness_goals, height_cm, weight_kg, gender')
    .eq('id', clientId)
    .single();

  if (error || !data) {
    return {
      fitnessGoals: [],
      experienceLevel: 'intermediate',
      heightCm: null,
      weightKg: null,
      gender: null,
      limitations: [],
    };
  }

  return {
    fitnessGoals: data.fitness_goals || [],
    experienceLevel: 'intermediate', // Could be added to accounts table
    heightCm: data.height_cm,
    weightKg: data.weight_kg,
    gender: data.gender,
    limitations: [], // Could be added to accounts table
  };
}

async function fetchProgramContext(
  supabase: ReturnType<typeof createClient>,
  programId: string
): Promise<ProgramContext> {
  const { data, error } = await supabase
    .from('workout_programs')
    .select('training_split, focus_areas, preferred_movement_groups, last_session_focus, muscle_group_history')
    .eq('id', programId)
    .single();

  if (error || !data) {
    return {
      trainingSplit: 'full_body',
      focusAreas: [],
      preferredMovementGroups: [],
      lastSessionFocus: null,
      muscleGroupHistory: [],
    };
  }

  return {
    trainingSplit: data.training_split || 'full_body',
    focusAreas: data.focus_areas || [],
    preferredMovementGroups: data.preferred_movement_groups || [],
    lastSessionFocus: data.last_session_focus,
    muscleGroupHistory: data.muscle_group_history || [],
  };
}

async function fetchRecentSessions(
  supabase: ReturnType<typeof createClient>,
  clientId: string,
  limit: number
): Promise<RecentSession[]> {
  const { data, error } = await supabase
    .from('sessions')
    .select(`
      id,
      focus_area,
      completed_at,
      session_exercises (
        exercise_id,
        exercises (
          name,
          name_ko,
          category,
          movement_group,
          movement_detail,
          muscle_group
        )
      )
    `)
    .eq('client_id', clientId)
    .eq('status', 'completed')
    .order('completed_at', { ascending: false })
    .limit(limit);

  if (error || !data) {
    return [];
  }

  return data.map((session: any) => ({
    id: session.id,
    focusArea: session.focus_area,
    completedAt: session.completed_at,
    exercises: (session.session_exercises || []).map((se: any) => ({
      exerciseId: se.exercise_id,
      exerciseName: se.exercises?.name_ko || se.exercises?.name || 'Unknown',
      category: se.exercises?.category || 'compound',
      movementGroup: se.exercises?.movement_group || 'other',
      movementDetail: se.exercises?.movement_detail || null,
      muscleGroup: se.exercises?.muscle_group || 'full_body',
    })),
  }));
}

function calculateDaysSinceLastSession(recentSessions: RecentSession[]): number {
  if (recentSessions.length === 0) return 7; // Default for new clients

  const lastSession = recentSessions[0];
  const lastDate = new Date(lastSession.completedAt);
  const now = new Date();
  const diffTime = now.getTime() - lastDate.getTime();
  return Math.floor(diffTime / (1000 * 60 * 60 * 24));
}

function determineFocusArea(programContext: ProgramContext, recentSessions: RecentSession[]): string {
  const { trainingSplit, lastSessionFocus } = programContext;

  // Split rotation logic
  const splitRotations: Record<string, string[]> = {
    full_body: ['full_body'],
    upper_lower: ['upper', 'lower'],
    push_pull_legs: ['push', 'pull', 'legs'],
    bro_split: ['chest', 'back', 'shoulders', 'arms', 'legs'],
  };

  const rotation = splitRotations[trainingSplit] || ['full_body'];

  if (rotation.length === 1) {
    return rotation[0];
  }

  // Find next in rotation based on last session
  if (!lastSessionFocus) {
    return rotation[0];
  }

  const currentIndex = rotation.indexOf(lastSessionFocus);
  const nextIndex = (currentIndex + 1) % rotation.length;
  return rotation[nextIndex];
}

async function fetchExerciseLibrary(
  supabase: ReturnType<typeof createClient>
): Promise<Array<{
  id: string;
  name: string;
  nameKo: string;
  category: string;
  movementGroup: string;
  movementDetail: string | null;
  muscleGroup: string;
  equipment: string;
  difficulty: string;
}>> {
  const { data, error } = await supabase
    .from('exercises')
    .select('id, name, name_ko, category, movement_group, movement_detail, muscle_group, equipment, difficulty');

  if (error || !data) {
    return [];
  }

  return data.map((e: any) => ({
    id: e.id,
    name: e.name,
    nameKo: e.name_ko || e.name,
    category: e.category || 'compound',
    movementGroup: e.movement_group || 'other',
    movementDetail: e.movement_detail || null,
    muscleGroup: e.muscle_group || 'full_body',
    equipment: e.equipment || 'bodyweight',
    difficulty: e.difficulty || 'intermediate',
  }));
}

function buildWorkoutPrompt(params: {
  clientContext: ClientContext;
  programContext: ProgramContext;
  recentSessions: RecentSession[];
  daysSinceLastSession: number;
  focusArea: string;
  primaryGoal: string;
  secondaryGoal: string | null;
  sessionDurationMinutes: number;
  availableExercises: Array<{ id: string; name: string; nameKo: string; category: string; movementGroup: string; movementDetail: string | null; muscleGroup: string; equipment: string; difficulty: string }>;
}): string {
  const {
    clientContext,
    programContext,
    recentSessions,
    daysSinceLastSession,
    focusArea,
    primaryGoal,
    secondaryGoal,
    sessionDurationMinutes,
    availableExercises,
  } = params;

  const goalKey = primaryGoal.toLowerCase().replace(/ /g, '_');
  const goalParams = GOAL_PARAMETERS[goalKey] || GOAL_PARAMETERS.general_fitness;

  // Get exercises from recent sessions to avoid
  const recentExerciseIds = new Set<string>();
  const mostRecentExercises: string[] = [];
  const secondRecentExercises: string[] = [];

  if (recentSessions[0]) {
    recentSessions[0].exercises.forEach(e => {
      recentExerciseIds.add(e.exerciseId);
      mostRecentExercises.push(e.exerciseName);
    });
  }
  if (recentSessions[1]) {
    recentSessions[1].exercises.forEach(e => {
      secondRecentExercises.push(e.exerciseName);
    });
  }

  // Build preferred movement groups instruction
  const preferredGroupsInstruction = programContext.preferredMovementGroups.length > 0
    ? `
## PREFERRED MOVEMENT GROUPS (PRIORITIZE THESE)
The client prefers these movement groups: **${programContext.preferredMovementGroups.join(', ')}**

When selecting exercises:
- PRIORITIZE exercises that match these movement groups
- Include at least 2-3 exercises from the preferred groups
- Explain in the reasoning why you selected exercises matching their preferences
- If an exercise matches a preferred group, mention it in the aiReasoning

Movement Group reference:
${Object.entries(MOVEMENT_GROUP_LABELS).map(([key, label]) => `- ${key}: ${label}`).join('\n')}
`
    : '';

  return `You are an expert personal trainer creating a personalized workout session.

## Client Profile
- Fitness Goals (from profile): ${clientContext.fitnessGoals.length > 0 ? clientContext.fitnessGoals.join(', ') : 'Not specified'}
- Experience Level: ${clientContext.experienceLevel}
- Gender: ${clientContext.gender || 'Not specified'}
- Limitations: ${clientContext.limitations.length > 0 ? clientContext.limitations.join(', ') : 'None'}

## Program Preferences
- Training Split: ${programContext.trainingSplit}
- Focus Areas (body parts to prioritize): ${programContext.focusAreas.length > 0 ? programContext.focusAreas.join(', ') : 'General fitness'}
- Today's Focus: ${focusArea}
- Days Since Last Session: ${daysSinceLastSession}
${preferredGroupsInstruction}
## SESSION TRAINING GOALS (USE THESE)
- Primary Goal: **${primaryGoal}** (from client's fitness goals)
- Secondary Goal: ${secondaryGoal || 'None'}
- Session Duration: ~${sessionDurationMinutes} minutes

## GOAL-BASED TRAINING PARAMETERS (MANDATORY)
Based on the primary goal "${primaryGoal}", use these parameters:
- Target Reps: ${goalParams.reps}
- Target Sets: ${goalParams.sets}
- Rest Between Sets: ${goalParams.restSeconds} seconds
- Target RPE: ${goalParams.targetRpe}/10

## RECOMMENDATION PRINCIPLES (Use as Contextual Guidance)

These principles should inform your reasoning - use them as knowledge, not rigid rules:

### Exercise Selection Philosophy
1. **Complementary Pairing**: Exercises that continue the same movement pattern work well together
   - Same movement group (push exercises flow naturally together)
   - Angle variations build complete muscle development (flat → incline → decline)
   - Family variations add stimulus variety (barbell → dumbbell → cable)

2. **Supplementary Finishing**: Isolation exercises finish what compounds start
   - Target the same prime muscle as the preceding compound
   - Use stable equipment (machines, cables) for safe muscle exhaustion
   - Consider secondary muscle overlap for efficient targeting

### Scoring Intuition (What Makes a "Good" Recommendation)
Think of these as weighted priorities:
- **Highest**: Does it fit today's split focus? (upper day = upper exercises)
- **High**: Is it NOT a recent repeat? (variety over repetition)
- **Medium-High**: Does it align with the client's goal? (strength = heavy compounds)
- **Medium**: Does it complement the previous exercise? (synergistic pairing)
- **Medium**: Does it match user preferences? (preferred equipment/muscles)
- **Lower**: Does it target the focus areas? (but don't over-prioritize)

### Split-Specific Wisdom
- **Upper/Lower**: Think "superset mentality" - push/pull alternation creates balance
- **PPL**: Each day is dedicated - go deep into that movement pattern
- **Full Body**: Distribution is key - ensure no region is overworked

### Compound-Isolation Flow
- Start with 2-3 compound movements (multi-joint, heavier loads)
- Finish with 2-3 isolation movements (single-joint, muscle exhaustion)
- This maximizes strength stimulus while fresh, then refines with isolation

### Variety Principles
- Avoid same exercise family twice (no 2 bench variations)
- Vary equipment when possible (barbell → dumbbell → machine)
- Consider what was done recently to ensure progressive variety

## RECENT WORKOUT HISTORY (CRITICAL FOR VARIETY)
${recentSessions.length > 0 ? `
### Most Recent Session (AVOID these exercises):
${mostRecentExercises.length > 0 ? mostRecentExercises.map(e => `- ${e}`).join('\n') : 'None'}

### Second Recent Session (LIMIT overlap to max 1 exercise):
${secondRecentExercises.length > 0 ? secondRecentExercises.map(e => `- ${e}`).join('\n') : 'None'}
` : 'No recent sessions - this is the first workout for this client.'}

## Instructions
Create a SINGLE training session with:
1. **EXACTLY 6 EXERCISES** - no more, no less
2. Use the GOAL-BASED PARAMETERS above for sets, reps, rest, and RPE
3. Detailed reasoning for why each exercise was selected

## EXERCISE DISTRIBUTION (MANDATORY)
For FULL BODY / GENERAL FITNESS sessions, follow this EXACT distribution:
- **3 UPPER BODY exercises**: Mix of push and pull movements (chest press, rows, shoulder press, pull-ups/pulldowns)
- **2 LOWER BODY exercises**: Squat, hinge, or lunge movements (leg press, squat, deadlift, RDL, hip thrust, lunge, leg curl, leg extension)
- **1 CORE exercise**: Core stability or rotation (plank, dead bug, pallof press, cable crunch, etc.)

For NON-FULL-BODY sessions (hypertrophy, strength, muscle-specific splits):
- Maintain exactly 6 exercises with appropriate muscle group focus
- **ORDER FROM COMPOUND TO ISOLATION (MANDATORY)**:
  1. Start with heavy compound movements (multi-joint exercises: squat, deadlift, bench press, rows, pull-ups)
  2. Progress to secondary compounds (lunges, incline press, cable rows)
  3. Finish with isolation exercises (curls, extensions, lateral raises, flyes)
- This order maximizes strength output when fresh and allows targeted muscle fatigue at the end

${programContext.focusAreas && programContext.focusAreas.length > 0 ? `
## FOCUS AREA EMPHASIS (IMPORTANT)
The client wants EXTRA emphasis on these body parts: **${programContext.focusAreas.join(', ')}**

When selecting exercises, apply this emphasis:
- Prioritize compound exercises that heavily involve the focus muscle groups
- When choosing between similar exercises, prefer variations that better target the focus areas
- Include at least one isolation exercise specifically for a focus area
- Example: If focus is "legs", prefer Barbell Squat over Leg Press for better engagement
- Reflect this emphasis in your exercise reasoning explanations
` : ''}
## WORKOUT HISTORY CONTEXT (CRITICAL)
ALWAYS analyze the client's workout history before selecting exercises:
1. Review the exercises from recent sessions above
2. Create CONTEXTUAL PROGRESSION: If client did bench press last session, consider incline press or dumbbell variation this session
3. Ensure MOVEMENT GROUP VARIETY across sessions - don't repeat the same groups consecutively
4. Track which muscle groups were heavily trained recently and balance accordingly

CRITICAL RULES:
1. **ALWAYS 6 EXERCISES** - This is mandatory, not a suggestion
2. Use the exact sets (${goalParams.sets}), reps (${goalParams.reps}), rest (${goalParams.restSeconds}s), and RPE (${goalParams.targetRpe}) from goal parameters
3. NEVER repeat exercises from the most recent session
4. Limit overlap with 2nd most recent session to maximum 1 exercise
5. First exercise should be a compound movement
6. Consider the client's limitations
7. **exerciseId MUST be the exact UUID** from exerciseId="..." in the Available Exercises list - NOT the exercise name or an index number
${programContext.preferredMovementGroups.length > 0 ? `8. PRIORITIZE exercises matching preferred movement groups: ${programContext.preferredMovementGroups.join(', ')}` : ''}

## Available Exercises
Each exercise below has a UUID that you MUST use as the exerciseId in your response.
Format: exerciseId="UUID" | name="Name" | category | movementGroup | muscleGroup

${availableExercises.slice(0, 60).map(e => `exerciseId="${e.id}" | name="${e.nameKo}" | ${e.category} | ${e.movementGroup}${e.movementDetail ? '/' + e.movementDetail : ''} | ${e.muscleGroup}`).join('\n')}

Respond with a JSON object in this exact format:
{
  "sessionName": "string",
  "sessionDescription": "string",
  "exercises": [
    {
      "exerciseId": "MUST be UUID from exerciseId=\\\"...\\\" above (e.g., 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'), NOT the name",
      "exerciseName": "string",
      "bodyCategory": "upper_body|lower_body|core",
      "exerciseType": "compound|isolation",
      "orderIndex": 0,
      "targetSets": ${goalParams.sets},
      "targetReps": "${goalParams.reps}",
      "targetRpe": ${goalParams.targetRpe},
      "restSeconds": ${goalParams.restSeconds},
      "notes": "string (optional)",
      "aiReasoning": {
        "reasons": [
          {
            "category": "goal_alignment|progressive_overload|workout_history_context|movement_group_preference|complementary_pairing|variety_principle",
            "explanation": "string (Use RECOMMENDATION PRINCIPLES to explain WHY - e.g., 'Barbell row complements bench press - pulling balances pushing for shoulder health')",
            "explanationKo": "string (Korean translation of explanation)"
          }
        ],
        "historyConsideration": "string (explain how this exercise fits with recent workout history and the variety principles)"
      }
    }
  ]
}

VALIDATION CHECK BEFORE RESPONDING:
- Count exercises: Must be exactly 6
- For full body: Verify 3 upper_body + 2 lower_body + 1 core
- For non-full-body: Verify compound exercises come before isolation exercises
- Confirm no exercises repeat from most recent session
${programContext.preferredMovementGroups.length > 0 ? `- Verify at least 2-3 exercises match preferred movement groups: ${programContext.preferredMovementGroups.join(', ')}` : ''}`;
}

async function callOpenAI(apiKey: string, prompt: string): Promise<any> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are an expert personal trainer with deep knowledge of exercise science and programming principles. Use the RECOMMENDATION PRINCIPLES provided in the prompt to guide your exercise selection and explain your reasoning. Always respond with valid JSON only, no markdown formatting.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.7,
      max_tokens: 4000,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${error}`);
  }

  const data = await response.json();
  const content = data.choices[0]?.message?.content;

  if (!content) {
    throw new Error('No content in OpenAI response');
  }

  return JSON.parse(content);
}

/**
 * Validate exercise IDs from OpenAI response and fix any invalid ones
 * AI models sometimes hallucinate or corrupt UUIDs (e.g., '1' becomes 'l')
 */
async function validateAndFixExerciseIds(
  supabase: ReturnType<typeof createClient>,
  workoutData: any,
  availableExercises: Array<{ id: string; name: string; nameKo: string }>,
  requestId: string
): Promise<void> {
  if (!workoutData.exercises || workoutData.exercises.length === 0) {
    return;
  }

  // Build lookup maps for quick validation
  const validIds = new Set(availableExercises.map(e => e.id));
  const nameToId = new Map<string, string>();
  const nameKoToId = new Map<string, string>();

  for (const e of availableExercises) {
    nameToId.set(e.name.toLowerCase(), e.id);
    nameKoToId.set(e.nameKo.toLowerCase(), e.id);
  }

  // Validate each exercise
  for (const exercise of workoutData.exercises) {
    const originalId = exercise.exerciseId;

    // Check if ID is valid
    if (validIds.has(originalId)) {
      continue; // Valid ID, no fix needed
    }

    console.log(`[${requestId}] ⚠️ Invalid exercise ID detected: ${originalId} for "${exercise.exerciseName}"`);

    // Try to find correct ID by name
    const exerciseName = exercise.exerciseName?.toLowerCase() || '';
    let correctedId = nameKoToId.get(exerciseName) || nameToId.get(exerciseName);

    // If exact match fails, try partial match
    if (!correctedId) {
      for (const [name, id] of nameKoToId.entries()) {
        if (name.includes(exerciseName) || exerciseName.includes(name)) {
          correctedId = id;
          break;
        }
      }
    }

    if (correctedId) {
      console.log(`[${requestId}] ✅ Auto-corrected to: ${correctedId}`);
      exercise.exerciseId = correctedId;
    } else {
      // Last resort: check if ID differs by common OCR-like errors (l/1, 0/O)
      const possibleCorrections = [
        originalId.replace(/l/g, '1'), // l -> 1
        originalId.replace(/O/gi, '0'), // O -> 0
        originalId.replace(/l/g, '1').replace(/O/gi, '0'),
      ];

      for (const corrected of possibleCorrections) {
        if (validIds.has(corrected)) {
          console.log(`[${requestId}] ✅ OCR-corrected from "${originalId}" to: ${corrected}`);
          exercise.exerciseId = corrected;
          break;
        }
      }

      // If still not found, throw error
      if (!validIds.has(exercise.exerciseId)) {
        throw new Error(`Invalid exercise ID "${originalId}" for "${exercise.exerciseName}" - could not auto-correct. Please retry.`);
      }
    }
  }
}

async function saveSessionToDatabase(
  supabase: ReturnType<typeof createClient>,
  clientId: string,
  trainerId: string,
  programId: string,
  workoutData: any,
  focusArea: string,
  daysSinceLastSession: number
): Promise<any> {
  const sessionId = crypto.randomUUID();

  // Separate storage for exercises vs reasoning:
  // - ai_recommended_exercises (JSONB): Original exercise list before user modifications
  // - ai_reasoning (text): AI's explanations for WHY these exercises were selected

  // Extract exercise list for ai_recommended_exercises column
  const aiRecommendedExercises = (workoutData.exercises || []).map((exercise: any) => ({
    exerciseId: exercise.exerciseId,
    exerciseName: exercise.exerciseName,
    bodyCategory: exercise.bodyCategory,
    exerciseType: exercise.exerciseType,
    orderIndex: exercise.orderIndex,
    targetSets: exercise.targetSets,
    targetReps: exercise.targetReps,
    targetRpe: exercise.targetRpe,
    restSeconds: exercise.restSeconds,
  }));

  // Extract reasoning for ai_reasoning column
  const aiReasoning = {
    sessionName: workoutData.sessionName,
    sessionDescription: workoutData.sessionDescription,
    generatedAt: new Date().toISOString(),
    exerciseReasonings: (workoutData.exercises || []).map((exercise: any) => ({
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      aiReasoning: exercise.aiReasoning,
    })),
  };

  // Create session record only (no session_exercises yet)
  // User can modify exercises in review screen before confirming
  const { error: sessionError } = await supabase.from('sessions').insert({
    id: sessionId,
    client_id: clientId,
    trainer_id: trainerId,
    program_id: programId,
    session_type: 'training',
    status: 'scheduled',
    focus_area: focusArea,
    days_since_last: daysSinceLastSession,
    ai_recommended_exercises: aiRecommendedExercises, // JSONB - original exercise list
    ai_reasoning: JSON.stringify(aiReasoning), // text - AI explanations
    scheduled_at: new Date().toISOString(),
  });

  if (sessionError) {
    throw new Error(`Failed to create session: ${sessionError.message}`);
  }

  // Return session with AI recommendations (no session_exercises yet)
  const { data: savedSession } = await supabase
    .from('sessions')
    .select('*')
    .eq('id', sessionId)
    .single();

  // Return response with both exercises and reasoning for client
  return {
    ...savedSession,
    ai_recommendations: {
      sessionName: aiReasoning.sessionName,
      sessionDescription: aiReasoning.sessionDescription,
      exercises: aiRecommendedExercises.map((exercise: any, index: number) => ({
        ...exercise,
        aiReasoning: aiReasoning.exerciseReasonings[index]?.aiReasoning,
      })),
    },
  };
}

async function updateProgramContext(
  supabase: ReturnType<typeof createClient>,
  programId: string,
  focusArea: string,
  exercises: Array<{ exerciseId: string; bodyCategory?: string }>
): Promise<void> {
  // Get current muscle group history
  const { data: program } = await supabase
    .from('workout_programs')
    .select('muscle_group_history, total_sessions')
    .eq('id', programId)
    .single();

  const currentHistory = program?.muscle_group_history || [];
  const today = new Date().toISOString().split('T')[0];

  // Add today's muscle groups
  const muscleGroups = [...new Set(exercises.map(e => e.bodyCategory).filter(Boolean))];
  const newEntries = muscleGroups.map(mg => ({ muscleGroup: mg, date: today }));

  // Keep only last 10 entries
  const updatedHistory = [...newEntries, ...currentHistory].slice(0, 10);

  // Update program
  await supabase
    .from('workout_programs')
    .update({
      last_session_focus: focusArea,
      muscle_group_history: updatedHistory,
      total_sessions: (program?.total_sessions || 0) + 1,
    })
    .eq('id', programId);
}
