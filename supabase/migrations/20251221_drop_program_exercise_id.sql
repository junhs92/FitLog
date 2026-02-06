-- =====================================================
-- Drop orphaned program_exercise_id column
-- =====================================================
-- This column referenced the program_exercises table which was dropped
-- in migration 20251220_100000_simplify_workout_structure.sql
-- The column is no longer used in the new dynamic AI session generation flow.

ALTER TABLE session_exercises DROP COLUMN IF EXISTS program_exercise_id;
