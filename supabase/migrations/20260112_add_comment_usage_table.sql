-- Add comments column to set_records table
ALTER TABLE set_records ADD COLUMN IF NOT EXISTS comments TEXT[] DEFAULT '{}';

-- Create comment_usage table for tracking frequently used comments
CREATE TABLE IF NOT EXISTS comment_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comment_key TEXT NOT NULL,
  muscle_group TEXT,
  movement_pattern TEXT,
  usage_count INT DEFAULT 1,
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(trainer_id, comment_key, muscle_group, movement_pattern)
);

-- Index for fast lookups by trainer and context
CREATE INDEX IF NOT EXISTS idx_comment_usage_lookup
ON comment_usage(trainer_id, muscle_group, movement_pattern);

-- Index for sorting by usage count
CREATE INDEX IF NOT EXISTS idx_comment_usage_count
ON comment_usage(trainer_id, usage_count DESC);

-- Enable RLS
ALTER TABLE comment_usage ENABLE ROW LEVEL SECURITY;

-- RLS policies: trainers can only access their own usage data
CREATE POLICY "Trainers can view own comment usage"
ON comment_usage FOR SELECT
TO authenticated
USING (trainer_id = auth.uid());

CREATE POLICY "Trainers can insert own comment usage"
ON comment_usage FOR INSERT
TO authenticated
WITH CHECK (trainer_id = auth.uid());

CREATE POLICY "Trainers can update own comment usage"
ON comment_usage FOR UPDATE
TO authenticated
USING (trainer_id = auth.uid())
WITH CHECK (trainer_id = auth.uid());

CREATE POLICY "Trainers can delete own comment usage"
ON comment_usage FOR DELETE
TO authenticated
USING (trainer_id = auth.uid());
