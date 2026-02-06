-- Migration: create_client_schedules
-- Description: Create client_schedules table for trainer-client appointments

-- Create updated_at trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create client_schedules table
CREATE TABLE client_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Scheduling details
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_client_schedules_trainer ON client_schedules(trainer_id);
CREATE INDEX idx_client_schedules_client ON client_schedules(client_id);
CREATE INDEX idx_client_schedules_scheduled_at ON client_schedules(scheduled_at);
CREATE INDEX idx_client_schedules_status ON client_schedules(status);

-- Enable RLS
ALTER TABLE client_schedules ENABLE ROW LEVEL SECURITY;

-- Trainers can manage their own schedules
CREATE POLICY "schedules_trainer_all" ON client_schedules
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their appointments
CREATE POLICY "schedules_client_view" ON client_schedules
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Updated_at trigger
CREATE TRIGGER update_client_schedules_updated_at
  BEFORE UPDATE ON client_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
