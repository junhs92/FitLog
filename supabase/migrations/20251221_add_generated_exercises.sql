-- Add generated_exercises column to store AI-generated exercise list
ALTER TABLE workout_programs
ADD COLUMN IF NOT EXISTS generated_exercises JSONB DEFAULT '[]'::jsonb;

-- Add comment
COMMENT ON COLUMN workout_programs.generated_exercises IS 'AI-generated exercises for this program: [{exercise_id, name, name_ko, sets, reps, rest_seconds, order_index, ai_reasoning}]';
