-- Migration: Fix infinite recursion in accounts RLS policy (v2)
-- Date: 2024-12-08 07:30:00
-- Issue: SQL functions get inlined, bypassing SECURITY DEFINER
-- Fix: Use plpgsql to prevent inlining

-- ============================================
-- 1. Drop policy FIRST (it depends on the function)
-- ============================================
DROP POLICY IF EXISTS trainers_view_client_accounts ON accounts;

-- ============================================
-- 2. Drop and recreate function with plpgsql (prevents inlining)
-- ============================================
DROP FUNCTION IF EXISTS get_my_account_id();

CREATE OR REPLACE FUNCTION get_my_account_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  account_id uuid;
BEGIN
  SELECT id INTO account_id
  FROM accounts
  WHERE user_id = auth.uid()
  LIMIT 1;

  RETURN account_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_my_account_id() TO authenticated;

-- ============================================
-- 2. Ensure policy uses the function
-- ============================================
DROP POLICY IF EXISTS trainers_view_client_accounts ON accounts;

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
-- - plpgsql functions are NOT inlined by PostgreSQL optimizer
-- - This ensures SECURITY DEFINER is properly applied
-- - The function runs in its own execution context, bypassing RLS
-- ============================================
