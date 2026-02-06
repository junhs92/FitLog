-- Migration: Add html_url column to session_reports table
-- This enables storing shareable HTML report URLs

-- Add html_url column to session_reports
ALTER TABLE session_reports
ADD COLUMN IF NOT EXISTS html_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN session_reports.html_url IS 'Public URL to the shareable HTML version of the report';
