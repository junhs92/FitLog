-- Migration: Complete exercise classification (family, movement_detail, angle, grip_orientation)
-- Created: 2026-02-12
-- Purpose: Populates all metadata fields + adds grip_orientation column for hierarchical picker
-- Run manually via Supabase Dashboard SQL Editor or supabase db push

-- ============================================
-- STEP 0: Add grip_orientation column
-- ============================================
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS grip_orientation TEXT;

ALTER TABLE exercises ADD CONSTRAINT exercises_grip_orientation_check
  CHECK (grip_orientation IN ('overhand', 'underhand', 'neutral', 'mixed', 'rotating', 'na'));

CREATE INDEX IF NOT EXISTS idx_exercises_grip_orientation
  ON exercises (grip_orientation) WHERE grip_orientation IS NOT NULL;

-- ============================================
-- STEP 1: Remove duplicate mobility exercises
-- ============================================
DELETE FROM exercises e1
USING exercises e2
WHERE e1.name = e2.name
  AND e1.category = 'mobility'
  AND e2.category = 'mobility'
  AND e1.id != e2.id
  AND (e1.movement_group = 'other' OR e1.movement_detail IS NULL)
  AND (e2.movement_group != 'other' OR e2.movement_detail IS NOT NULL);

-- ============================================
-- STEP 2: Fill FAMILY for all exercises
-- ============================================

-- CHEST: Bench Press family
UPDATE exercises SET family = 'bench_press' WHERE name IN (
  'Barbell Bench Press', 'Incline Barbell Bench Press', 'Decline Bench Press',
  'Dumbbell Bench Press', 'Incline Dumbbell Press', 'Decline Dumbbell Press',
  'Smith Machine Bench Press', 'Smith Machine Incline Press', 'Machine Chest Press',
  'Floor Press', 'Close Grip Bench Press'
);

-- CHEST: Fly family
UPDATE exercises SET family = 'fly' WHERE name IN (
  'Dumbbell Fly', 'Incline Dumbbell Fly', 'Decline Dumbbell Fly',
  'Pec Deck Machine', 'Machine Fly', 'Cable Crossover',
  'High Cable Fly', 'Low Cable Fly'
);

-- CHEST: Push-up family
UPDATE exercises SET family = 'pushup' WHERE name IN (
  'Push-Up', 'Close Grip Push-Up', 'Wide Grip Push-Up', 'Diamond Push-Up'
);

-- CHEST: Pullover family
UPDATE exercises SET family = 'pullover' WHERE name IN (
  'Dumbbell Pullover', 'Cable Pullover'
);

-- SHOULDERS: Overhead Press family
UPDATE exercises SET family = 'overhead_press' WHERE name IN (
  'Arnold Press', 'Behind Neck Press', 'Bradford Press', 'Landmine Press',
  'Machine Shoulder Press', 'Overhead Press', 'Seated Dumbbell Press', 'Z Press'
);

-- SHOULDERS: Lateral Raise family
UPDATE exercises SET family = 'lateral_raise' WHERE name IN (
  'Cable Lateral Raise', 'Lateral Raise', 'Machine Lateral Raise'
);

-- SHOULDERS: Front Raise family
UPDATE exercises SET family = 'front_raise' WHERE name = 'Front Raise';

-- SHOULDERS: Rear Delt family
UPDATE exercises SET family = 'rear_delt' WHERE name IN (
  'Rear Delt Fly', 'Prone Rear Delt Raise', 'Reverse Pec Deck', 'Face Pull', 'Rope Face Pull'
);

-- SHOULDERS: Y Raise family
UPDATE exercises SET family = 'y_raise' WHERE name IN (
  'Dumbbell Y Raise', 'Lu Raise'
);

-- SHOULDERS: Shrug family
UPDATE exercises SET family = 'shrug' WHERE name IN (
  'Barbell Shrug', 'Dumbbell Shrug'
);

-- SHOULDERS: Upright Row family
UPDATE exercises SET family = 'upright_row' WHERE name = 'Upright Row';

-- SHOULDERS: Mobility
UPDATE exercises SET family = 'shoulder_mobility' WHERE name IN (
  'Shoulder Dislocates', 'Wall Slide', 'Arm Circle'
);

