// Generate Workout Edge Function
// Uses OpenAI GPT-4 to create personalized workout programs based on:
// 1. Client context (goals, equipment, experience, injuries)
// 2. Workout history (last 30 days)
// 3. Session feedback (difficulty ratings, swaps, trainer notes)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

interface GenerateWorkoutRequest {
  action?: 'generate' | 'createTemplate' | 'applyTemplate';
  // Generate action params
  clientId?: string;
  trainerId?: string;
  primaryGoal?: string;
  secondaryGoal?: string;
  durationWeeks?: number;
  sessionsPerWeek?: number;
  excludedExerciseIds?: string[];
  preferredEquipment?: string[];
  sessionDurationMinutes?: number;
  // Template action params
  programId?: string;
  templateName?: string;
  templateDescription?: string;
  templateId?: string;
  customizationNotes?: string;
}

interface ClientContext {
  fitnessGoals: string[];
  availableEquipment: string[];
  experienceLevel: string;
  injuryHistory: Array<{ area: string; severity: string; notes?: string }>;
  limitations: string[];
  preferences: Record<string, unknown>;
}

interface WorkoutHistory {
  recentSessions: Array<{
    date: string;
    exercises: Array<{
      name: string;
      sets: Array<{ weight: number; reps: number; rpe?: number }>;
    }>;
  }>;
  personalRecords: Array<{
    exerciseName: string;
    weight: number;
    reps: number;
    date: string;
  }>;
  volumeTrends: {
    weeklyVolume: number[];
    trend: 'increasing' | 'stable' | 'decreasing';
  };
}

interface SessionFeedback {
  difficultyFeedback: Array<{
    exerciseName: string;
    feedback: string;
    frequency: number;
  }>;
  swapHistory: Array<{
    originalExercise: string;
    replacementExercise: string;
    reason?: string;
  }>;
  rpePatterns: {
    averageRpe: number;
    trend: 'increasing' | 'stable' | 'decreasing';
  };
}

interface ExerciseFamiliarity {
  exerciseId: string;
  exerciseName: string;
  familiarityScore: number;
  timesPerformed: number;
  isMastered: boolean;
}

interface PreviousSession {
  id: string;
  primaryGoal: string;
  createdAt: string;
  exercises: Array<{
    exerciseId: string;
    exerciseName: string;
    movementPattern: string;
  }>;
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
  athletic_performance: { reps: '6-8', sets: 4, restSeconds: 120, targetRpe: 8 },
};

// New exercise limits based on client training age
const NEW_EXERCISE_LIMITS: Record<string, number> = {
  beginner: 2,      // 0-4 weeks
  intermediate: 3,  // 4-8 weeks
  advanced: 4,      // 8+ weeks
};

