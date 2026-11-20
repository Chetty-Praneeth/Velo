-- ============================================================
-- ProjectM — Add Income Support Migration
-- Run this in the Supabase SQL Editor to support logging income.
-- ============================================================

-- Add type column to expenses table (defaulting to 'expense')
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'expense' 
CHECK (type IN ('expense', 'income'));
