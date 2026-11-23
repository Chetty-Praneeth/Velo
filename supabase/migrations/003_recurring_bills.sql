-- ============================================================
-- ProjectM — Recurring Bills & Subscriptions
-- Run this in the Supabase SQL Editor.
--
-- Bills (rent, phone recharge, Spotify…) are set aside from the budget at
-- the start of each cycle. Paying one logs a normal expense linked to the
-- bill through expenses.recurring_bill_id.
-- ============================================================

CREATE TABLE IF NOT EXISTS recurring_bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  category TEXT NOT NULL DEFAULT 'Bills',
  due_day INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 31),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE recurring_bills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own recurring bills" ON recurring_bills;
CREATE POLICY "Users can manage own recurring bills"
  ON recurring_bills FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_recurring_bills_user
  ON recurring_bills(user_id);

-- Link a logged payment back to its bill. Deleting a bill keeps its past
-- payments as ordinary expenses.
ALTER TABLE expenses
ADD COLUMN IF NOT EXISTS recurring_bill_id UUID
  REFERENCES recurring_bills(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_recurring_bill
  ON expenses(recurring_bill_id)
  WHERE recurring_bill_id IS NOT NULL;