-- TRICEPS: Dip family
UPDATE exercises SET family = 'dip' WHERE name IN (
  'Dips', 'Bench Dips'
);

-- TRICEPS: Tricep Extension family
UPDATE exercises SET family = 'tricep_extension' WHERE name IN (
  'Cable Overhead Extension', 'Dumbbell Skull Crusher', 'French Press',
  'Machine Tricep Extension', 'Overhead Tricep Extension', 'Skull Crusher',
  'Rope Tricep Pushdown', 'Single Arm Pushdown', 'Reverse Grip Pushdown',
  'Tricep Kickback', 'Tricep Pushdown'
);

-- TRICEPS: JM Press family
UPDATE exercises SET family = 'jm_press' WHERE name = 'JM Press';

-- TRICEPS: Tate Press family
UPDATE exercises SET family = 'tate_press' WHERE name = 'Tate Press';

-- BACK: Row family
UPDATE exercises SET family = 'row' WHERE name IN (
  'Barbell Row', 'Chest Supported Row', 'Dumbbell Row', 'Inverted Row',
  'Kroc Row', 'Machine Row', 'Meadows Row', 'One Arm Dumbbell Row',
  'Pendlay Row', 'Seal Row', 'Seated Cable Row', 'Single Arm Cable Row',
  'Smith Machine Row', 'T-Bar Row'
);

-- BACK: Pulldown family
UPDATE exercises SET family = 'pulldown' WHERE name IN (
  'Lat Pulldown', 'Close Grip Lat Pulldown', 'Wide Grip Lat Pulldown',
  'Reverse Grip Lat Pulldown', 'Straight Arm Pulldown'
);

-- BACK: Pull-up family
UPDATE exercises SET family = 'pullup' WHERE name IN (
  'Pull-Up', 'Chin-Up', 'Assisted Pull-Up'
);

-- BACK: Rack Pull family
UPDATE exercises SET family = 'rack_pull' WHERE name = 'Rack Pull';

-- BACK: Snatch Grip Deadlift -> deadlift family
UPDATE exercises SET family = 'deadlift' WHERE name = 'Snatch Grip Deadlift';

-- BACK: Spine Mobility
UPDATE exercises SET family = 'spine_mobility' WHERE name IN (
  'Cat-Cow', 'Thoracic Spine Rotation', 'Thread the Needle',
  'Seated Spinal Twist', 'Scorpion Stretch', 'Child''s Pose',
  'World Greatest Stretch'
);

-- BICEPS: Curl family
UPDATE exercises SET family = 'curl' WHERE name IN (
  'Barbell Curl', '21s Curl', 'Bayesian Curl', 'Cable Curl',
  'Cable Hammer Curl', 'Concentration Curl', 'Cross Body Hammer Curl',
  'Drag Curl', 'Dumbbell Curl', 'EZ Bar Curl', 'Hammer Curl',
  'Incline Dumbbell Curl', 'Machine Preacher Curl', 'Preacher Curl',
  'Reverse Curl', 'Spider Curl', 'Zottman Curl'
);

-- FOREARMS: Wrist Curl family
UPDATE exercises SET family = 'wrist_curl' WHERE name IN (
  'Wrist Curl', 'Reverse Wrist Curl', 'Behind Back Wrist Curl'
);

-- FOREARMS: Grip family
UPDATE exercises SET family = 'grip' WHERE name IN (
  'Plate Pinch', 'Farmer''s Hold'
);

-- LEGS: Squat family
UPDATE exercises SET family = 'squat' WHERE name IN (
  'Barbell Squat', 'Belt Squat', 'Box Squat', 'Bulgarian Split Squat',
  'Cyclist Squat', 'Front Squat', 'Goblet Squat', 'Hack Squat',
  'Leg Press', 'Pause Squat', 'Pendulum Squat', 'Smith Machine Squat',
  'Zercher Squat', 'Sissy Squat', 'Walking Lunge'
);

-- LEGS: Lunge family
UPDATE exercises SET family = 'lunge' WHERE name IN (
  'Reverse Lunge', 'Split Squat', 'Step Up'
);

