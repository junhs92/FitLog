-- Allow clients to update their own report's viewed status
-- This enables marking reports as "viewed" when clients open them

CREATE POLICY "Clients can mark reports as viewed"
ON session_reports
FOR UPDATE
USING (
  session_id IN (
    SELECT sessions.id
    FROM sessions
    WHERE sessions.client_id IN (
      SELECT accounts.id
      FROM accounts
      WHERE accounts.user_id = auth.uid()
    )
  )
)
WITH CHECK (
  session_id IN (
    SELECT sessions.id
    FROM sessions
    WHERE sessions.client_id IN (
      SELECT accounts.id
      FROM accounts
      WHERE accounts.user_id = auth.uid()
    )
  )
);
