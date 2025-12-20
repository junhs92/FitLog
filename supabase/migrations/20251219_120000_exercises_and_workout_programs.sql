-- =====================================================
-- Exercises and Workout Programs Migration
-- Complete schema for AI workout generation system
-- =====================================================

-- =====================================================
-- 1. EXERCISES TABLE
-- Master exercise library with movement patterns
-- =====================================================

CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Basic Info
  name TEXT NOT NULL,
  name_ko TEXT,
  description TEXT,
  description_ko TEXT,

  -- Classification
  category TEXT NOT NULL CHECK (category IN ('compound', 'isolation', 'cardio', 'mobility', 'warmup', 'cooldown')),
  movement_pattern TEXT NOT NULL CHECK (movement_pattern IN (
    'squat', 'hinge', 'horizontal_push', 'horizontal_pull',
    'vertical_push', 'vertical_pull', 'carry', 'rotation', 'isolation', 'cardio'
  )),

  -- Targeting
  muscle_group TEXT NOT NULL CHECK (muscle_group IN (
    'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
    'quadriceps', 'hamstrings', 'glutes', 'calves', 'core', 'full_body'
  )),
  secondary_muscles TEXT[] DEFAULT '{}',

  -- Equipment & Difficulty
  equipment TEXT NOT NULL CHECK (equipment IN (
    'barbell', 'dumbbell', 'kettlebell', 'cable', 'machine',
    'bodyweight', 'band', 'smith', 'trx', 'other'
  )),
  difficulty TEXT NOT NULL DEFAULT 'intermediate' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced', 'expert')),

  -- Media
  video_url TEXT,
  thumbnail_url TEXT,
  instructions JSONB DEFAULT '[]'::jsonb,

  -- Custom exercise support
  is_custom BOOLEAN DEFAULT FALSE,
  trainer_id UUID REFERENCES accounts(id) ON DELETE CASCADE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_exercises_movement_pattern ON exercises(movement_pattern);
CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON exercises(equipment);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON exercises(difficulty);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category);
CREATE INDEX IF NOT EXISTS idx_exercises_trainer_id ON exercises(trainer_id) WHERE trainer_id IS NOT NULL;

-- RLS
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Everyone can view standard exercises
CREATE POLICY "Anyone can view standard exercises" ON exercises
  FOR SELECT USING (is_custom = FALSE);

-- Trainers can view their custom exercises
CREATE POLICY "Trainers can view own custom exercises" ON exercises
  FOR SELECT USING (
    is_custom = TRUE AND trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Trainers can create custom exercises
CREATE POLICY "Trainers can create custom exercises" ON exercises
  FOR INSERT WITH CHECK (
    is_custom = TRUE AND trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Trainers can update their custom exercises
CREATE POLICY "Trainers can update own custom exercises" ON exercises
  FOR UPDATE USING (
    is_custom = TRUE AND trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Trainers can delete their custom exercises
CREATE POLICY "Trainers can delete own custom exercises" ON exercises
  FOR DELETE USING (
    is_custom = TRUE AND trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );


-- =====================================================
-- 2. WORKOUT PROGRAMS TABLE
-- AI-generated or manually created workout programs
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES accounts(id),

  -- Program Details
  name TEXT NOT NULL,
  description TEXT,

  -- Goals
  primary_goal TEXT NOT NULL CHECK (primary_goal IN (
    'strength', 'hypertrophy', 'endurance', 'weight_loss',
    'general_fitness', 'rehabilitation', 'athletic'
  )),
  secondary_goal TEXT CHECK (secondary_goal IN (
    'strength', 'hypertrophy', 'endurance', 'weight_loss',
    'general_fitness', 'rehabilitation', 'athletic'
  )),

  -- Program Structure
  duration_weeks INTEGER NOT NULL DEFAULT 4 CHECK (duration_weeks BETWEEN 1 AND 52),
  sessions_per_week INTEGER NOT NULL DEFAULT 3 CHECK (sessions_per_week BETWEEN 1 AND 7),

  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'archived')),

  -- AI Metadata
  is_ai_generated BOOLEAN DEFAULT TRUE,
  customization_count INTEGER DEFAULT 0,
  ai_model_version TEXT,
  generation_context JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_programs_client_id ON workout_programs(client_id);
CREATE INDEX IF NOT EXISTS idx_workout_programs_trainer_id ON workout_programs(trainer_id);
CREATE INDEX IF NOT EXISTS idx_workout_programs_status ON workout_programs(status);

-- RLS
ALTER TABLE workout_programs ENABLE ROW LEVEL SECURITY;

-- Trainers can manage programs for their clients
CREATE POLICY "Trainers can manage client programs" ON workout_programs
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their own programs
CREATE POLICY "Clients can view own programs" ON workout_programs
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );


-- =====================================================
-- 3. WORKOUT DAYS TABLE
-- Individual workout days within a program
-- =====================================================

