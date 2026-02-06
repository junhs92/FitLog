-- Migration: Create weight_logs and activity_logs tables + Test data for '송고객'
-- Date: 2025-12-29

-- ============================================
-- PART 1: Create Missing Tables
-- ============================================

-- Create weight_logs table
CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  weight NUMERIC NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(client_id, log_date)
);

-- Create activity_logs table
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  steps INTEGER,
  active_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(client_id, log_date)
);

-- Enable RLS
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS policies for weight_logs
CREATE POLICY "Trainers can view client weight logs" ON weight_logs
  FOR SELECT USING (
    client_id IN (
      SELECT client_id FROM trainer_client_relationships
      WHERE trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
      AND status = 'active'
    )
  );

CREATE POLICY "Clients can view own weight logs" ON weight_logs
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "Clients can insert own weight logs" ON weight_logs
  FOR INSERT WITH CHECK (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "Clients can update own weight logs" ON weight_logs
  FOR UPDATE USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- RLS policies for activity_logs
CREATE POLICY "Trainers can view client activity logs" ON activity_logs
  FOR SELECT USING (
    client_id IN (
      SELECT client_id FROM trainer_client_relationships
      WHERE trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
      AND status = 'active'
    )
  );

CREATE POLICY "Clients can view own activity logs" ON activity_logs
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "Clients can insert own activity logs" ON activity_logs
  FOR INSERT WITH CHECK (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "Clients can update own activity logs" ON activity_logs
  FOR UPDATE USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- ============================================
-- PART 2: Test Data for '송고객' (Flow 0 Testing)
-- Client ID: e83706a3-6b56-4956-874a-b72c3f0009de
-- ============================================

-- Sleep logs (quality: 1=poor, 2=fair, 3=good, 4=excellent)
INSERT INTO sleep_logs (client_id, log_date, bedtime, wake_time, quality) VALUES
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', '2025-12-22 23:00:00+09', '2025-12-23 06:30:00+09', 3),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', '2025-12-23 22:30:00+09', '2025-12-24 07:00:00+09', 4),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', '2025-12-24 23:30:00+09', '2025-12-25 07:30:00+09', 3),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', '2025-12-26 00:00:00+09', '2025-12-26 06:00:00+09', 2),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', '2025-12-26 22:00:00+09', '2025-12-27 06:30:00+09', 4),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', '2025-12-27 23:00:00+09', '2025-12-28 07:00:00+09', 3),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', '2025-12-28 22:30:00+09', '2025-12-29 06:00:00+09', 3);

-- Mood logs (mood/energy: 1-5 scale)
INSERT INTO mood_logs (client_id, log_date, mood, energy, stress_level) VALUES
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 4, 4, 2),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 5, 5, 1),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 4, 3, 2),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 3, 2, 3),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 4, 4, 2),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 5, 5, 1),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 4, 4, 2);

-- Meal logs (3 meals per day for 7 days)
INSERT INTO meal_logs (client_id, log_date, meal_type, description, calories, protein, carbs, fat) VALUES
-- Day 1 (2025-12-23)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 'breakfast', '계란 토스트, 우유', 450, 25, 45, 18),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 'lunch', '닭가슴살 샐러드', 520, 42, 30, 22),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 'dinner', '연어 스테이크, 현미밥', 680, 38, 55, 28),
-- Day 2 (2025-12-24)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 'breakfast', '오트밀, 바나나', 380, 12, 65, 8),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 'lunch', '불고기 덮밥', 720, 35, 85, 25),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 'dinner', '두부 스테이크', 450, 28, 35, 22),
-- Day 3 (2025-12-25)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 'breakfast', '그릭요거트, 그래놀라', 420, 20, 48, 15),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 'lunch', '참치 김밥', 550, 25, 70, 18),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 'dinner', '삼겹살, 쌈', 750, 32, 25, 55),
-- Day 4 (2025-12-26)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 'breakfast', '식빵, 잼, 우유', 400, 12, 60, 12),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 'lunch', '제육볶음 정식', 680, 30, 75, 28),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 'dinner', '된장찌개, 밥', 520, 22, 65, 18),
-- Day 5 (2025-12-27)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 'breakfast', '아보카도 토스트', 480, 15, 42, 28),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 'lunch', '비빔밥', 620, 25, 80, 22),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 'dinner', '치킨 샐러드', 580, 45, 25, 32),
-- Day 6 (2025-12-28)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 'breakfast', '팬케이크, 메이플시럽', 550, 12, 75, 22),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 'lunch', '김치찌개 정식', 580, 28, 60, 25),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 'dinner', '스테이크, 감자', 720, 48, 45, 38),
-- Day 7 (2025-12-29)
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 'breakfast', '시리얼, 우유', 350, 10, 55, 8),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 'lunch', '순두부찌개', 480, 25, 40, 25),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 'dinner', '갈비탕', 650, 35, 50, 32);

-- Water logs (2 entries per day)
INSERT INTO water_logs (client_id, log_date, amount_ml) VALUES
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 500),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 750),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 600),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 800),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 400),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 600),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 500),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 700),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 600),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 900),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 500),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 800),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 450),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 650);

-- Weight logs (every 2-3 days)
INSERT INTO weight_logs (client_id, log_date, weight) VALUES
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 72.5),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 72.3),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 72.0);

-- Activity logs (daily)
INSERT INTO activity_logs (client_id, log_date, steps, active_minutes) VALUES
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-23', 8500, 45),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-24', 12000, 75),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-25', 6500, 35),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-26', 5200, 30),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-27', 9800, 60),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-28', 11500, 80),
('e83706a3-6b56-4956-874a-b72c3f0009de', '2025-12-29', 7200, 42);
