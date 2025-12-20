-- =============================================
-- Create Sessions and Trainer Messages Tables
-- Migration: 20241208_100000_create_sessions_messages
-- =============================================

-- 1. SESSIONS TABLE
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  session_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
  scheduled_at TIMESTAMPTZ NOT NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  feedback TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE sessions IS 'Training sessions between trainers and clients';
COMMENT ON COLUMN sessions.status IS 'Session status: scheduled, active, completed, cancelled';

-- 2. TRAINER MESSAGES TABLE
CREATE TABLE trainer_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE trainer_messages IS 'Messages from trainers to their clients';

-- =============================================
-- Enable RLS
-- =============================================
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_messages ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS Policies for sessions
-- =============================================

-- Trainers can manage their own sessions
CREATE POLICY "sessions_trainer_all" ON sessions
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their own sessions
CREATE POLICY "sessions_client_view" ON sessions
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- =============================================
-- RLS Policies for trainer_messages
-- =============================================

-- Trainers can manage messages they sent
CREATE POLICY "messages_trainer_all" ON trainer_messages
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view and update (mark read) messages sent to them
CREATE POLICY "messages_client_view" ON trainer_messages
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

CREATE POLICY "messages_client_update" ON trainer_messages
  FOR UPDATE USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  )
  WITH CHECK (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- =============================================
-- Performance Indexes
-- =============================================
CREATE INDEX idx_sessions_trainer ON sessions(trainer_id);
CREATE INDEX idx_sessions_client ON sessions(client_id);
CREATE INDEX idx_sessions_scheduled ON sessions(scheduled_at);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_messages_client ON trainer_messages(client_id);
CREATE INDEX idx_messages_created ON trainer_messages(created_at DESC);