CREATE TABLE IF NOT EXISTS workout_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id UUID NOT NULL REFERENCES workout_programs(id) ON DELETE CASCADE,

  -- Day Details
  day_number INTEGER NOT NULL CHECK (day_number BETWEEN 1 AND 7),
  name TEXT NOT NULL,
  focus_area TEXT,

  -- Duration
  estimated_duration_minutes INTEGER DEFAULT 60,

  -- Order
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_days_program_id ON workout_days(program_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_days_program_day ON workout_days(program_id, day_number);

-- RLS
ALTER TABLE workout_days ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers can manage workout days" ON workout_days
  FOR ALL USING (
    program_id IN (
      SELECT id FROM workout_programs WHERE trainer_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Clients can view workout days" ON workout_days
  FOR SELECT USING (
    program_id IN (
      SELECT id FROM workout_programs WHERE client_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );


-- =====================================================
-- 4. PROGRAM EXERCISES TABLE
-- Exercises within a workout day (AI-generated template)
-- =====================================================

CREATE TABLE IF NOT EXISTS program_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id),

  -- Order
  order_index INTEGER NOT NULL DEFAULT 0,

  -- Target Parameters
  target_sets INTEGER NOT NULL DEFAULT 3 CHECK (target_sets BETWEEN 1 AND 10),
  target_reps TEXT NOT NULL DEFAULT '10',  -- Can be "8-12", "10", "AMRAP", etc.
  target_weight DECIMAL(6,2),
  target_rpe INTEGER CHECK (target_rpe BETWEEN 1 AND 10),
  rest_seconds INTEGER DEFAULT 90,

  -- Notes
  notes TEXT,

  -- AI Reasoning
  ai_reasoning JSONB,  -- Stores AIExerciseReasoning structure
  alternatives JSONB DEFAULT '[]'::jsonb,  -- Pre-computed alternatives

  -- Swap tracking
  original_exercise_id UUID REFERENCES exercises(id),
  is_swapped BOOLEAN DEFAULT FALSE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_program_exercises_workout_day_id ON program_exercises(workout_day_id);
CREATE INDEX IF NOT EXISTS idx_program_exercises_exercise_id ON program_exercises(exercise_id);

-- RLS
ALTER TABLE program_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers can manage program exercises" ON program_exercises
  FOR ALL USING (
    workout_day_id IN (
      SELECT wd.id FROM workout_days wd
      JOIN workout_programs wp ON wd.program_id = wp.id
      WHERE wp.trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Clients can view program exercises" ON program_exercises
  FOR SELECT USING (
    workout_day_id IN (
      SELECT wd.id FROM workout_days wd
      JOIN workout_programs wp ON wd.program_id = wp.id
      WHERE wp.client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
    )
  );


-- =====================================================
-- 5. SESSION EXERCISES TABLE
-- Actual exercises performed in a session (with logged results)
-- =====================================================

CREATE TABLE IF NOT EXISTS session_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id),
  program_exercise_id UUID REFERENCES program_exercises(id),

  -- Order
  order_index INTEGER NOT NULL DEFAULT 0,

  -- Logged Results (JSONB array of sets)
  sets JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Each set: { "set_number": 1, "weight": 60.0, "reps": 10, "rpe": 7, "notes": "" }

  -- Session-time notes
  notes TEXT,

  -- Timestamps
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id ON session_exercises(session_id);
CREATE INDEX IF NOT EXISTS idx_session_exercises_exercise_id ON session_exercises(exercise_id);

-- RLS
ALTER TABLE session_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers can manage session exercises" ON session_exercises
  FOR ALL USING (
    session_id IN (
      SELECT id FROM sessions WHERE trainer_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Clients can view session exercises" ON session_exercises
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM sessions WHERE client_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );


-- =====================================================
-- 6. SESSION REPORTS TABLE (if not exists)
-- AI-generated session summaries
-- =====================================================

CREATE TABLE IF NOT EXISTS session_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

  -- Report Content
  summary TEXT NOT NULL,
  summary_ko TEXT,
  highlights JSONB DEFAULT '[]'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,

  -- Delivery
  pdf_url TEXT,
  email_sent_at TIMESTAMPTZ,
  push_sent_at TIMESTAMPTZ,

  -- AI Metadata
  ai_model_version TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_session_reports_session_id ON session_reports(session_id);

-- RLS
ALTER TABLE session_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers can manage session reports" ON session_reports
  FOR ALL USING (
    session_id IN (
      SELECT id FROM sessions WHERE trainer_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Clients can view session reports" ON session_reports
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM sessions WHERE client_id IN (
        SELECT id FROM accounts WHERE user_id = auth.uid()
      )
    )
  );


-- =====================================================
-- 7. HELPER FUNCTION: Increment customization count
-- =====================================================

CREATE OR REPLACE FUNCTION increment_customization_count(program_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE workout_programs
  SET customization_count = customization_count + 1,
      updated_at = NOW()
  WHERE id = program_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================
-- 8. TRIGGER: Update timestamps
-- =====================================================

CREATE OR REPLACE FUNCTION update_exercises_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_exercises_updated_at ON exercises;
CREATE TRIGGER trigger_update_exercises_updated_at
  BEFORE UPDATE ON exercises
  FOR EACH ROW
  EXECUTE FUNCTION update_exercises_updated_at();

CREATE OR REPLACE FUNCTION update_workout_programs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_workout_programs_updated_at ON workout_programs;
CREATE TRIGGER trigger_update_workout_programs_updated_at
  BEFORE UPDATE ON workout_programs
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_programs_updated_at();


-- =====================================================
-- 9. SEED DATA: Exercise Library
-- Comprehensive gym exercise database
-- =====================================================

-- Clear existing seed data (if re-running)
DELETE FROM exercises WHERE is_custom = FALSE;

-- CHEST EXERCISES (Horizontal Push)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Barbell Bench Press', '바벨 벤치프레스', 'compound', 'horizontal_push', 'chest', ARRAY['triceps', 'shoulders'], 'barbell', 'intermediate', 'Classic chest builder targeting pectorals'),
('Dumbbell Bench Press', '덤벨 벤치프레스', 'compound', 'horizontal_push', 'chest', ARRAY['triceps', 'shoulders'], 'dumbbell', 'intermediate', 'Greater range of motion than barbell'),
('Incline Barbell Bench Press', '인클라인 바벨 벤치프레스', 'compound', 'horizontal_push', 'chest', ARRAY['shoulders', 'triceps'], 'barbell', 'intermediate', 'Targets upper chest'),
('Incline Dumbbell Press', '인클라인 덤벨 프레스', 'compound', 'horizontal_push', 'chest', ARRAY['shoulders', 'triceps'], 'dumbbell', 'intermediate', 'Upper chest with independent arm movement'),
('Decline Bench Press', '디클라인 벤치프레스', 'compound', 'horizontal_push', 'chest', ARRAY['triceps'], 'barbell', 'intermediate', 'Targets lower chest'),
('Push-Up', '푸쉬업', 'compound', 'horizontal_push', 'chest', ARRAY['triceps', 'shoulders', 'core'], 'bodyweight', 'beginner', 'Fundamental bodyweight chest exercise'),
('Dumbbell Fly', '덤벨 플라이', 'isolation', 'horizontal_push', 'chest', ARRAY[]::text[], 'dumbbell', 'intermediate', 'Isolation movement for chest stretch'),
('Cable Crossover', '케이블 크로스오버', 'isolation', 'horizontal_push', 'chest', ARRAY[]::text[], 'cable', 'intermediate', 'Constant tension chest isolation'),
('Machine Chest Press', '머신 체스트 프레스', 'compound', 'horizontal_push', 'chest', ARRAY['triceps', 'shoulders'], 'machine', 'beginner', 'Guided chest pressing movement'),
('Pec Deck Machine', '펙덱 머신', 'isolation', 'horizontal_push', 'chest', ARRAY[]::text[], 'machine', 'beginner', 'Machine fly movement');

-- BACK EXERCISES (Horizontal Pull)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Barbell Row', '바벨 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps', 'core'], 'barbell', 'intermediate', 'Primary back thickness builder'),
('Dumbbell Row', '덤벨 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps'], 'dumbbell', 'beginner', 'Unilateral back exercise'),
('Seated Cable Row', '시티드 케이블 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps'], 'cable', 'beginner', 'Controlled rowing movement'),
('T-Bar Row', '티바 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps', 'core'], 'barbell', 'intermediate', 'Heavy back exercise'),
('Machine Row', '머신 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps'], 'machine', 'beginner', 'Guided horizontal pull'),
('Chest Supported Row', '체스트 서포티드 로우', 'compound', 'horizontal_pull', 'back', ARRAY['biceps'], 'dumbbell', 'beginner', 'Strict form rowing');

-- BACK EXERCISES (Vertical Pull)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Pull-Up', '풀업', 'compound', 'vertical_pull', 'back', ARRAY['biceps', 'core'], 'bodyweight', 'intermediate', 'Classic back width builder'),
('Chin-Up', '친업', 'compound', 'vertical_pull', 'back', ARRAY['biceps'], 'bodyweight', 'intermediate', 'Biceps-emphasized pull-up'),
('Lat Pulldown', '랫 풀다운', 'compound', 'vertical_pull', 'back', ARRAY['biceps'], 'cable', 'beginner', 'Pull-up alternative'),
('Wide Grip Lat Pulldown', '와이드 그립 랫 풀다운', 'compound', 'vertical_pull', 'back', ARRAY['biceps'], 'cable', 'beginner', 'Width-focused pulldown'),
('Close Grip Lat Pulldown', '클로즈 그립 랫 풀다운', 'compound', 'vertical_pull', 'back', ARRAY['biceps'], 'cable', 'beginner', 'Inner back focused'),
('Assisted Pull-Up', '어시스티드 풀업', 'compound', 'vertical_pull', 'back', ARRAY['biceps'], 'machine', 'beginner', 'Assisted pull-up movement');

-- SHOULDER EXERCISES (Vertical Push)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Overhead Press', '오버헤드 프레스', 'compound', 'vertical_push', 'shoulders', ARRAY['triceps', 'core'], 'barbell', 'intermediate', 'Standing shoulder press'),
('Seated Dumbbell Press', '시티드 덤벨 프레스', 'compound', 'vertical_push', 'shoulders', ARRAY['triceps'], 'dumbbell', 'intermediate', 'Seated shoulder pressing'),
('Arnold Press', '아놀드 프레스', 'compound', 'vertical_push', 'shoulders', ARRAY['triceps'], 'dumbbell', 'intermediate', 'Rotational shoulder press'),
('Machine Shoulder Press', '머신 숄더 프레스', 'compound', 'vertical_push', 'shoulders', ARRAY['triceps'], 'machine', 'beginner', 'Guided overhead press'),
('Lateral Raise', '레터럴 레이즈', 'isolation', 'isolation', 'shoulders', ARRAY[]::text[], 'dumbbell', 'beginner', 'Side delt isolation'),
('Front Raise', '프론트 레이즈', 'isolation', 'isolation', 'shoulders', ARRAY[]::text[], 'dumbbell', 'beginner', 'Front delt isolation'),
('Rear Delt Fly', '리어 델트 플라이', 'isolation', 'isolation', 'shoulders', ARRAY[]::text[], 'dumbbell', 'beginner', 'Rear delt isolation'),
('Face Pull', '페이스 풀', 'compound', 'horizontal_pull', 'shoulders', ARRAY['back'], 'cable', 'beginner', 'Rear delt and upper back health'),
('Upright Row', '업라이트 로우', 'compound', 'vertical_pull', 'shoulders', ARRAY['biceps'], 'barbell', 'intermediate', 'Shoulder and trap builder');

-- LEG EXERCISES (Squat Pattern)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Barbell Squat', '바벨 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes', 'hamstrings', 'core'], 'barbell', 'intermediate', 'King of leg exercises'),
('Front Squat', '프론트 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes', 'core'], 'barbell', 'advanced', 'Quad-dominant squat'),
('Goblet Squat', '고블릿 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes', 'core'], 'dumbbell', 'beginner', 'Beginner-friendly squat'),
('Leg Press', '레그 프레스', 'compound', 'squat', 'quadriceps', ARRAY['glutes'], 'machine', 'beginner', 'Machine squat alternative'),
('Hack Squat', '핵 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes'], 'machine', 'intermediate', 'Machine squat variation'),
('Smith Machine Squat', '스미스 머신 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes'], 'smith', 'beginner', 'Guided squat movement'),
('Bulgarian Split Squat', '불가리안 스플릿 스쿼트', 'compound', 'squat', 'quadriceps', ARRAY['glutes'], 'dumbbell', 'intermediate', 'Single leg squat'),
('Walking Lunge', '워킹 런지', 'compound', 'squat', 'quadriceps', ARRAY['glutes', 'hamstrings'], 'dumbbell', 'beginner', 'Dynamic leg movement'),
('Leg Extension', '레그 익스텐션', 'isolation', 'isolation', 'quadriceps', ARRAY[]::text[], 'machine', 'beginner', 'Quad isolation');

