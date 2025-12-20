-- =============================================
-- Create Lifestyle Logging Tables for FitLog Pro
-- Migration: 20241208_090000_create_lifestyle_tables
-- =============================================

-- 1. MEAL LOGS
CREATE TABLE meal_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  photo_url TEXT,
  description TEXT,
  calories INTEGER,
  protein DECIMAL(6,2),
  carbs DECIMAL(6,2),
  fat DECIMAL(6,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE meal_logs IS 'Client meal logging with nutritional data';

-- 2. MOOD LOGS
CREATE TABLE mood_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  mood INTEGER NOT NULL CHECK (mood BETWEEN 1 AND 5),
  energy INTEGER CHECK (energy BETWEEN 1 AND 5),
  stress_level INTEGER CHECK (stress_level BETWEEN 1 AND 5),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE mood_logs IS 'Client mood and energy tracking';

-- 3. SLEEP LOGS
CREATE TABLE sleep_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  bedtime TIMESTAMPTZ,
  wake_time TIMESTAMPTZ,
  quality INTEGER CHECK (quality BETWEEN 1 AND 5),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE sleep_logs IS 'Client sleep tracking with quality metrics';

-- 4. WATER LOGS
CREATE TABLE water_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  amount_ml INTEGER NOT NULL,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE water_logs IS 'Client daily water intake tracking';

-- 5. BODY PHOTOS
CREATE TABLE body_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  photo_date DATE NOT NULL,
  angle TEXT NOT NULL CHECK (angle IN ('front', 'side', 'back')),
  photo_url TEXT NOT NULL,
  weight DECIMAL(5,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE body_photos IS 'Client progress photos from different angles';

-- =============================================
-- Enable RLS on all tables
-- =============================================
ALTER TABLE meal_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_photos ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS Policies for meal_logs
-- =============================================
CREATE POLICY "meal_logs_client_own_data" ON meal_logs
  FOR ALL USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "meal_logs_trainer_view" ON meal_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships tcr
      JOIN accounts a ON a.id = tcr.trainer_id
      WHERE tcr.client_id = meal_logs.client_id
      AND a.user_id = auth.uid()
      AND tcr.status = 'active'
    )
  );

-- =============================================
-- RLS Policies for mood_logs
-- =============================================
CREATE POLICY "mood_logs_client_own_data" ON mood_logs
  FOR ALL USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "mood_logs_trainer_view" ON mood_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships tcr
      JOIN accounts a ON a.id = tcr.trainer_id
      WHERE tcr.client_id = mood_logs.client_id
      AND a.user_id = auth.uid()
      AND tcr.status = 'active'
    )
  );

-- =============================================
-- RLS Policies for sleep_logs
-- =============================================
CREATE POLICY "sleep_logs_client_own_data" ON sleep_logs
  FOR ALL USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "sleep_logs_trainer_view" ON sleep_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships tcr
      JOIN accounts a ON a.id = tcr.trainer_id
      WHERE tcr.client_id = sleep_logs.client_id
      AND a.user_id = auth.uid()
      AND tcr.status = 'active'
    )
  );

-- =============================================
-- RLS Policies for water_logs
-- =============================================
CREATE POLICY "water_logs_client_own_data" ON water_logs
  FOR ALL USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "water_logs_trainer_view" ON water_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships tcr
      JOIN accounts a ON a.id = tcr.trainer_id
      WHERE tcr.client_id = water_logs.client_id
      AND a.user_id = auth.uid()
      AND tcr.status = 'active'
    )
  );

-- =============================================
-- RLS Policies for body_photos
-- =============================================
CREATE POLICY "body_photos_client_own_data" ON body_photos
  FOR ALL USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "body_photos_trainer_view" ON body_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships tcr
      JOIN accounts a ON a.id = tcr.trainer_id
      WHERE tcr.client_id = body_photos.client_id
      AND a.user_id = auth.uid()
      AND tcr.status = 'active'
    )
  );

-- =============================================
-- Performance Indexes
-- =============================================
CREATE INDEX idx_meal_logs_client_date ON meal_logs(client_id, log_date);
CREATE INDEX idx_mood_logs_client_date ON mood_logs(client_id, log_date);
CREATE INDEX idx_sleep_logs_client_date ON sleep_logs(client_id, log_date);
CREATE INDEX idx_water_logs_client_date ON water_logs(client_id, log_date);
CREATE INDEX idx_body_photos_client_date ON body_photos(client_id, photo_date);

