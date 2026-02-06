-- =====================================================
-- Cleanup Test Data
-- Keep: accounts, connection_requests, exercises, trainer_client_relationships
-- Delete all data from other tables
-- =====================================================

-- Delete in order of dependencies (child tables first)

-- 1. Delete from session_exercises (depends on sessions)
DELETE FROM session_exercises;

-- 2. Delete from session_reports (depends on sessions)
DELETE FROM session_reports;

-- 3. Delete from sessions (depends on workout_programs)
DELETE FROM sessions;

-- 4. Delete from template_usage (depends on program_templates, workout_programs)
DELETE FROM template_usage;

-- 5. Delete from program_templates (depends on workout_programs)
DELETE FROM program_templates;

-- 6. Delete from workout_programs
DELETE FROM workout_programs;

-- 7. Delete from trainer_messages
DELETE FROM trainer_messages;

-- 8. Delete from client_exercise_familiarity
DELETE FROM client_exercise_familiarity;

-- Verification queries (optional - run to confirm cleanup)
-- SELECT 'session_exercises' as table_name, count(*) as count FROM session_exercises
-- UNION ALL SELECT 'session_reports', count(*) FROM session_reports
-- UNION ALL SELECT 'sessions', count(*) FROM sessions
-- UNION ALL SELECT 'template_usage', count(*) FROM template_usage
-- UNION ALL SELECT 'program_templates', count(*) FROM program_templates
-- UNION ALL SELECT 'workout_programs', count(*) FROM workout_programs
-- UNION ALL SELECT 'trainer_messages', count(*) FROM trainer_messages
-- UNION ALL SELECT 'client_exercise_familiarity', count(*) FROM client_exercise_familiarity;
