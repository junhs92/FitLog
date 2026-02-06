-- Migration: Add recommendation enhancement tables
-- Date: 2026-01-23
-- Description: Creates tables for exercise aliases, relations, user preferences, and tunable recommendation weights

-- 1. exercise_aliases - Search/display normalization for Korean/English exercise names
CREATE TABLE IF NOT EXISTS exercise_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  alias TEXT NOT NULL,
  alias_normalized TEXT NOT NULL,  -- lowercase, no spaces for matching
  priority INT DEFAULT 0,          -- higher = preferred display
  locale TEXT DEFAULT 'ko',        -- 'ko', 'en', 'mixed'
  source TEXT DEFAULT 'system',    -- 'system', 'user', 'import'
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_exercise_aliases_exercise_id ON exercise_aliases(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_normalized ON exercise_aliases(alias_normalized);

-- 2. exercise_relations - Exercise relationship graph for recommendations
CREATE TABLE IF NOT EXISTS exercise_relations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  to_exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  relation_type TEXT NOT NULL CHECK (relation_type IN (
    'variation',       -- same exercise, different angle/equipment
    'complementary',   -- good to do together
    'supplementary',   -- isolation for same muscle
    'substitute'       -- can replace when unavailable
  )),
  strength INT DEFAULT 50 CHECK (strength >= 0 AND strength <= 100),
  reason_tags TEXT[] DEFAULT '{}',  -- ['same_group', 'angle_variation', etc.]
  constraints JSONB DEFAULT '{}',   -- optional conditions
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(from_exercise_id, to_exercise_id, relation_type)
);

CREATE INDEX IF NOT EXISTS idx_exercise_relations_from ON exercise_relations(from_exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_relations_type ON exercise_relations(relation_type);

-- 3. user_preferences - Per-user equipment/level preferences for filtering
-- Note: Different from workout_programs.constraints which is one-time setup
-- This stores evolving preferences learned from app usage
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  preferred_equipment TEXT[] DEFAULT '{}',    -- ['barbell', 'dumbbell']
  avoid_equipment TEXT[] DEFAULT '{}',        -- ['machine']
  level TEXT DEFAULT 'intermediate',          -- maps to exercises.difficulty
  preferred_groups TEXT[] DEFAULT '{}',       -- ['push', 'pull']
  avoid_muscle_groups TEXT[] DEFAULT '{}',    -- ['shoulders'] for injuries
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(user_id)
);

-- 4. recommendation_weights - Tunable scoring weights (replaces hardcoded values)
CREATE TABLE IF NOT EXISTS recommendation_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,     -- 'same_group', 'same_prime', etc.
  category TEXT NOT NULL,       -- 'complementary', 'supplementary', 'split'
  weight FLOAT NOT NULL,        -- scoring points
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Seed default weights (current hardcoded values from exercise_recommendation_service.dart)
INSERT INTO recommendation_weights (key, category, weight, description) VALUES
  ('same_group', 'complementary', 40, 'Same movement group'),
  ('same_detail', 'complementary', 20, 'Same movement detail'),
  ('same_prime', 'complementary', 30, 'Same primary muscle'),
  ('same_family', 'complementary', 25, 'Same exercise family'),
  ('angle_variation', 'complementary', 20, 'Different angle, same muscle'),
  ('same_equipment', 'complementary', 10, 'Same equipment'),
  ('category_match', 'complementary', 10, 'Same category (compound/isolation)'),
  ('supplementary_same_prime', 'supplementary', 30, 'Same primary muscle'),
  ('isolation_bonus', 'supplementary', 25, 'Isolation exercise bonus'),
  ('secondary_overlap', 'supplementary', 20, 'Secondary muscle overlap'),
  ('stable_equipment', 'supplementary', 10, 'Machine/cable stability bonus'),
  ('difficulty_mismatch_penalty', 'general', -15, 'User level vs exercise difficulty')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE exercise_aliases ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_weights ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- exercise_aliases: Read for all authenticated (system data)
CREATE POLICY "Read exercise_aliases" ON exercise_aliases
  FOR SELECT TO authenticated USING (true);

-- exercise_relations: Read for all authenticated (system data)
CREATE POLICY "Read exercise_relations" ON exercise_relations
  FOR SELECT TO authenticated USING (true);

-- user_preferences: Users can only access their own preferences
CREATE POLICY "Read own user_preferences" ON user_preferences
  FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Insert own user_preferences" ON user_preferences
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Update own user_preferences" ON user_preferences
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Delete own user_preferences" ON user_preferences
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- recommendation_weights: Read for all authenticated (system config)
CREATE POLICY "Read recommendation_weights" ON recommendation_weights
  FOR SELECT TO authenticated USING (true);