-- LEGS: Deadlift family
UPDATE exercises SET family = 'deadlift' WHERE name IN (
  'Deadlift', 'Deficit Deadlift', 'Sumo Deadlift', 'Trap Bar Deadlift',
  'Good Morning', 'Stiff Leg Deadlift', 'Romanian Deadlift', 'Dumbbell RDL',
  'Single Leg Deadlift', 'Kettlebell Swing', 'Cable Pull Through'
);

-- LEGS: Hip Thrust family
UPDATE exercises SET family = 'hip_thrust' WHERE name IN (
  'Hip Thrust', 'Banded Hip Thrust', 'Single Leg Hip Thrust', 'Glute Bridge', 'Frog Pumps'
);

-- LEGS: Leg Curl family
UPDATE exercises SET family = 'leg_curl' WHERE name IN (
  'Cable Leg Curl', 'Dumbbell Leg Curl', 'Lying Leg Curl',
  'Seated Leg Curl', 'Single Leg Lying Curl', 'Nordic Curl', 'Glute Ham Raise'
);

-- LEGS: Leg Extension family
UPDATE exercises SET family = 'leg_extension' WHERE name = 'Leg Extension';

-- LEGS: Calf Raise family
UPDATE exercises SET family = 'calf_raise' WHERE name IN (
  'Standing Calf Raise', 'Seated Calf Raise', 'Donkey Calf Raise',
  'Single Leg Calf Raise', 'Smith Machine Calf Raise',
  'Leg Press Calf Raise', 'Calf Press on Hack Squat', 'Tibialis Raise'
);

-- LEGS: Kickback family
UPDATE exercises SET family = 'glute_kickback' WHERE name IN (
  'Cable Kickback', 'Donkey Kicks', 'Fire Hydrant'
);

-- LEGS: Reverse Hyper family
UPDATE exercises SET family = 'reverse_hyper' WHERE name = 'Reverse Hyperextension';

-- LEGS: Hip Adduction/Abduction
UPDATE exercises SET family = 'hip_adduction' WHERE name IN (
  'Adductor Machine', 'Cable Hip Adduction', 'Copenhagen Plank'
);
UPDATE exercises SET family = 'hip_abduction' WHERE name = 'Banded Clamshell';

-- LEGS: Hip Mobility
UPDATE exercises SET family = 'hip_mobility' WHERE name IN (
  'Hip Flexor Stretch', 'Pigeon Stretch', '90/90 Hip Stretch',
  'Couch Stretch', 'Butterfly Stretch', 'Hip Circle', 'Leg Swings'
);

-- LEGS: Ankle Mobility
UPDATE exercises SET family = 'ankle_mobility' WHERE name = 'Ankle Circles';

-- CORE: Plank family
UPDATE exercises SET family = 'plank' WHERE name IN (
  'Plank', 'Side Plank', 'Hollow Body Hold', 'L-Sit', 'Dead Bug', 'Bird Dog'
);

-- CORE: Crunch family
UPDATE exercises SET family = 'crunch' WHERE name IN (
  'Crunch', 'Bicycle Crunch', 'Cable Crunch', 'Reverse Crunch',
  'Hanging Leg Raise', 'Ab Wheel Rollout', 'V-Up', 'Toe Touch', 'Dragon Flag'
);

-- CORE: Carry family
UPDATE exercises SET family = 'carry' WHERE name IN (
  'Farmers Walk', 'Overhead Carry', 'Suitcase Carry', 'Trap Bar Carry'
);

-- CORE: Rotation family
UPDATE exercises SET family = 'rotation' WHERE name IN (
  'Russian Twist', 'Cable Woodchop', 'Landmine Rotation', 'Pallof Press'
);

-- CORE: Mountain Climber
UPDATE exercises SET family = 'mountain_climber' WHERE name = 'Mountain Climbers';

-- FULL BODY: Sled family
UPDATE exercises SET family = 'sled' WHERE name IN ('Sled Push', 'Sled Pull');

-- FULL BODY: Jump family
UPDATE exercises SET family = 'jump' WHERE name IN ('Box Jump', 'Jump Rope');

-- FULL BODY: Burpee family
UPDATE exercises SET family = 'burpee' WHERE name = 'Burpee';