serve(async (req: Request) => {
  const requestId = crypto.randomUUID().slice(0, 8);
  console.log(`[${requestId}] ====== EDGE FUNCTION START ======`);
  console.log(`[${requestId}] Method: ${req.method}`);
  console.log(`[${requestId}] Timestamp: ${new Date().toISOString()}`);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    console.log(`[${requestId}] CORS preflight request - returning OK`);
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log(`[${requestId}] Creating Supabase client...`);
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const request: GenerateWorkoutRequest = await req.json();
    const action = request.action || 'generate';
    console.log(`[${requestId}] Action: ${action}`);
    console.log(`[${requestId}] ClientId: ${request.clientId}`);
    console.log(`[${requestId}] PrimaryGoal: ${request.primaryGoal}`);

    // 0. Verify trainer authorization (required for all actions)
    console.log(`[${requestId}] Checking authorization...`);
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      console.log(`[${requestId}] ERROR: No authorization header`);
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.log(`[${requestId}] ERROR: Invalid token - ${authError?.message}`);
      return new Response(
        JSON.stringify({ error: 'Invalid authorization token' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 401 }
      );
    }
    console.log(`[${requestId}] User authenticated: ${user.id}`);

    // Verify the user is a trainer
    const { data: account, error: accountError } = await supabase
      .from('accounts')
      .select('id, role')
      .eq('user_id', user.id)
      .single();

    if (accountError || !account) {
      console.log(`[${requestId}] ERROR: Account not found - ${accountError?.message}`);
      return new Response(
        JSON.stringify({ error: 'Account not found' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
      );
    }

    if (account.role !== 'trainer') {
      console.log(`[${requestId}] ERROR: User is not a trainer (role: ${account.role})`);
      return new Response(
        JSON.stringify({ error: 'Only trainers can manage workout programs' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
      );
    }
    console.log(`[${requestId}] Trainer verified: ${account.id}`);

    // Route to appropriate handler based on action
    console.log(`[${requestId}] Routing to handler: ${action}`);
    switch (action) {
      case 'createTemplate':
        return await handleCreateTemplate(supabase, account.id, request);

      case 'applyTemplate':
        return await handleApplyTemplate(supabase, account.id, request);

      case 'generate':
      default:
        const result = await handleGenerateWorkout(supabase, account.id, request);
        console.log(`[${requestId}] ====== EDGE FUNCTION END (SUCCESS) ======`);
        return result;
    }
  } catch (error) {
    console.error(`[${requestId}] ====== EDGE FUNCTION ERROR ======`);
    console.error(`[${requestId}] Error:`, error);
    return new Response(
      JSON.stringify({ error: error.message || 'Failed to process request' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

// Fetch previous programs for context (avoid exercise overlap)
async function fetchPreviousPrograms(
  supabase: ReturnType<typeof createClient>,
  clientId: string,
  limit: number = 3
): Promise<PreviousSession[]> {
  const { data, error } = await supabase
    .from('workout_programs')
    .select(`
      id,
      primary_goal,
      created_at,
      workout_days (
        program_exercises (
          exercise_id,
          exercises!program_exercises_exercise_id_fkey (
            name,
            name_ko,
            movement_pattern
          )
        )
      )
    `)
    .eq('client_id', clientId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching previous programs:', error);
    return [];
  }

  return (data || []).map((program: any) => {
    const exercises: Array<{ exerciseId: string; exerciseName: string; movementPattern: string }> = [];

    for (const day of program.workout_days || []) {
      for (const pe of day.program_exercises || []) {
        if (pe.exercise_id && pe.exercises) {
          exercises.push({
            exerciseId: pe.exercise_id,
            exerciseName: pe.exercises.name_ko || pe.exercises.name,
            movementPattern: pe.exercises.movement_pattern || 'other',
          });
        }
      }
    }

    return {
      id: program.id,
      primaryGoal: program.primary_goal,
      createdAt: program.created_at,
      exercises,
    };
  });
}

// Handler for generating a new workout program
async function handleGenerateWorkout(
  supabase: ReturnType<typeof createClient>,
  trainerId: string,
  request: GenerateWorkoutRequest
): Promise<Response> {
  const handlerId = crypto.randomUUID().slice(0, 8);
  console.log(`[HANDLER-${handlerId}] Starting handleGenerateWorkout...`);

  const {
    clientId,
    primaryGoal,
    secondaryGoal,
    excludedExerciseIds = [],
    preferredEquipment = [],
    sessionDurationMinutes = 60,
  } = request;

  // Always generate single session (1 week, 1 session)
  const durationWeeks = 1;
  const sessionsPerWeek = 1;

  console.log(`[HANDLER-${handlerId}] Params: clientId=${clientId}, goal=${primaryGoal}, trainer=${trainerId}`);

  if (!clientId || !primaryGoal) {
    console.log(`[HANDLER-${handlerId}] ERROR: Missing required params`);
    return new Response(
      JSON.stringify({ error: 'clientId and primaryGoal are required' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }

  const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openaiApiKey) {
    console.log(`[HANDLER-${handlerId}] ERROR: OPENAI_API_KEY not configured`);
    throw new Error('OPENAI_API_KEY not configured');
  }
  console.log(`[HANDLER-${handlerId}] OpenAI API key found`);

  // Verify trainer owns this client relationship
  console.log(`[HANDLER-${handlerId}] Checking trainer-client relationship...`);
  const { data: clientRelation, error: relationError } = await supabase
    .from('trainer_client_relationships')
    .select('id')
    .eq('trainer_id', trainerId)
    .eq('client_id', clientId)
    .eq('status', 'active')
    .single();

  if (relationError || !clientRelation) {
    console.log(`[HANDLER-${handlerId}] ERROR: Trainer-client relationship not found - ${relationError?.message}`);
    return new Response(
      JSON.stringify({ error: 'You are not authorized to create programs for this client' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
    );
  }
  console.log(`[HANDLER-${handlerId}] Trainer-client relationship verified: ${clientRelation.id}`);

  // 1. Fetch Client Context
  console.log(`[HANDLER-${handlerId}] Fetching client context...`);
  const clientContext = await fetchClientContext(supabase, clientId);
  console.log(`[HANDLER-${handlerId}] Client context fetched: experienceLevel=${clientContext.experienceLevel}`);

  // 2. Fetch Workout History (last 30 days)
  console.log(`[HANDLER-${handlerId}] Fetching workout history...`);
  const workoutHistory = await fetchWorkoutHistory(supabase, clientId);
  console.log(`[HANDLER-${handlerId}] Workout history: ${workoutHistory.recentSessions.length} sessions`);

  // 3. Fetch Session Feedback
  console.log(`[HANDLER-${handlerId}] Fetching session feedback...`);
  const sessionFeedback = await fetchSessionFeedback(supabase, clientId);

  // 4. Fetch Exercise Familiarity
  console.log(`[HANDLER-${handlerId}] Fetching exercise familiarity...`);
  const exerciseFamiliarity = await fetchExerciseFamiliarity(supabase, clientId);
  console.log(`[HANDLER-${handlerId}] Exercise familiarity: ${exerciseFamiliarity.length} exercises known`);

  // 5. Calculate client training age
  console.log(`[HANDLER-${handlerId}] Calculating training age...`);
  const trainingAgeWeeks = await calculateTrainingAge(supabase, clientId);
  console.log(`[HANDLER-${handlerId}] Training age: ${trainingAgeWeeks} weeks`);

  // 6. Fetch Exercise Library
  console.log(`[HANDLER-${handlerId}] Fetching exercise library...`);
  const exercises = await fetchExerciseLibrary(supabase, excludedExerciseIds);
  console.log(`[HANDLER-${handlerId}] Exercise library: ${exercises.length} exercises available`);

  // 7. Fetch Previous Programs for context (avoid exercise overlap)
  console.log(`[HANDLER-${handlerId}] Fetching previous programs...`);
  const previousPrograms = await fetchPreviousPrograms(supabase, clientId);
  console.log(`[HANDLER-${handlerId}] Previous programs: ${previousPrograms.length} found`);

  // 8. Build comprehensive prompt for GPT-4
  console.log(`[HANDLER-${handlerId}] Building prompt for OpenAI...`);
  const prompt = buildWorkoutPrompt({
    clientContext,
    workoutHistory,
    sessionFeedback,
    exerciseFamiliarity,
    trainingAgeWeeks,
    primaryGoal,
    secondaryGoal,
    durationWeeks,
    sessionsPerWeek,
    preferredEquipment,
    sessionDurationMinutes,
    availableExercises: exercises,
    previousPrograms,
  });
  console.log(`[HANDLER-${handlerId}] Prompt built: ${prompt.length} characters`);

  // 8. Call OpenAI GPT-4
  console.log(`[HANDLER-${handlerId}] >>>>>> CALLING OPENAI API (gpt-4o-mini) <<<<<<`);
  const openaiStartTime = Date.now();
  const workoutProgram = await callOpenAI(openaiApiKey, prompt);
  const openaiDuration = Date.now() - openaiStartTime;
  console.log(`[HANDLER-${handlerId}] OpenAI response received in ${openaiDuration}ms`);
  console.log(`[HANDLER-${handlerId}] Program name: ${workoutProgram.programName}`);
  console.log(`[HANDLER-${handlerId}] Exercises count: ${workoutProgram.workoutDays?.[0]?.exercises?.length || 0}`);

  // 9. Save program to database
  console.log(`[HANDLER-${handlerId}] >>>>>> SAVING TO DATABASE <<<<<<`);
  const savedProgram = await saveProgramToDatabase(
    supabase,
    clientId,
    trainerId,
    workoutProgram,
    primaryGoal,
    secondaryGoal,
    durationWeeks,
    sessionsPerWeek
  );
  console.log(`[HANDLER-${handlerId}] Program saved with ID: ${savedProgram?.id}`);
  console.log(`[HANDLER-${handlerId}] AI Model Version: ${savedProgram?.ai_model_version}`);

  console.log(`[HANDLER-${handlerId}] >>>>>> RETURNING SUCCESS RESPONSE <<<<<<`);
  return new Response(JSON.stringify(savedProgram), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 200,
  });
}

// Handler for creating a template from an existing program
async function handleCreateTemplate(
  supabase: ReturnType<typeof createClient>,
  trainerId: string,
  request: GenerateWorkoutRequest
): Promise<Response> {
  const { programId, templateName, templateDescription } = request;

  if (!programId || !templateName) {
    return new Response(
      JSON.stringify({ error: 'programId and templateName are required' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }

  // Fetch the existing program with all its data
  const { data: program, error: programError } = await supabase
    .from('workout_programs')
    .select(`
      *,
      workout_days (
        *,
        program_exercises (
          *,
          exercises (id, name, name_ko)
        )
      )
    `)
    .eq('id', programId)
    .eq('trainer_id', trainerId)
    .single();

  if (programError || !program) {
    return new Response(
      JSON.stringify({ error: 'Program not found or you do not have access' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
    );
  }

  // Create template data snapshot (anonymized, without client-specific info)
  const templateData = {
    workoutDays: program.workout_days.map((day: any) => ({
      dayNumber: day.day_number,
      name: day.name,
      focusArea: day.focus_area,
      estimatedDurationMinutes: day.estimated_duration_minutes,
      exercises: day.program_exercises.map((pe: any) => ({
        exerciseId: pe.exercise_id,
        exerciseName: pe.exercises?.name_ko || pe.exercises?.name,
        orderIndex: pe.order_index,
        targetSets: pe.target_sets,
        targetReps: pe.target_reps,
        targetRpe: pe.target_rpe,
        restSeconds: pe.rest_seconds,
        notes: pe.notes,
      })),
    })),
  };

  // Create the template
  const templateId = crypto.randomUUID();
  const { error: insertError } = await supabase.from('program_templates').insert({
    id: templateId,
    trainer_id: trainerId,
    name: templateName,
    description: templateDescription || program.description,
    source_program_id: programId,
    primary_goal: program.primary_goal,
    secondary_goal: program.secondary_goal,
    duration_weeks: program.duration_weeks,
    sessions_per_week: program.sessions_per_week,
    template_data: templateData,
    usage_count: 0,
    is_public: false,
  });

  if (insertError) {
    console.error('Error creating template:', insertError);
    return new Response(
      JSON.stringify({ error: 'Failed to create template' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }

  // Fetch and return the created template
  const { data: template } = await supabase
    .from('program_templates')
    .select('*')
    .eq('id', templateId)
    .single();

  return new Response(JSON.stringify(template), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 201,
  });
}

// Handler for applying a template to a new client
async function handleApplyTemplate(
  supabase: ReturnType<typeof createClient>,
  trainerId: string,
  request: GenerateWorkoutRequest
): Promise<Response> {
  const { templateId, clientId, customizationNotes } = request;

  if (!templateId || !clientId) {
    return new Response(
      JSON.stringify({ error: 'templateId and clientId are required' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }

  // Verify trainer owns this client relationship
  const { data: clientRelation, error: relationError } = await supabase
    .from('trainer_client_relationships')
    .select('id')
    .eq('trainer_id', trainerId)
    .eq('client_id', clientId)
    .eq('status', 'active')
    .single();

  if (relationError || !clientRelation) {
    return new Response(
      JSON.stringify({ error: 'You are not authorized to create programs for this client' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 403 }
    );
  }

  // Fetch the template
  const { data: template, error: templateError } = await supabase
    .from('program_templates')
    .select('*')
    .eq('id', templateId)
    .eq('trainer_id', trainerId)
    .single();

  if (templateError || !template) {
    return new Response(
      JSON.stringify({ error: 'Template not found or you do not have access' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
    );
  }

  // Create a new program from the template
  const programId = crypto.randomUUID();
  const { error: programError } = await supabase.from('workout_programs').insert({
    id: programId,
    client_id: clientId,
    trainer_id: trainerId,
    name: template.name,
    description: template.description,
    primary_goal: template.primary_goal,
    secondary_goal: template.secondary_goal,
    duration_weeks: template.duration_weeks,
    sessions_per_week: template.sessions_per_week,
    status: 'draft',
    is_ai_generated: false,
    customization_count: 0,
  });

  if (programError) {
    console.error('Error creating program from template:', programError);
    return new Response(
      JSON.stringify({ error: 'Failed to create program' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }

  // Create workout days and exercises from template data
  const templateData = template.template_data;
  for (const day of templateData.workoutDays || []) {
    const dayId = crypto.randomUUID();
    await supabase.from('workout_days').insert({
      id: dayId,
      program_id: programId,
      day_number: day.dayNumber,
      name: day.name,
      focus_area: day.focusArea,
      estimated_duration_minutes: day.estimatedDurationMinutes,
    });

    for (const exercise of day.exercises || []) {
      await supabase.from('program_exercises').insert({
        id: crypto.randomUUID(),
        workout_day_id: dayId,
        exercise_id: exercise.exerciseId,
        order_index: exercise.orderIndex,
        target_sets: exercise.targetSets,
        target_reps: exercise.targetReps,
        target_rpe: exercise.targetRpe,
        rest_seconds: exercise.restSeconds,
        notes: exercise.notes,
      });
    }
  }

  // Track template usage
  await supabase.from('template_usage').insert({
    id: crypto.randomUUID(),
    template_id: templateId,
    program_id: programId,
    client_id: clientId,
    trainer_id: trainerId,
    customization_notes: customizationNotes,
    customization_count: 0,
  });

  // Increment template usage count
  await supabase
    .from('program_templates')
    .update({ usage_count: (template.usage_count || 0) + 1 })
    .eq('id', templateId);

  // Fetch and return the created program
  const { data: savedProgram } = await supabase
    .from('workout_programs')
    .select(`
      *,
      workout_days (
        *,
        program_exercises (
          *,
          exercises (id, name, name_ko)
        )
      )
    `)
    .eq('id', programId)
    .single();

  return new Response(JSON.stringify(savedProgram), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 201,
  });
}

async function fetchClientContext(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<ClientContext> {
  const { data, error } = await supabase
    .from('ai_generation_context')
    .select('*')
    .eq('client_id', clientId)
    .single();

  if (error || !data) {
    // Return defaults if no context exists
    return {
      fitnessGoals: [],
      availableEquipment: [],
      experienceLevel: 'intermediate',
      injuryHistory: [],
      limitations: [],
      preferences: {},
    };
  }

  return {
    fitnessGoals: data.fitness_goals || [],
    availableEquipment: data.available_equipment || [],
    experienceLevel: data.experience_level || 'intermediate',
    injuryHistory: data.injury_history || [],
    limitations: data.limitations || [],
    preferences: data.preferences || {},
  };
}

async function fetchWorkoutHistory(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<WorkoutHistory> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  // Fetch recent sessions
  // Note: sets are stored as JSONB in session_exercises.sets, not in a separate table
  const { data: sessions, error } = await supabase
    .from('sessions')
    .select(`
      id,
      started_at,
      session_exercises (
        id,
        sets,
        exercises (name, name_ko)
      )
    `)
    .eq('client_id', clientId)
    .eq('status', 'completed')
    .gte('started_at', thirtyDaysAgo.toISOString())
    .order('started_at', { ascending: false })
    .limit(20);

  if (error) {
    console.error('Error fetching workout history:', error);
    return {
      recentSessions: [],
      personalRecords: [],
      volumeTrends: { weeklyVolume: [], trend: 'stable' },
    };
  }

  // Transform sessions data
  // sets is a JSONB array stored directly in session_exercises
  const recentSessions = (sessions || []).map((session: any) => ({
    date: session.started_at,
    exercises: (session.session_exercises || []).map((se: any) => ({
      name: se.exercises?.name_ko || se.exercises?.name || 'Unknown',
      sets: (se.sets || []).map((set: any) => ({
        weight: set.weight || 0,
        reps: set.reps || 0,
        rpe: set.rpe,
      })),
    })),
  }));

  // Calculate personal records
  const personalRecords = extractPersonalRecords(recentSessions);

  // Calculate volume trends
  const volumeTrends = calculateVolumeTrends(recentSessions);

  return {
    recentSessions,
    personalRecords,
    volumeTrends,
  };
}

async function fetchSessionFeedback(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<SessionFeedback> {
  // Fetch difficulty feedback
  const { data: feedback } = await supabase
    .from('session_exercise_feedback')
    .select(`
      feedback,
      exercises (name, name_ko),
      session_exercises!inner (
        sessions!inner (client_id)
      )
    `)
    .eq('session_exercises.sessions.client_id', clientId)
    .limit(100);

  // Fetch swap history
  const { data: swaps } = await supabase
    .from('exercise_swap_history')
    .select(`
      feedback_reason,
      custom_reason,
      original_exercise:exercises!exercise_swap_history_original_exercise_id_fkey (name, name_ko),
      replacement_exercise:exercises!exercise_swap_history_replacement_exercise_id_fkey (name, name_ko)
    `)
    .eq('client_id', clientId)
    .order('swapped_at', { ascending: false })
    .limit(20);

  // Aggregate difficulty feedback
  const feedbackMap = new Map<string, { feedback: string; count: number }[]>();
  (feedback || []).forEach((f: any) => {
    const exerciseName = f.exercises?.name_ko || f.exercises?.name || 'Unknown';
    if (!feedbackMap.has(exerciseName)) {
      feedbackMap.set(exerciseName, []);
    }
    feedbackMap.get(exerciseName)!.push({ feedback: f.feedback, count: 1 });
  });

  const difficultyFeedback = Array.from(feedbackMap.entries()).map(
    ([exerciseName, feedbacks]) => {
      const mostCommon = feedbacks.reduce((acc, curr) => {
        acc[curr.feedback] = (acc[curr.feedback] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);
      const topFeedback = Object.entries(mostCommon).sort((a, b) => b[1] - a[1])[0];
      return {
        exerciseName,
        feedback: topFeedback?.[0] || 'just_right',
        frequency: topFeedback?.[1] || 0,
      };
    }
  );

  // Transform swap history
  const swapHistory = (swaps || []).map((s: any) => ({
    originalExercise: s.original_exercise?.name_ko || s.original_exercise?.name || 'Unknown',
    replacementExercise: s.replacement_exercise?.name_ko || s.replacement_exercise?.name || 'Unknown',
    reason: s.custom_reason || s.feedback_reason,
  }));

  return {
    difficultyFeedback,
    swapHistory,
    rpePatterns: { averageRpe: 7, trend: 'stable' }, // TODO: Calculate from actual data
  };
}

async function fetchExerciseFamiliarity(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<ExerciseFamiliarity[]> {
  const { data, error } = await supabase
    .from('client_exercise_familiarity')
    .select(`
      exercise_id,
      familiarity_score,
      times_performed,
      is_mastered,
      exercises (name, name_ko)
    `)
    .eq('client_id', clientId)
    .order('familiarity_score', { ascending: false });

  if (error) {
    console.error('Error fetching exercise familiarity:', error);
    return [];
  }

  return (data || []).map((f: any) => ({
    exerciseId: f.exercise_id,
    exerciseName: f.exercises?.name_ko || f.exercises?.name || 'Unknown',
    familiarityScore: f.familiarity_score || 0,
    timesPerformed: f.times_performed || 0,
    isMastered: f.is_mastered || false,
  }));
}

async function calculateTrainingAge(
  supabase: ReturnType<typeof createClient>,
  clientId: string
): Promise<number> {
  // Find the first completed session date for this client
  const { data, error } = await supabase
    .from('sessions')
    .select('started_at')
    .eq('client_id', clientId)
    .eq('status', 'completed')
    .order('started_at', { ascending: true })
    .limit(1)
    .single();

  if (error || !data) {
    return 0; // New client with no history
  }

  const firstSessionDate = new Date(data.started_at);
  const now = new Date();
  const weeksDiff = Math.floor(
    (now.getTime() - firstSessionDate.getTime()) / (7 * 24 * 60 * 60 * 1000)
  );

  return weeksDiff;
}

// Get basic compound exercises for new clients
function getBasicCompoundExercises(exercises: Array<{ id: string; name: string; nameKo: string; movementPattern: string }>): string[] {
  const basicPatterns = ['squat', 'hinge', 'horizontal_push', 'horizontal_pull', 'vertical_push', 'vertical_pull'];
  const preferredExercises = [
    'goblet squat', 'leg press',
    'dumbbell rdl', 'hip thrust',
    'push-up', 'machine chest press',
    'seated cable row', 'machine row',
    'machine shoulder press',
    'lat pulldown',
  ];

  return exercises
    .filter(e =>
      preferredExercises.some(pe => e.name.toLowerCase().includes(pe)) ||
      basicPatterns.includes(e.movementPattern)
    )
    .slice(0, 12)
    .map(e => e.nameKo);
}

async function fetchExerciseLibrary(
  supabase: ReturnType<typeof createClient>,
  excludedIds: string[]
): Promise<Array<{ id: string; name: string; nameKo: string; movementPattern: string; muscleGroup: string; equipment: string; difficulty: string }>> {
  let query = supabase
    .from('exercises')
    .select('id, name, name_ko, movement_pattern, muscle_group, equipment, difficulty');

  if (excludedIds.length > 0) {
    query = query.not('id', 'in', `(${excludedIds.join(',')})`);
  }

  const { data, error } = await query;

  if (error) {
    console.error('Error fetching exercises:', error);
    return [];
  }

  return (data || []).map((e: any) => ({
    id: e.id,
    name: e.name,
    nameKo: e.name_ko || e.name,
    movementPattern: e.movement_pattern || 'other',
    muscleGroup: e.muscle_group || 'other',
    equipment: e.equipment || 'bodyweight',
    difficulty: e.difficulty || 'intermediate',
  }));
}

function buildWorkoutPrompt(params: {
  clientContext: ClientContext;
  workoutHistory: WorkoutHistory;
  sessionFeedback: SessionFeedback;
  exerciseFamiliarity: ExerciseFamiliarity[];
  trainingAgeWeeks: number;
  primaryGoal: string;
  secondaryGoal?: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  preferredEquipment: string[];
  sessionDurationMinutes: number;
  availableExercises: Array<{ id: string; name: string; nameKo: string; movementPattern: string; muscleGroup: string; equipment: string; difficulty: string }>;
  previousPrograms: PreviousSession[];
}): string {
  const {
    clientContext,
    workoutHistory,
    sessionFeedback,
    exerciseFamiliarity,
    trainingAgeWeeks,
    primaryGoal,
    secondaryGoal,
    durationWeeks,
    sessionsPerWeek,
    preferredEquipment,
    sessionDurationMinutes,
    availableExercises,
    previousPrograms,
  } = params;

  // Get goal-based parameters
  const goalParams = GOAL_PARAMETERS[primaryGoal.toLowerCase().replace(/ /g, '_')] || GOAL_PARAMETERS.general_fitness;

  // Determine max new exercises per session based on training age
  let maxNewExercises = 2;
  if (trainingAgeWeeks >= 8) {
    maxNewExercises = NEW_EXERCISE_LIMITS.advanced;
  } else if (trainingAgeWeeks >= 4) {
    maxNewExercises = NEW_EXERCISE_LIMITS.intermediate;
  } else {
    maxNewExercises = NEW_EXERCISE_LIMITS.beginner;
  }

  // Categorize exercises by familiarity
  const familiarExercises = exerciseFamiliarity
    .filter(f => f.familiarityScore >= 0.5)
    .map(f => f.exerciseName);
  const masteredExercises = exerciseFamiliarity
    .filter(f => f.isMastered)
    .map(f => f.exerciseName);
  const newExerciseCandidates = availableExercises
    .filter(e => !exerciseFamiliarity.some(f => f.exerciseId === e.id))
    .map(e => e.nameKo);

  // For new clients with no history, recommend basic compound exercises
  const isNewClient = trainingAgeWeeks === 0 && exerciseFamiliarity.length === 0;
  const basicExercises = isNewClient ? getBasicCompoundExercises(availableExercises) : [];

  return `You are an expert personal trainer creating a personalized workout program.

## Client Profile
- Experience Level: ${clientContext.experienceLevel}
- Training Age: ${trainingAgeWeeks} weeks
- Fitness Goals: ${clientContext.fitnessGoals.join(', ') || primaryGoal}
- Available Equipment: ${[...clientContext.availableEquipment, ...preferredEquipment].join(', ') || 'gym equipment'}
- Injury History: ${clientContext.injuryHistory.length > 0 ? JSON.stringify(clientContext.injuryHistory) : 'None reported'}
- Limitations: ${clientContext.limitations.join(', ') || 'None'}

## Program Requirements
- Primary Goal: ${primaryGoal}
${secondaryGoal ? `- Secondary Goal: ${secondaryGoal}` : ''}
- Duration: ${durationWeeks} weeks
- Sessions per week: ${sessionsPerWeek}
- Session duration: ~${sessionDurationMinutes} minutes

## GOAL-BASED TRAINING PARAMETERS (MANDATORY)
Based on the primary goal "${primaryGoal}", use these parameters:
- Target Reps: ${goalParams.reps}
- Target Sets: ${goalParams.sets}
- Rest Between Sets: ${goalParams.restSeconds} seconds
- Target RPE: ${goalParams.targetRpe}/10

## EXERCISE FAMILIARITY RULES (CRITICAL)
Training Age: ${trainingAgeWeeks} weeks
Max NEW exercises per session: ${maxNewExercises}

${isNewClient ? `
### NEW CLIENT - Basic Compound Focus
This client has no training history. Start with these foundational movements:
${basicExercises.join(', ')}

Focus on:
- Machine-based or bodyweight variations for safety
- Exercises with low technical complexity
- Build consistency before introducing variety
` : `
### Familiar Exercises (PRIORITY - use 60%+ of these per session):
${familiarExercises.length > 0 ? familiarExercises.slice(0, 15).join(', ') : 'None recorded yet'}

### Mastered Exercises (client excels at these):
${masteredExercises.length > 0 ? masteredExercises.join(', ') : 'None yet'}

### New Exercise Candidates (limit to ${maxNewExercises} per session):
${newExerciseCandidates.slice(0, 20).join(', ')}
`}

## Recent Workout History (Last 30 Days)
${workoutHistory.recentSessions.length > 0 ? `
- Completed ${workoutHistory.recentSessions.length} sessions
- Recent exercises: ${workoutHistory.recentSessions.slice(0, 5).flatMap(s => s.exercises.map(e => e.name)).slice(0, 10).join(', ')}
- Volume trend: ${workoutHistory.volumeTrends.trend}
` : 'No recent workout history available'}

## Session Feedback
${sessionFeedback.difficultyFeedback.length > 0 ? `
Exercises that were too easy: ${sessionFeedback.difficultyFeedback.filter(f => f.feedback === 'too_easy').map(f => f.exerciseName).join(', ') || 'None'}
Exercises that were challenging: ${sessionFeedback.difficultyFeedback.filter(f => f.feedback === 'struggling').map(f => f.exerciseName).join(', ') || 'None'}
` : 'No feedback available'}
${sessionFeedback.swapHistory.length > 0 ? `
Recent exercise swaps: ${sessionFeedback.swapHistory.slice(0, 5).map(s => `${s.originalExercise} → ${s.replacementExercise}`).join(', ')}
` : ''}

## PREVIOUS SESSIONS CONTEXT (CRITICAL FOR VARIETY)
${previousPrograms.length > 0 ? (() => {
  const prevGoal = previousPrograms[0]?.primaryGoal;
  const goalChanged = prevGoal && prevGoal !== primaryGoal;
  const mostRecentExercises = previousPrograms[0]?.exercises || [];
  const secondRecentExercises = previousPrograms[1]?.exercises || [];
  const thirdRecentExercises = previousPrograms[2]?.exercises || [];

  // Count movement patterns from recent sessions
  const patternCounts = new Map<string, number>();
  [...mostRecentExercises, ...secondRecentExercises, ...thirdRecentExercises].forEach(e => {
    patternCounts.set(e.movementPattern, (patternCounts.get(e.movementPattern) || 0) + 1);
  });

  return `Goal Continuity: ${goalChanged ? `CHANGED from "${prevGoal}" to "${primaryGoal}"` : `SAME as previous ("${primaryGoal}")`}

### Exercises to AVOID (from most recent session):
${mostRecentExercises.length > 0 ? mostRecentExercises.map(e => `- ${e.exerciseName}`).join('\n') : 'None'}

### Exercises to LIMIT (from 2nd most recent session - max 20% overlap):
${secondRecentExercises.length > 0 ? secondRecentExercises.map(e => `- ${e.exerciseName}`).join('\n') : 'None'}

### Movement Pattern Balance:
${Array.from(patternCounts.entries()).map(([pattern, count]) => `- ${pattern}: ${count} times in last 3 sessions`).join('\n')}

EXERCISE SELECTION RULES FOR VARIETY:
1. NEVER repeat exercises from the most recent session
2. Limit overlap with 2nd most recent session to max 1 exercise
3. Prioritize underused movement patterns
4. ${goalChanged ? 'Goal changed: Include 40% familiar exercises for smooth transition' : 'Goal same: Progress with variety while maintaining similar movement patterns'}
`;
})() : 'No previous sessions - this is the first program for this client.'}

## Available Exercises
${availableExercises.slice(0, 50).map(e => `- ${e.nameKo} [ID: ${e.id}] (${e.movementPattern}, ${e.muscleGroup}, ${e.difficulty})`).join('\n')}

## Instructions
Create a SINGLE training session with:
1. 5-7 exercises appropriate for the goal (MINIMUM 5 exercises)
2. Use the GOAL-BASED PARAMETERS above for sets, reps, rest, and RPE
3. Detailed reasoning for why each exercise was selected (considering variety from previous sessions)

CRITICAL RULES:
1. Use the exact sets (${goalParams.sets}), reps (${goalParams.reps}), rest (${goalParams.restSeconds}s), and RPE (${goalParams.targetRpe}) from goal parameters
2. NEVER repeat exercises from the most recent session (see PREVIOUS SESSIONS CONTEXT)
3. Limit overlap with 2nd most recent session to maximum 1 exercise
4. Prioritize underused movement patterns for variety
5. ${isNewClient ? 'For this new client, prioritize basic compound movements with machines or bodyweight' : 'Progress difficulty based on experience level'}
6. Consider the client's injury history and limitations
7. At least 60% of exercises MUST be from the familiar/mastered list (unless new client)
8. Maximum ${maxNewExercises} new exercises per session
9. Include warm-up/activation exercise as first exercise
10. **FULL BODY BALANCE (MANDATORY)**: For ANY full_body or general workout:
    - MUST include at least 2 LOWER BODY exercises (squat or hinge patterns: leg press, squat, deadlift, RDL, hip thrust, lunge, leg curl, leg extension)
    - MUST include at least 2 UPPER BODY exercises (push or pull patterns: bench press, row, pulldown, shoulder press, etc.)
    - Upper body patterns: horizontal_push, horizontal_pull, vertical_push, vertical_pull
    - Lower body patterns: squat, hinge
    - A "full body" workout with only upper body exercises is INVALID

Respond with a JSON object in this exact format:
{
  "programName": "string",
  "programDescription": "string",
  "workoutDays": [
    {
      "dayNumber": 1,
      "name": "string",
      "focusArea": "string",
      "estimatedDurationMinutes": 60,
      "exercises": [
        {
          "exerciseId": "string (MUST use ID from available exercises list)",
          "exerciseName": "string",
          "orderIndex": 0,
          "targetSets": ${goalParams.sets},
          "targetReps": "${goalParams.reps}",
          "targetRpe": ${goalParams.targetRpe},
          "restSeconds": ${goalParams.restSeconds},
          "isNewExercise": false,
          "notes": "string (optional)",
          "aiReasoning": {
            "reasons": [
              {
                "category": "goal_alignment|familiarity|progressive_overload|injury_prevention",
                "explanation": "string",
                "explanationKo": "string",
                "confidence": 0.9
              }
            ],
            "overallScore": 0.85
          }
        }
      ]
    }
  ]
}`;
}

async function callOpenAI(
  apiKey: string,
  prompt: string
): Promise<any> {
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
          content: 'You are an expert personal trainer. Always respond with valid JSON only, no markdown formatting.',
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

async function saveProgramToDatabase(
  supabase: ReturnType<typeof createClient>,
  clientId: string,
  trainerId: string,
  workoutProgram: any,
  primaryGoal: string,
  secondaryGoal: string | undefined,
  durationWeeks: number,
  sessionsPerWeek: number
): Promise<any> {
  const programId = crypto.randomUUID();

  // Insert program with AI model version for tracking
  const { error: programError } = await supabase.from('workout_programs').insert({
    id: programId,
    client_id: clientId,
    trainer_id: trainerId,
    name: workoutProgram.programName,
    description: workoutProgram.programDescription,
    primary_goal: primaryGoal,
    secondary_goal: secondaryGoal,
    duration_weeks: durationWeeks,
    sessions_per_week: sessionsPerWeek,
    status: 'draft',
    is_ai_generated: true,
    ai_model_version: 'gpt-4o-mini',
    customization_count: 0,
  });

  if (programError) {
    throw new Error(`Failed to save program: ${programError.message}`);
  }

  // Insert workout days and exercises
  for (const day of workoutProgram.workoutDays || []) {
    const dayId = crypto.randomUUID();

    await supabase.from('workout_days').insert({
      id: dayId,
      program_id: programId,
      day_number: day.dayNumber,
      name: day.name,
      focus_area: day.focusArea,
      estimated_duration_minutes: day.estimatedDurationMinutes,
    });

    for (const exercise of day.exercises || []) {
      await supabase.from('program_exercises').insert({
        id: crypto.randomUUID(),
        workout_day_id: dayId,
        exercise_id: exercise.exerciseId,
        order_index: exercise.orderIndex,
        target_sets: exercise.targetSets,
        target_reps: exercise.targetReps,
        target_rpe: exercise.targetRpe,
        rest_seconds: exercise.restSeconds,
        notes: exercise.notes,
        ai_reasoning: exercise.aiReasoning,
      });
    }
  }

  // Return complete program
  const { data: savedProgram } = await supabase
    .from('workout_programs')
    .select(`
      *,
      workout_days (
        *,
        program_exercises (
          *,
          exercises (id, name, name_ko)
        )
      )
    `)
    .eq('id', programId)
    .single();

  return savedProgram;
}

// Helper functions
function extractPersonalRecords(sessions: any[]): Array<{ exerciseName: string; weight: number; reps: number; date: string }> {
  const records = new Map<string, { weight: number; reps: number; date: string }>();

  sessions.forEach((session) => {
    session.exercises.forEach((exercise: any) => {
      exercise.sets.forEach((set: any) => {
        const key = exercise.name;
        const existing = records.get(key);
        const volume = set.weight * set.reps;

        if (!existing || (set.weight * set.reps > existing.weight * existing.reps)) {
          records.set(key, {
            weight: set.weight,
            reps: set.reps,
            date: session.date,
          });
        }
      });
    });
  });

  return Array.from(records.entries()).map(([name, record]) => ({
    exerciseName: name,
    ...record,
  }));
}

function calculateVolumeTrends(sessions: any[]): { weeklyVolume: number[]; trend: 'increasing' | 'stable' | 'decreasing' } {
  // Group sessions by week
  const weeklyVolumes: number[] = [];
  let currentWeekVolume = 0;
  let currentWeekStart: Date | null = null;

  sessions.forEach((session) => {
    const sessionDate = new Date(session.date);
    const weekStart = new Date(sessionDate);
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());

    if (!currentWeekStart || weekStart.getTime() !== currentWeekStart.getTime()) {
      if (currentWeekStart) {
        weeklyVolumes.push(currentWeekVolume);
      }
      currentWeekStart = weekStart;
      currentWeekVolume = 0;
    }

    session.exercises.forEach((exercise: any) => {
      exercise.sets.forEach((set: any) => {
        currentWeekVolume += (set.weight || 0) * (set.reps || 0);
      });
    });
  });

  if (currentWeekVolume > 0) {
    weeklyVolumes.push(currentWeekVolume);
  }

  // Determine trend
  let trend: 'increasing' | 'stable' | 'decreasing' = 'stable';
  if (weeklyVolumes.length >= 2) {
    const recent = weeklyVolumes.slice(0, 2);
    const diff = recent[0] - recent[1];
    const threshold = recent[1] * 0.1; // 10% threshold

    if (diff > threshold) {
      trend = 'increasing';
    } else if (diff < -threshold) {
      trend = 'decreasing';
    }
  }

  return { weeklyVolume: weeklyVolumes, trend };
}
