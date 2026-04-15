-- Migration: Create academy tables for YouTube video feed
-- Created: 2026-02-14
-- Updated: 2026-02-18 — restructured to 3 categories with 7 curated channels
-- Purpose: academy_channels (channel registry) + academy_videos (cached video metadata)

-- ============================================
-- TABLE: academy_channels
-- ============================================
CREATE TABLE IF NOT EXISTS academy_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id TEXT NOT NULL UNIQUE,
  channel_name TEXT NOT NULL,
  channel_name_ko TEXT,
  category TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT academy_channels_category_check
    CHECK (category IN ('exercise', 'rehab', 'nutrition'))
);

-- ============================================
-- TABLE: academy_videos
-- ============================================
CREATE TABLE IF NOT EXISTS academy_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id TEXT NOT NULL UNIQUE,
  channel_id TEXT NOT NULL REFERENCES academy_channels(channel_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  category TEXT NOT NULL,
  published_at TIMESTAMPTZ NOT NULL,
  view_count BIGINT DEFAULT 0,
  duration TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT academy_videos_category_check
    CHECK (category IN ('exercise', 'rehab', 'nutrition'))
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_academy_videos_category_published
  ON academy_videos (category, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_academy_videos_published_at
  ON academy_videos (published_at DESC);

CREATE INDEX IF NOT EXISTS idx_academy_channels_category
  ON academy_channels (category);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE academy_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE academy_videos ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read
CREATE POLICY "academy_channels_read" ON academy_channels
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "academy_videos_read" ON academy_videos
  FOR SELECT TO authenticated
  USING (true);

-- Service role has full access (for edge function sync)
CREATE POLICY "academy_channels_service_all" ON academy_channels
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

CREATE POLICY "academy_videos_service_all" ON academy_videos
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ============================================
-- SEED: Curated Korean fitness YouTuber channels
-- ============================================
INSERT INTO academy_channels (channel_id, channel_name, channel_name_ko, category) VALUES
  -- Exercise (운동) — 2 channels
  ('UChBKRycwLWou13wTAF--_mw', '3-Minute Exercise Science', '3분 운동과학',                'exercise'),
  ('UChU7a6tVcJ-PEG4VW0dL36w', 'Fundamental',              '뻔더',                       'exercise'),
  -- Rehab (재활) — 2 channels
  ('UCPwxWbDnHIbOv0HqpNXOvUQ', 'Jaeho Fitness',            '재호 - Fitness',              'rehab'),
  ('UC60jiGq5e5zoDiWyGPLVicg', 'Mr. Physio',               'Mr.Physio 호주물리치료사',      'rehab'),
  -- Nutrition (영양) — 3 channels
  ('UCMFk5S7g5DY-CZNVh_Kyz_A', 'Yakstory',                 '약사가 들려주는 약 이야기',     'nutrition'),
  ('UCedNxnMK3b2-_hzqLyo4stg', 'Dr. Dingyo',               '닥터딩요',                    'nutrition'),
  ('UC3iSLVH0MxHfwO69oHKpvog', 'Little Yaksa',             '리틀약사',                    'nutrition')
ON CONFLICT (channel_id) DO NOTHING;