-- FULL BODY: Battle Ropes
UPDATE exercises SET family = 'battle_ropes' WHERE name = 'Battle Ropes';

-- FULL BODY: Wall Ball
UPDATE exercises SET family = 'wall_ball' WHERE name = 'Wall Ball';

-- CARDIO: Cardio Machine family
UPDATE exercises SET family = 'cardio_machine' WHERE name IN (
  'Bike', 'Rowing Machine', 'Stair Climber', 'Treadmill Running'
);

-- MOBILITY: General
UPDATE exercises SET family = 'yoga' WHERE name = 'Downward Dog';
UPDATE exercises SET family = 'foam_roll' WHERE name = 'Foam Roll';

-- ============================================
-- STEP 3: Fill missing MOVEMENT_DETAIL
-- ============================================

UPDATE exercises SET movement_detail = 'squat' WHERE movement_detail = 'lunge';

UPDATE exercises SET movement_detail = 'anti_extension'
WHERE name IN ('Ab Wheel Rollout', 'Bird Dog', 'Cable Crunch', 'Crunch',
  'Dead Bug', 'Hanging Leg Raise', 'Plank') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'anti_lateral_flexion'
WHERE name IN ('Pallof Press', 'Suitcase Carry') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'rotation'
WHERE name IN ('Cat-Cow', 'Hip Circle') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'vertical'
WHERE muscle_group = 'biceps' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'squat'
WHERE muscle_group = 'calves' AND movement_group = 'legs' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'hinge'
WHERE name IN ('Lying Leg Curl', 'Seated Leg Curl') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'squat'
WHERE name = 'Leg Extension' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'vertical'
WHERE name = 'Front Raise' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'horizontal'
WHERE name IN ('Lateral Raise', 'Rear Delt Fly') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'anti_lateral_flexion'
WHERE name = 'Overhead Carry' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'vertical'
WHERE name IN ('Overhead Tricep Extension', 'Skull Crusher', 'Tricep Pushdown') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'horizontal'
WHERE name = 'Tricep Kickback' AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'anti_lateral_flexion'
WHERE name IN ('Farmers Walk', 'Trap Bar Carry') AND movement_detail IS NULL;

UPDATE exercises SET movement_detail = 'rotation'
WHERE name = 'World Greatest Stretch' AND movement_detail IS NULL;

-- ============================================
-- STEP 4: Fill ANGLE for applicable exercises
-- ============================================

-- Expand angle constraint to include 'high' and 'low' for cable pulley positions
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_angle_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_angle_check
  CHECK (angle IS NULL OR angle IN ('flat','incline','decline','high','low','neutral','na'));

UPDATE exercises SET angle = 'flat' WHERE name IN (
  'Barbell Bench Press', 'Dumbbell Bench Press', 'Smith Machine Bench Press',
  'Machine Chest Press', 'Floor Press', 'Close Grip Bench Press',
  'Dumbbell Fly', 'Pec Deck Machine', 'Machine Fly', 'Cable Crossover',
  'Push-Up', 'Close Grip Push-Up', 'Wide Grip Push-Up'
) AND angle IS NULL;

UPDATE exercises SET angle = 'incline' WHERE name IN (
  'Incline Barbell Bench Press', 'Incline Dumbbell Press',
  'Smith Machine Incline Press', 'Incline Dumbbell Fly',
  'Low Cable Fly', 'Incline Dumbbell Curl'
) AND angle IS NULL;

UPDATE exercises SET angle = 'decline' WHERE name IN (
  'Decline Bench Press', 'Decline Dumbbell Press', 'Decline Dumbbell Fly',
  'High Cable Fly'
) AND angle IS NULL;

UPDATE exercises SET angle = 'high' WHERE name IN (
  'Lat Pulldown', 'Close Grip Lat Pulldown', 'Wide Grip Lat Pulldown',
  'Reverse Grip Lat Pulldown', 'Straight Arm Pulldown',
  'Tricep Pushdown', 'Rope Tricep Pushdown',
  'Single Arm Pushdown', 'Reverse Grip Pushdown',
  'Cable Crunch', 'Cable Overhead Extension', 'Cable Pullover'
) AND angle IS NULL;

