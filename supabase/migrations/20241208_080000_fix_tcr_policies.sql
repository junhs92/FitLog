-- Migration: Fix infinite recursion in trainer_client_relationships policies
-- Date: 2024-12-08 08:00:00
-- Issue: Policies on trainer_client_relationships query accounts directly,
--        causing infinite recursion when combined with trainers_view_client_accounts
-- Fix: Use get_my_account_id() helper function instead of direct accounts queries

-- ============================================
-- 1. Create additional helper function for role check
-- ============================================
CREATE OR REPLACE FUNCTION is_current_user_trainer()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM accounts
  WHERE user_id = auth.uid()
  LIMIT 1;

  RETURN user_role IN ('trainer', 'both');
END;
$$;

GRANT EXECUTE ON FUNCTION is_current_user_trainer() TO authenticated;

-- ============================================
-- 2. Drop all problematic policies
-- ============================================
DROP POLICY IF EXISTS trainers_view_relationships ON trainer_client_relationships;
DROP POLICY IF EXISTS clients_view_relationships ON trainer_client_relationships;
DROP POLICY IF EXISTS parties_update_relationships ON trainer_client_relationships;
DROP POLICY IF EXISTS trainers_create_relationships ON trainer_client_relationships;

-- ============================================
-- 3. Recreate policies using helper functions
-- ============================================

-- Trainers can view their relationships
CREATE POLICY trainers_view_relationships ON trainer_client_relationships
FOR SELECT
TO authenticated
USING (trainer_id = get_my_account_id());

-- Clients can view their relationships
CREATE POLICY clients_view_relationships ON trainer_client_relationships
FOR SELECT
TO authenticated
USING (client_id = get_my_account_id());

-- Both parties can update relationships
CREATE POLICY parties_update_relationships ON trainer_client_relationships
FOR UPDATE
TO authenticated
USING (
  trainer_id = get_my_account_id()
  OR client_id = get_my_account_id()
);

-- Trainers can create relationships (with role check)
CREATE POLICY trainers_create_relationships ON trainer_client_relationships
FOR INSERT
TO authenticated
WITH CHECK (
  trainer_id = get_my_account_id()
  AND is_current_user_trainer()
);

-- ============================================
-- Notes:
-- - get_my_account_id() returns the current user's account.id
-- - is_current_user_trainer() checks if user has trainer role
-- - Both functions use SECURITY DEFINER + plpgsql to bypass RLS
-- - This breaks the recursion chain that occurred when policies
--   queried accounts table directly
-- ============================================
