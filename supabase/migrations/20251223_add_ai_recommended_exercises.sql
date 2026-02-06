-- Migration: Add ai_recommended_exercises column to sessions table
-- Purpose: Store original AI-recommended exercises separately from reasoning
--
-- ai_reasoning: Stores AI's explanations for WHY exercises were selected (text)
-- ai_recommended_exercises: Stores the ORIGINAL exercise list before user modifications (JSONB)

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS ai_recommended_exercises JSONB DEFAULT NULL;

-- Add comments explaining column purposes
COMMENT ON COLUMN sessions.ai_recommended_exercises IS 'Original list of exercises recommended by AI before user modifications. Stored as JSONB array containing exercise details.';
COMMENT ON COLUMN sessions.ai_reasoning IS 'AI reasoning and explanations for exercise selection decisions.';
