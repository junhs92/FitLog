-- Migration: Fix infinite recursion in accounts RLS policy
-- Date: 2024-12-08 07:15:00
-- Issue: trainers_view_client_accounts policy causes infinite recursion
--        when querying accounts table to get trainer's account id

-- ============================================
-- 1. Create helper function (SECURITY DEFINER bypasses RLS)
-- ============================================
CREATE OR REPLACE FUNCTION get_my_account_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM accounts WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_my_account_id() TO authenticated;

-- ============================================
-- 2. Drop the problematic policy
-- ============================================
DROP POLICY IF EXISTS trainers_view_client_accounts ON accounts;

-- ============================================
-- 3. Recreate policy using helper function (no recursion)
-- ============================================
CREATE POLICY trainers_view_client_accounts ON accounts
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT client_id
    FROM trainer_client_relationships
    WHERE trainer_id = get_my_account_id()
    AND status = 'active'
  )
);

-- ============================================
-- Notes:
-- - The get_my_account_id() function runs with SECURITY DEFINER
--   which means it bypasses RLS policies
-- - This prevents the infinite recursion that occurred when the
--   policy tried to query the accounts table to find the trainer's id
-- - STABLE keyword indicates the function returns same result for
--   same inputs within a single query (allows query optimization)
-- ============================================
