-- Migration: Create session_packages table for tracking client session credits

CREATE TABLE session_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

  -- Package details
  package_name TEXT NOT NULL,
  total_sessions INTEGER NOT NULL CHECK (total_sessions > 0),
  sessions_used INTEGER NOT NULL DEFAULT 0 CHECK (sessions_used >= 0),
  price DECIMAL(10,2),

  -- Dates
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,

  -- Status
  is_active BOOLEAN DEFAULT true,
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_session_packages_trainer ON session_packages(trainer_id);
CREATE INDEX idx_session_packages_client ON session_packages(client_id);
CREATE INDEX idx_session_packages_active ON session_packages(trainer_id, client_id, is_active)
  WHERE is_active = true;

-- RLS
ALTER TABLE session_packages ENABLE ROW LEVEL SECURITY;

-- Trainers can manage packages for their clients
CREATE POLICY "packages_trainer_all" ON session_packages
  FOR ALL USING (
    trainer_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Clients can view their own packages
CREATE POLICY "packages_client_view" ON session_packages
  FOR SELECT USING (
    client_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
  );

-- Updated_at trigger
CREATE TRIGGER update_session_packages_updated_at
  BEFORE UPDATE ON session_packages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
