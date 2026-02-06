-- =====================================================
-- Drop generated_exercises column from workout_programs
-- =====================================================
-- workout_programs should only store training DIRECTION (goals, split, constraints)
-- Exercises are generated at session start and stored directly in session_exercises

ALTER TABLE workout_programs DROP COLUMN IF EXISTS generated_exercises;
