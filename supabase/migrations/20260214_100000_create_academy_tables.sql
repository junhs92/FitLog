-- Migration: Create academy tables for YouTube video feed
-- Created: 2026-02-14
-- Updated: 2026-02-15 — real YouTube channel IDs (videos fetched via RSS)
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
    CHECK (category IN ('bodybuilding', 'powerlifting', 'rehab_mobility', 'nutrition', 'stretching'))
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
    CHECK (category IN ('bodybuilding', 'powerlifting', 'rehab_mobility', 'nutrition', 'stretching'))
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
-- SEED: Real Korean fitness YouTuber channels
-- ============================================
INSERT INTO academy_channels (channel_id, channel_name, channel_name_ko, category) VALUES
  -- Bodybuilding (보디빌딩)
  ('UCdtRAcd3L_UpV4tMXCw63NQ', 'Physical Gallery',       '피지컬갤러리',         'bodybuilding'),
  ('UCjGoJbTmFYjd5OnPRUur02A', 'Kim Kang Min',           '김강민',              'bodybuilding'),
  ('UC3hRpIQ4x5niJDwjajQSVPg', 'FITVELY',                '핏블리',              'bodybuilding'),
  ('UCcMSJmR90Y_McofszAVxjAQ', 'Kim Seong Hwan',         '김성환헬스유튜브',      'bodybuilding'),
  ('UCuwyPNJScQ5luAV7b8juFfg', 'Kang Kyung Won',         '강경원',              'bodybuilding'),
  ('UCMA7GmwOUuvSlM4XUhN2JFA', 'Seol Ki Kwan',           '설기관',              'bodybuilding'),
  ('UCYJDUekoQz0-bo8al1diLWQ', 'Mal Wang TV',            '말왕TV',              'bodybuilding'),
  ('UC249-iv-esDsCbsVRVC_v5A', 'Health Brain Official',  '헬스뇌피셜',           'bodybuilding'),
  -- Powerlifting (파워리프팅)
  ('UCB_InNNxt0TRjGrTiqyTtFw', '1-Min Powerlifting',     '1분 파워리프팅',       'powerlifting'),
  ('UCc8atk3sIWO-5k4mWhfqIuw', 'Kim Dong Hyun PL',       '김동현 PowerLifting',  'powerlifting'),
  ('UCcR-weSu2qrz5RP8Oeq6kbg', 'IPF KOREA',              'IPF KOREA',           'powerlifting'),
  ('UCCS3--kPUakwPG4SP_TtkGg', 'Joint Destroyer',        '관절파괴자',           'powerlifting'),
  ('UCmdFfKkZFoLS3FjbpL_bB6A', 'Team Triple Strength',   'TEAM TRIPLE STRENGTH 팀트리플', 'powerlifting'),
  -- Rehab / Mobility (재활/모빌리티)
  ('UCsyhk1jx2eeafzMSYhQc9Mg', 'PT Jaeseok',             '물리치료사PT재석',      'rehab_mobility'),
  ('UCNEqrN9CGcd_RW9Uj9J_FKQ', 'Real Rehab',             '리얼리햅',             'rehab_mobility'),
  ('UC0kjUOzhExSnUhp2pmcGlrg', 'PT Yoon',                '물리치료사 윤쌤',       'rehab_mobility'),
  ('UCiAtFdOzCLP7s_EnamnIGjg', 'Rehavi',                  '리해비',               'rehab_mobility'),
  ('UCATBFeLSoEImAPlToNNH-Hg', 'PT Jaban',               '운동하는 물리치료사_자반', 'rehab_mobility'),
  ('UC69aaZIgXIAI7L0vZT7wX0Q', 'PT Hands',               'PT핸즈',               'rehab_mobility'),
  -- Nutrition (영양)
  ('UCMFk5S7g5DY-CZNVh_Kyz_A', 'Pharmacist Drug Stories', '약사가 들려주는 약 이야기', 'nutrition'),
  ('UCoe-0EVDJnjlSoPK8ygcGwQ', 'Gym Jong Kook',          '김종국 GYM JONG KOOK',  'nutrition'),
  ('UC0NazDJj6HZnqXR9x9HiXEg', 'Dear Dabin',            '디어다빈_영양사의 다이어트', 'nutrition'),
  ('UC-9mf6zsaEf5YFIpEzElIEw', 'Nutrition Talk',          '영양톡',               'nutrition'),
  ('UCaAV1hS46BOWR_sGvTP1iYA', 'Lim RD',                  '영양사 임알디',         'nutrition'),
  ('UCCECtlEkh5QluApGuI1MqJQ', 'Healthy Hanna',           '건강한나 영양사',       'nutrition'),
  ('UCQHIirHu_EEWIuwsUN3GAwA', 'Living-Alone Dietitian',  '자취방 영양사',         'nutrition'),
  -- Stretching (스트레칭)
  ('UC4yq3FWEWqMvFNFBsV3gbKQ', 'Hip Euddeume',            '힙으뜸',               'stretching'),
  ('UCxHcczukcG21up2MBe8yP_Q', 'Kang Hana Stretching',    '강하나 스트레칭',       'stretching'),
  ('UCaBpzR9Ti-DqR1v5S01OLhw', 'Yoga Song Hayeon',        '요가쏭',               'stretching'),
  ('UCsd1XJK6zwiCqTzf8KQQgrQ', 'Yoga Boy',                '요가소년',              'stretching'),
  ('UCq7bR6RxqqOx8cptc1-0AVQ', 'Allblanc TV',             'Allblanc TV',          'stretching'),
  ('UCYa-mbstZLNmg1xyjYnZV9w', 'FoxgymTV',               'FoxgymTV',             'stretching')
ON CONFLICT (channel_id) DO NOTHING;