UPDATE exercises SET angle = 'low' WHERE name IN (
  'Seated Cable Row', 'Single Arm Cable Row',
  'Face Pull', 'Rope Face Pull', 'Cable Curl',
  'Cable Hammer Curl', 'Bayesian Curl', 'Cable Pull Through',
  'Cable Kickback', 'Cable Leg Curl', 'Cable Hip Adduction',
  'Pallof Press', 'Cable Woodchop', 'Cable Lateral Raise'
) AND angle IS NULL;

-- ============================================
-- STEP 5: Fill GRIP_ORIENTATION
-- ============================================

-- OVERHAND: Pronated grip
UPDATE exercises SET grip_orientation = 'overhand' WHERE name IN (
  'Barbell Row', 'Pendlay Row', 'Barbell Bench Press', 'Incline Barbell Bench Press',
  'Decline Bench Press', 'Close Grip Bench Press', 'Overhead Press',
  'Behind Neck Press', 'Skull Crusher', 'Dumbbell Skull Crusher', 'French Press',
  'Pull-Up', 'Lat Pulldown', 'Wide Grip Lat Pulldown',
  'Straight Arm Pulldown', 'Barbell Curl', 'Reverse Curl',
  'Barbell Shrug', 'Upright Row', 'Reverse Wrist Curl',
  'Tricep Pushdown', 'EZ Bar Curl', 'Preacher Curl',
  'Smith Machine Bench Press', 'Smith Machine Incline Press',
  'Smith Machine Row', 'Smith Machine Squat', 'T-Bar Row'
);

-- UNDERHAND: Supinated grip
UPDATE exercises SET grip_orientation = 'underhand' WHERE name IN (
  'Chin-Up', 'Reverse Grip Lat Pulldown', 'Close Grip Lat Pulldown',
  'Bayesian Curl', 'Cable Curl', 'Concentration Curl',
  'Dumbbell Curl', 'Incline Dumbbell Curl', 'Spider Curl',
  'Drag Curl', '21s Curl', 'Machine Preacher Curl',
  'Wrist Curl', 'Behind Back Wrist Curl',
  'Reverse Grip Pushdown'
);

-- NEUTRAL: Neutral/hammer grip
UPDATE exercises SET grip_orientation = 'neutral' WHERE name IN (
  'Hammer Curl', 'Cable Hammer Curl', 'Cross Body Hammer Curl',
  'Dumbbell Row', 'One Arm Dumbbell Row', 'Kroc Row', 'Meadows Row',
  'Chest Supported Row', 'Seal Row',
  'Rope Tricep Pushdown', 'Rope Face Pull',
  'Dumbbell Bench Press', 'Incline Dumbbell Press', 'Decline Dumbbell Press',
  'Floor Press', 'Dumbbell Fly', 'Incline Dumbbell Fly', 'Decline Dumbbell Fly',
  'Seated Dumbbell Press', 'Lateral Raise', 'Front Raise',
  'Dumbbell Shrug', 'Dumbbell Pullover', 'Cable Pullover',
  'Goblet Squat', 'Trap Bar Deadlift', 'Farmers Walk', 'Trap Bar Carry',
  'Farmer''s Hold', 'Assisted Pull-Up',
  'Seated Cable Row', 'Single Arm Cable Row', 'Cable Lateral Raise',
  'Machine Chest Press', 'Machine Shoulder Press', 'Machine Row',
  'Machine Fly', 'Pec Deck Machine', 'Machine Lateral Raise',
  'Machine Tricep Extension', 'Machine Preacher Curl',
  'Single Arm Pushdown',
  'Cable Overhead Extension', 'Overhead Tricep Extension',
  'Tricep Kickback', 'Cable Crossover', 'High Cable Fly', 'Low Cable Fly',
  'Dumbbell Y Raise', 'Lu Raise'
);

-- MIXED: Mixed grip
UPDATE exercises SET grip_orientation = 'mixed' WHERE name IN (
  'Deadlift', 'Rack Pull'
);

-- ROTATING: Grip rotation during movement
UPDATE exercises SET grip_orientation = 'rotating' WHERE name IN (
  'Arnold Press', 'Zottman Curl', 'Bradford Press'
);

