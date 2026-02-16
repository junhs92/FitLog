-- Migration: Add 25 new Korean fitness YouTube channels to academy
-- Created: 2026-02-15
-- Purpose: Expand channel coverage across all 5 categories

INSERT INTO academy_channels (channel_id, channel_name, channel_name_ko, category) VALUES
  -- Bodybuilding (보디빌딩) — 5 new
  ('UCcMSJmR90Y_McofszAVxjAQ', 'Kim Seong Hwan',        '김성환헬스유튜브',               'bodybuilding'),
  ('UCuwyPNJScQ5luAV7b8juFfg', 'Kang Kyung Won',        '강경원',                        'bodybuilding'),
  ('UCMA7GmwOUuvSlM4XUhN2JFA', 'Seol Ki Kwan',          '설기관',                        'bodybuilding'),
  ('UCYJDUekoQz0-bo8al1diLWQ', 'Mal Wang TV',           '말왕TV',                        'bodybuilding'),
  ('UC249-iv-esDsCbsVRVC_v5A', 'Health Brain Official', '헬스뇌피셜',                     'bodybuilding'),
  -- Powerlifting (파워리프팅) — 5 new
  ('UCB_InNNxt0TRjGrTiqyTtFw', '1-Min Powerlifting',    '1분 파워리프팅',                  'powerlifting'),
  ('UCc8atk3sIWO-5k4mWhfqIuw', 'Kim Dong Hyun PL',      '김동현 PowerLifting',            'powerlifting'),
  ('UCcR-weSu2qrz5RP8Oeq6kbg', 'IPF KOREA',             'IPF KOREA',                     'powerlifting'),
  ('UCCS3--kPUakwPG4SP_TtkGg', 'Joint Destroyer',       '관절파괴자',                     'powerlifting'),
  ('UCmdFfKkZFoLS3FjbpL_bB6A', 'Team Triple Strength',  'TEAM TRIPLE STRENGTH 팀트리플',   'powerlifting'),
  -- Rehab / Mobility (재활/모빌리티) — 5 new
  ('UCNEqrN9CGcd_RW9Uj9J_FKQ', 'Real Rehab',            '리얼리햅',                       'rehab_mobility'),
  ('UC0kjUOzhExSnUhp2pmcGlrg', 'PT Yoon',               '물리치료사 윤쌤',                 'rehab_mobility'),
  ('UCiAtFdOzCLP7s_EnamnIGjg', 'Rehavi',                 '리해비',                         'rehab_mobility'),
  ('UCATBFeLSoEImAPlToNNH-Hg', 'PT Jaban',              '운동하는 물리치료사_자반',          'rehab_mobility'),
  ('UC69aaZIgXIAI7L0vZT7wX0Q', 'PT Hands',              'PT핸즈',                         'rehab_mobility'),
  -- Nutrition (영양) — 5 new
  ('UC0NazDJj6HZnqXR9x9HiXEg', 'Dear Dabin',           '디어다빈_영양사의 다이어트',        'nutrition'),
  ('UC-9mf6zsaEf5YFIpEzElIEw', 'Nutrition Talk',         '영양톡',                         'nutrition'),
  ('UCaAV1hS46BOWR_sGvTP1iYA', 'Lim RD',                 '영양사 임알디',                   'nutrition'),
  ('UCCECtlEkh5QluApGuI1MqJQ', 'Healthy Hanna',          '건강한나 영양사',                 'nutrition'),
  ('UCQHIirHu_EEWIuwsUN3GAwA', 'Living-Alone Dietitian', '자취방 영양사',                   'nutrition'),
  -- Stretching (스트레칭) — 5 new
  ('UCxHcczukcG21up2MBe8yP_Q', 'Kang Hana Stretching',   '강하나 스트레칭',                 'stretching'),
  ('UCaBpzR9Ti-DqR1v5S01OLhw', 'Yoga Song Hayeon',       '요가쏭',                         'stretching'),
  ('UCsd1XJK6zwiCqTzf8KQQgrQ', 'Yoga Boy',               '요가소년',                       'stretching'),
  ('UCq7bR6RxqqOx8cptc1-0AVQ', 'Allblanc TV',            'Allblanc TV',                   'stretching'),
  ('UCYa-mbstZLNmg1xyjYnZV9w', 'FoxgymTV',              'FoxgymTV',                       'stretching')
ON CONFLICT (channel_id) DO NOTHING;