-- LEG EXERCISES (Hinge Pattern)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Deadlift', '데드리프트', 'compound', 'hinge', 'hamstrings', ARRAY['glutes', 'back', 'core'], 'barbell', 'intermediate', 'Full posterior chain'),
('Romanian Deadlift', '루마니안 데드리프트', 'compound', 'hinge', 'hamstrings', ARRAY['glutes', 'back'], 'barbell', 'intermediate', 'Hamstring-focused deadlift'),
('Stiff Leg Deadlift', '스티프 레그 데드리프트', 'compound', 'hinge', 'hamstrings', ARRAY['glutes'], 'barbell', 'intermediate', 'Maximum hamstring stretch'),
('Dumbbell RDL', '덤벨 루마니안 데드리프트', 'compound', 'hinge', 'hamstrings', ARRAY['glutes'], 'dumbbell', 'beginner', 'Dumbbell hip hinge'),
('Good Morning', '굿모닝', 'compound', 'hinge', 'hamstrings', ARRAY['glutes', 'back'], 'barbell', 'advanced', 'Posterior chain stretch'),
('Hip Thrust', '힙 쓰러스트', 'compound', 'hinge', 'glutes', ARRAY['hamstrings'], 'barbell', 'intermediate', 'Glute isolation'),
('Glute Bridge', '글루트 브릿지', 'compound', 'hinge', 'glutes', ARRAY['hamstrings'], 'bodyweight', 'beginner', 'Basic glute activation'),
('Lying Leg Curl', '라잉 레그 컬', 'isolation', 'isolation', 'hamstrings', ARRAY[]::text[], 'machine', 'beginner', 'Hamstring isolation'),
('Seated Leg Curl', '시티드 레그 컬', 'isolation', 'isolation', 'hamstrings', ARRAY[]::text[], 'machine', 'beginner', 'Seated hamstring isolation'),
('Cable Pull Through', '케이블 풀스루', 'compound', 'hinge', 'glutes', ARRAY['hamstrings'], 'cable', 'beginner', 'Hip hinge with cable');

