-- Migration: Restructure academy categories from 5 to 3 focused categories
-- Created: 2026-02-18
-- Purpose: Replace 32 channels (5 categories) with 7 curated channels (3 categories)

-- ============================================
-- STEP 1: Clean slate — remove all existing data
-- ============================================
DELETE FROM academy_videos;
DELETE FROM academy_channels;

-- ============================================
-- STEP 2: Drop old CHECK constraints
-- ============================================
ALTER TABLE academy_channels DROP CONSTRAINT IF EXISTS academy_channels_category_check;
ALTER TABLE academy_videos DROP CONSTRAINT IF EXISTS academy_videos_category_check;

-- ============================================
-- STEP 3: Add new CHECK constraints
-- ============================================
ALTER TABLE academy_channels
  ADD CONSTRAINT academy_channels_category_check
  CHECK (category IN ('exercise', 'rehab', 'nutrition'));

ALTER TABLE academy_videos
  ADD CONSTRAINT academy_videos_category_check
  CHECK (category IN ('exercise', 'rehab', 'nutrition'));

-- ============================================
-- STEP 4: Insert 7 curated channels
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
  ('UC3iSLVH0MxHfwO69oHKpvog', 'Little Yaksa',             '리틀약사',                    'nutrition');
