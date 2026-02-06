-- Cleanup test data from workout-related tables
-- Order matters due to foreign key constraints

-- 1. First delete session_reports (depends on sessions)
DELETE FROM session_reports;

-- 2. Delete session_exercises (depends on sessions)
DELETE FROM session_exercises;

-- 3. Delete sessions (depends on workout_programs, accounts)
DELETE FROM sessions;

-- 4. Delete client_exercise_familiarity (depends on accounts, exercises)
DELETE FROM client_exercise_familiarity;

-- 5. Delete workout_programs (depends on accounts)
DELETE FROM workout_programs;