-- ARM EXERCISES (Biceps)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Barbell Curl', '바벨 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'barbell', 'beginner', 'Classic bicep builder'),
('Dumbbell Curl', '덤벨 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'dumbbell', 'beginner', 'Standard dumbbell curl'),
('Hammer Curl', '해머 컬', 'isolation', 'isolation', 'biceps', ARRAY['forearms'], 'dumbbell', 'beginner', 'Brachialis and forearm focus'),
('Preacher Curl', '프리처 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'barbell', 'beginner', 'Strict bicep isolation'),
('Cable Curl', '케이블 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'cable', 'beginner', 'Constant tension curl'),
('Incline Dumbbell Curl', '인클라인 덤벨 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'dumbbell', 'intermediate', 'Long head stretch'),
('Concentration Curl', '컨센트레이션 컬', 'isolation', 'isolation', 'biceps', ARRAY[]::text[], 'dumbbell', 'beginner', 'Peak contraction focus');

-- ARM EXERCISES (Triceps)
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Tricep Pushdown', '트라이셉 푸시다운', 'isolation', 'isolation', 'triceps', ARRAY[]::text[], 'cable', 'beginner', 'Cable tricep extension'),
('Skull Crusher', '스컬 크러셔', 'isolation', 'isolation', 'triceps', ARRAY[]::text[], 'barbell', 'intermediate', 'Lying tricep extension'),
('Overhead Tricep Extension', '오버헤드 트라이셉 익스텐션', 'isolation', 'isolation', 'triceps', ARRAY[]::text[], 'dumbbell', 'beginner', 'Long head stretch'),
('Dips', '딥스', 'compound', 'horizontal_push', 'triceps', ARRAY['chest', 'shoulders'], 'bodyweight', 'intermediate', 'Compound tricep movement'),
('Close Grip Bench Press', '클로즈 그립 벤치프레스', 'compound', 'horizontal_push', 'triceps', ARRAY['chest'], 'barbell', 'intermediate', 'Tricep-focused pressing'),
('Diamond Push-Up', '다이아몬드 푸쉬업', 'compound', 'horizontal_push', 'triceps', ARRAY['chest'], 'bodyweight', 'intermediate', 'Bodyweight tricep focus'),
('Tricep Kickback', '트라이셉 킥백', 'isolation', 'isolation', 'triceps', ARRAY[]::text[], 'dumbbell', 'beginner', 'Tricep contraction focus');

-- CORE EXERCISES
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Plank', '플랭크', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'bodyweight', 'beginner', 'Isometric core hold'),
('Dead Bug', '데드 버그', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'bodyweight', 'beginner', 'Anti-extension core'),
('Bird Dog', '버드독', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'bodyweight', 'beginner', 'Stability and control'),
('Cable Woodchop', '케이블 우드찹', 'compound', 'rotation', 'core', ARRAY[]::text[], 'cable', 'intermediate', 'Rotational core power'),
('Hanging Leg Raise', '행잉 레그 레이즈', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'bodyweight', 'intermediate', 'Lower ab focus'),
('Ab Wheel Rollout', '앱 휠 롤아웃', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'other', 'advanced', 'Advanced core anti-extension'),
('Russian Twist', '러시안 트위스트', 'compound', 'rotation', 'core', ARRAY[]::text[], 'bodyweight', 'beginner', 'Rotational core'),
('Crunch', '크런치', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'bodyweight', 'beginner', 'Basic ab flexion'),
('Cable Crunch', '케이블 크런치', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'cable', 'beginner', 'Weighted ab flexion'),
('Pallof Press', '팔로프 프레스', 'isolation', 'isolation', 'core', ARRAY[]::text[], 'cable', 'beginner', 'Anti-rotation core');

-- CARRY EXERCISES
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Farmers Walk', '파머스 워크', 'compound', 'carry', 'full_body', ARRAY['core', 'forearms'], 'dumbbell', 'beginner', 'Loaded carry'),
('Suitcase Carry', '수트케이스 캐리', 'compound', 'carry', 'core', ARRAY['forearms'], 'dumbbell', 'beginner', 'Single arm carry'),
('Overhead Carry', '오버헤드 캐리', 'compound', 'carry', 'shoulders', ARRAY['core'], 'dumbbell', 'intermediate', 'Overhead loaded carry'),
('Trap Bar Carry', '트랩바 캐리', 'compound', 'carry', 'full_body', ARRAY['core'], 'barbell', 'intermediate', 'Heavy loaded carry');

-- CALVES
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Standing Calf Raise', '스탠딩 카프 레이즈', 'isolation', 'isolation', 'calves', ARRAY[]::text[], 'machine', 'beginner', 'Gastrocnemius focus'),
('Seated Calf Raise', '시티드 카프 레이즈', 'isolation', 'isolation', 'calves', ARRAY[]::text[], 'machine', 'beginner', 'Soleus focus'),
('Leg Press Calf Raise', '레그 프레스 카프 레이즈', 'isolation', 'isolation', 'calves', ARRAY[]::text[], 'machine', 'beginner', 'Machine calf raise');

-- CARDIO / CONDITIONING
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Treadmill Running', '트레드밀 런닝', 'cardio', 'cardio', 'full_body', ARRAY[]::text[], 'machine', 'beginner', 'Steady state cardio'),
('Rowing Machine', '로잉 머신', 'cardio', 'cardio', 'full_body', ARRAY['back', 'core'], 'machine', 'beginner', 'Full body cardio'),
('Bike', '바이크', 'cardio', 'cardio', 'full_body', ARRAY['quadriceps'], 'machine', 'beginner', 'Low impact cardio'),
('Stair Climber', '스테어 클라이머', 'cardio', 'cardio', 'full_body', ARRAY['quadriceps', 'glutes'], 'machine', 'beginner', 'Lower body cardio'),
('Jump Rope', '줄넘기', 'cardio', 'cardio', 'full_body', ARRAY['calves'], 'other', 'beginner', 'Coordination and cardio'),
('Battle Ropes', '배틀 로프', 'cardio', 'cardio', 'full_body', ARRAY['shoulders', 'core'], 'other', 'intermediate', 'HIIT conditioning'),
('Box Jump', '박스 점프', 'compound', 'squat', 'full_body', ARRAY['quadriceps', 'glutes'], 'other', 'intermediate', 'Explosive power'),
('Burpee', '버피', 'cardio', 'cardio', 'full_body', ARRAY['chest', 'core'], 'bodyweight', 'intermediate', 'Full body conditioning');

-- WARMUP / MOBILITY
INSERT INTO exercises (name, name_ko, category, movement_pattern, muscle_group, secondary_muscles, equipment, difficulty, description) VALUES
('Hip Circle', '힙 서클', 'mobility', 'rotation', 'glutes', ARRAY[]::text[], 'bodyweight', 'beginner', 'Hip mobility'),
('Arm Circle', '암 서클', 'warmup', 'rotation', 'shoulders', ARRAY[]::text[], 'bodyweight', 'beginner', 'Shoulder warmup'),
('Cat-Cow', '캣-카우', 'mobility', 'rotation', 'core', ARRAY['back'], 'bodyweight', 'beginner', 'Spine mobility'),
('World Greatest Stretch', '월드 그레이티스트 스트레치', 'mobility', 'rotation', 'full_body', ARRAY[]::text[], 'bodyweight', 'beginner', 'Dynamic stretch'),
('Foam Roll', '폼롤링', 'mobility', 'isolation', 'full_body', ARRAY[]::text[], 'other', 'beginner', 'Myofascial release');

-- Grant read access to the exercise seed data for everyone
GRANT SELECT ON exercises TO authenticated;
GRANT SELECT ON exercises TO anon;


-- =====================================================
-- 10. PROGRAM TEMPLATES TABLE
-- Save and reuse workout programs for other clients
-- =====================================================

CREATE TABLE IF NOT EXISTS program_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Template Details
  name TEXT NOT NULL,
  description TEXT,

  -- Source Program Reference (if derived from a program)
  source_program_id UUID REFERENCES workout_programs(id) ON DELETE SET NULL,

  -- Goals (copied from program)
  primary_goal TEXT NOT NULL CHECK (primary_goal IN (
    'strength', 'hypertrophy', 'endurance', 'weight_loss',
    'general_fitness', 'rehabilitation', 'athletic'
  )),
  secondary_goal TEXT CHECK (secondary_goal IN (
    'strength', 'hypertrophy', 'endurance', 'weight_loss',
    'general_fitness', 'rehabilitation', 'athletic'
  )),

  -- Program Structure
  duration_weeks INTEGER NOT NULL DEFAULT 4 CHECK (duration_weeks BETWEEN 1 AND 52),
  sessions_per_week INTEGER NOT NULL DEFAULT 3 CHECK (sessions_per_week BETWEEN 1 AND 7),

  -- Template Content (JSONB snapshot of workout days and exercises)
  template_data JSONB NOT NULL,
  -- Structure: {
  --   "workoutDays": [
  --     {
  --       "dayNumber": 1,
  --       "name": "...",
  --       "focusArea": "...",
  --       "estimatedDurationMinutes": 60,
  --       "exercises": [
  --         {
  --           "exerciseId": "...",
  --           "orderIndex": 0,
  --           "targetSets": 4,
  --           "targetReps": "8-12",
  --           "targetRpe": 7,
  --           "restSeconds": 90,
  --           "notes": "..."
  --         }
  --       ]
  --     }
  --   ]
  -- }

  -- Usage Tracking
  usage_count INTEGER DEFAULT 0,

  -- Visibility (for future sharing feature)
  is_public BOOLEAN DEFAULT FALSE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_program_templates_trainer_id ON program_templates(trainer_id);
CREATE INDEX IF NOT EXISTS idx_program_templates_primary_goal ON program_templates(primary_goal);

-- RLS
ALTER TABLE program_templates ENABLE ROW LEVEL SECURITY;

-- Trainers can manage their own templates
CREATE POLICY "Trainers can manage own templates" ON program_templates
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );


-- =====================================================
-- 11. TEMPLATE USAGE TRACKING TABLE
-- Track which templates were used for which clients
-- =====================================================

CREATE TABLE IF NOT EXISTS template_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES program_templates(id) ON DELETE CASCADE,
  program_id UUID NOT NULL REFERENCES workout_programs(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES accounts(id),

  -- Customizations made after applying template
  customization_notes TEXT,
  customization_count INTEGER DEFAULT 0,

  -- Timestamp
  applied_at TIMESTAMPTZ DEFAULT NOW(),

  -- One program can only be from one template
  UNIQUE(program_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_template_usage_template_id ON template_usage(template_id);
CREATE INDEX IF NOT EXISTS idx_template_usage_client_id ON template_usage(client_id);
CREATE INDEX IF NOT EXISTS idx_template_usage_trainer_id ON template_usage(trainer_id);

-- RLS
ALTER TABLE template_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainers can view template usage" ON template_usage
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );


-- =====================================================
-- 12. CLIENT EXERCISE FAMILIARITY TABLE
-- Track client familiarity with each exercise
-- =====================================================

CREATE TABLE IF NOT EXISTS client_exercise_familiarity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,

  -- Familiarity Metrics
  times_performed INTEGER DEFAULT 0,
  first_performed_at TIMESTAMPTZ,
  last_performed_at TIMESTAMPTZ,

  -- Performance Tracking
  total_sets_completed INTEGER DEFAULT 0,
  average_rpe DECIMAL(3,1),
  best_weight DECIMAL(6,2),
  best_reps INTEGER,

  -- Familiarity Score (0.0 to 1.0)
  -- Calculated: times_performed (40%) + recency (30%) + consistency (30%)
  familiarity_score DECIMAL(3,2) DEFAULT 0.0 CHECK (familiarity_score BETWEEN 0.0 AND 1.0),

  -- Status flags
  is_mastered BOOLEAN DEFAULT FALSE,  -- Trainer marked as mastered
  needs_coaching BOOLEAN DEFAULT FALSE,  -- Trainer flagged for extra attention

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- One record per client-exercise pair
  UNIQUE(client_id, exercise_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_client_exercise_familiarity_client ON client_exercise_familiarity(client_id);
CREATE INDEX IF NOT EXISTS idx_client_exercise_familiarity_score ON client_exercise_familiarity(familiarity_score DESC);
CREATE INDEX IF NOT EXISTS idx_client_exercise_familiarity_exercise ON client_exercise_familiarity(exercise_id);

-- RLS
ALTER TABLE client_exercise_familiarity ENABLE ROW LEVEL SECURITY;

-- Trainers can view and manage familiarity for their clients
CREATE POLICY "Trainers can manage client familiarity" ON client_exercise_familiarity
  FOR ALL USING (
    client_id IN (
      SELECT tcr.client_id
      FROM trainer_client_relationships tcr
      JOIN accounts a ON a.user_id = auth.uid()
      WHERE tcr.trainer_id = a.id AND tcr.status = 'active'
    )
  );

-- Clients can view their own familiarity
CREATE POLICY "Clients can view own familiarity" ON client_exercise_familiarity
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );


-- =====================================================
-- 13. SESSION DATA ENHANCEMENTS
-- Add columns for comprehensive session tracking
-- =====================================================

-- Enhance sessions table
ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS duration_seconds INTEGER,
  ADD COLUMN IF NOT EXISTS overall_difficulty TEXT CHECK (overall_difficulty IN ('too_easy', 'just_right', 'challenging', 'exhausting')),
  ADD COLUMN IF NOT EXISTS session_notes TEXT,
  ADD COLUMN IF NOT EXISTS program_id UUID REFERENCES workout_programs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS workout_day_id UUID REFERENCES workout_days(id) ON DELETE SET NULL;

-- Enhance session_exercises table
ALTER TABLE session_exercises
  ADD COLUMN IF NOT EXISTS completion_status TEXT DEFAULT 'completed' CHECK (completion_status IN ('completed', 'partial', 'skipped', 'substituted')),
  ADD COLUMN IF NOT EXISTS difficulty_feedback TEXT CHECK (difficulty_feedback IN ('too_easy', 'just_right', 'challenging', 'struggling')),
  ADD COLUMN IF NOT EXISTS actual_rest_seconds INTEGER,
  ADD COLUMN IF NOT EXISTS exercise_notes TEXT;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_sessions_program_id ON sessions(program_id) WHERE program_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_workout_day_id ON sessions(workout_day_id) WHERE workout_day_id IS NOT NULL;


-- =====================================================
-- 14. TRIGGER: Auto-update exercise familiarity
-- After session exercise insert/update, update familiarity
-- =====================================================

CREATE OR REPLACE FUNCTION update_exercise_familiarity()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_exercise_id UUID;
  v_sets JSONB;
  v_set_count INTEGER;
  v_avg_rpe DECIMAL;
  v_max_weight DECIMAL;
  v_max_reps INTEGER;
  v_recency_factor DECIMAL;
  v_new_familiarity DECIMAL;
BEGIN
  -- Get client_id from session
  SELECT client_id INTO v_client_id FROM sessions WHERE id = NEW.session_id;
  v_exercise_id := NEW.exercise_id;
  v_sets := COALESCE(NEW.sets, '[]'::jsonb);
  v_set_count := jsonb_array_length(v_sets);

  -- Skip if no sets
  IF v_set_count = 0 THEN
    RETURN NEW;
  END IF;

  -- Calculate metrics from sets (RPE is averaged from individual set RPEs)
  SELECT
    AVG((set_data->>'rpe')::DECIMAL),
    MAX((set_data->>'weight')::DECIMAL),
    MAX((set_data->>'reps')::INTEGER)
  INTO v_avg_rpe, v_max_weight, v_max_reps
  FROM jsonb_array_elements(v_sets) AS set_data
  WHERE set_data->>'weight' IS NOT NULL OR set_data->>'reps' IS NOT NULL;

  -- Upsert familiarity record
  INSERT INTO client_exercise_familiarity (
    client_id, exercise_id, times_performed, first_performed_at,
    last_performed_at, total_sets_completed, average_rpe, best_weight, best_reps, familiarity_score
  )
  VALUES (
    v_client_id, v_exercise_id, 1, NOW(),
    NOW(), v_set_count, v_avg_rpe, v_max_weight, v_max_reps, 0.1
  )
  ON CONFLICT (client_id, exercise_id) DO UPDATE SET
    times_performed = client_exercise_familiarity.times_performed + 1,
    last_performed_at = NOW(),
    total_sets_completed = client_exercise_familiarity.total_sets_completed + v_set_count,
    average_rpe = CASE
      WHEN v_avg_rpe IS NOT NULL THEN
        (COALESCE(client_exercise_familiarity.average_rpe, v_avg_rpe) * client_exercise_familiarity.times_performed + v_avg_rpe) / (client_exercise_familiarity.times_performed + 1)
      ELSE client_exercise_familiarity.average_rpe
    END,
    best_weight = GREATEST(COALESCE(client_exercise_familiarity.best_weight, 0), COALESCE(v_max_weight, 0)),
    best_reps = GREATEST(COALESCE(client_exercise_familiarity.best_reps, 0), COALESCE(v_max_reps, 0)),
    updated_at = NOW();

  -- Calculate and update familiarity score
  UPDATE client_exercise_familiarity
  SET familiarity_score = LEAST(1.0, (
    -- Times performed component (max 0.4 at 10+ times)
    LEAST(times_performed::DECIMAL / 10.0, 0.4) +
    -- Recency component (max 0.3)
    CASE
      WHEN last_performed_at > NOW() - INTERVAL '14 days' THEN 0.3
      WHEN last_performed_at > NOW() - INTERVAL '30 days' THEN 0.2
      WHEN last_performed_at > NOW() - INTERVAL '60 days' THEN 0.1
      ELSE 0.05
    END +
    -- Consistency component (max 0.3 at 50+ total sets)
    LEAST(total_sets_completed::DECIMAL / 50.0, 0.3)
  ))
  WHERE client_id = v_client_id AND exercise_id = v_exercise_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (fires when sets are recorded/updated)
DROP TRIGGER IF EXISTS trigger_update_exercise_familiarity ON session_exercises;
CREATE TRIGGER trigger_update_exercise_familiarity
  AFTER INSERT OR UPDATE OF sets ON session_exercises
  FOR EACH ROW
  WHEN (NEW.sets IS NOT NULL AND jsonb_array_length(NEW.sets) > 0)
  EXECUTE FUNCTION update_exercise_familiarity();


-- =====================================================
-- 15. HELPER FUNCTION: Increment template usage count
-- =====================================================

CREATE OR REPLACE FUNCTION increment_template_usage(p_template_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE program_templates
  SET usage_count = usage_count + 1,
      updated_at = NOW()
  WHERE id = p_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =====================================================
-- 16. TRIGGER: Update program_templates timestamps
-- =====================================================

CREATE OR REPLACE FUNCTION update_program_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_program_templates_updated_at ON program_templates;
CREATE TRIGGER trigger_update_program_templates_updated_at
  BEFORE UPDATE ON program_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_program_templates_updated_at();


-- =====================================================
-- 17. TRIGGER: Update client_exercise_familiarity timestamps
-- =====================================================

CREATE OR REPLACE FUNCTION update_client_exercise_familiarity_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_client_exercise_familiarity_updated_at ON client_exercise_familiarity;
CREATE TRIGGER trigger_update_client_exercise_familiarity_updated_at
  BEFORE UPDATE ON client_exercise_familiarity
  FOR EACH ROW
  EXECUTE FUNCTION update_client_exercise_familiarity_updated_at();