-- NA: Bodyweight, fixed machines, legs, core
UPDATE exercises SET grip_orientation = 'na' WHERE name IN (
  'Push-Up', 'Close Grip Push-Up', 'Wide Grip Push-Up', 'Diamond Push-Up',
  'Dips', 'Bench Dips', 'Inverted Row',
  'Plank', 'Side Plank', 'Hollow Body Hold', 'L-Sit', 'Dead Bug', 'Bird Dog',
  'Crunch', 'Bicycle Crunch', 'Reverse Crunch', 'V-Up', 'Toe Touch', 'Dragon Flag',
  'Hanging Leg Raise', 'Ab Wheel Rollout', 'Mountain Climbers',
  'Russian Twist', 'Cable Crunch', 'Pallof Press',
  'Cable Woodchop', 'Landmine Rotation',
  'Barbell Squat', 'Front Squat', 'Hack Squat', 'Belt Squat',
  'Box Squat', 'Pause Squat', 'Cyclist Squat', 'Zercher Squat',
  'Pendulum Squat', 'Sissy Squat', 'Leg Press',
  'Bulgarian Split Squat', 'Walking Lunge', 'Reverse Lunge', 'Split Squat', 'Step Up',
  'Romanian Deadlift', 'Stiff Leg Deadlift', 'Sumo Deadlift',
  'Deficit Deadlift', 'Snatch Grip Deadlift', 'Dumbbell RDL',
  'Single Leg Deadlift', 'Good Morning',
  'Hip Thrust', 'Banded Hip Thrust', 'Single Leg Hip Thrust', 'Glute Bridge', 'Frog Pumps',
  'Lying Leg Curl', 'Seated Leg Curl', 'Single Leg Lying Curl',
  'Cable Leg Curl', 'Dumbbell Leg Curl', 'Nordic Curl', 'Glute Ham Raise',
  'Leg Extension', 'Adductor Machine', 'Cable Hip Adduction', 'Banded Clamshell',
  'Standing Calf Raise', 'Seated Calf Raise', 'Donkey Calf Raise',
  'Single Leg Calf Raise', 'Smith Machine Calf Raise',
  'Leg Press Calf Raise', 'Calf Press on Hack Squat', 'Tibialis Raise',
  'Cable Kickback', 'Donkey Kicks', 'Fire Hydrant', 'Copenhagen Plank',
  'Reverse Hyperextension', 'Kettlebell Swing', 'Cable Pull Through',
  'Sled Push', 'Sled Pull', 'Box Jump', 'Jump Rope', 'Burpee',
  'Battle Ropes', 'Wall Ball',
  'Bike', 'Rowing Machine', 'Stair Climber', 'Treadmill Running',
  'Hip Flexor Stretch', 'Pigeon Stretch', '90/90 Hip Stretch',
  'Couch Stretch', 'Butterfly Stretch', 'Hip Circle', 'Leg Swings',
  'Ankle Circles', 'Shoulder Dislocates', 'Wall Slide', 'Arm Circle',
  'Cat-Cow', 'Thoracic Spine Rotation', 'Thread the Needle',
  'Seated Spinal Twist', 'Scorpion Stretch', 'Child''s Pose',
  'World Greatest Stretch', 'Downward Dog', 'Foam Roll',
  'Suitcase Carry', 'Overhead Carry',
  'Rear Delt Fly', 'Prone Rear Delt Raise', 'Reverse Pec Deck', 'Face Pull',
  'Plate Pinch', 'JM Press', 'Tate Press', 'Z Press', 'Landmine Press'
);

-- ============================================
-- VERIFICATION QUERIES (run after migration)
-- ============================================
-- SELECT COUNT(*) as total, COUNT(family) as has_family, COUNT(angle) as has_angle, COUNT(grip_orientation) as has_grip FROM exercises WHERE is_custom = false;
-- SELECT family, COUNT(*) as cnt FROM exercises WHERE family IS NOT NULL GROUP BY family ORDER BY family;
-- SELECT grip_orientation, COUNT(*) as cnt FROM exercises WHERE grip_orientation IS NOT NULL GROUP BY grip_orientation;
-- SELECT name FROM exercises WHERE family IS NULL AND is_custom = false;
