-- Fix sessions_trainer_all RLS policy to use get_my_account_id() helper
-- instead of raw subquery on accounts table, and add WITH CHECK clause for INSERT support.
--
-- Root cause: The USING clause subquery (SELECT id FROM accounts WHERE user_id = auth.uid())
-- hits the accounts table's own RLS policies during INSERT evaluation, causing RLS recursion.
-- The get_my_account_id() function is SECURITY DEFINER and bypasses RLS.

-- Also fix sessions_client_view which has the same raw subquery pattern
DROP POLICY IF EXISTS "sessions_trainer_all" ON sessions;
DROP POLICY IF EXISTS "sessions_client_view" ON sessions;

CREATE POLICY "sessions_trainer_all" ON sessions
  FOR ALL
  USING (trainer_id = get_my_account_id())
  WITH CHECK (trainer_id = get_my_account_id());

CREATE POLICY "sessions_client_view" ON sessions
  FOR SELECT
  USING (client_id = get_my_account_id());
