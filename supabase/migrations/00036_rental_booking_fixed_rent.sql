-- Aluguel fixo mensal em reservas (com dia de vencimento)
-- Migration: 00036

ALTER TABLE rental_bookings
  ADD COLUMN IF NOT EXISTS is_fixed_rent BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS monthly_rent NUMERIC(14, 2),
  ADD COLUMN IF NOT EXISTS payment_due_day SMALLINT;

ALTER TABLE rental_bookings
  DROP CONSTRAINT IF EXISTS rental_bookings_payment_due_day_valid;

ALTER TABLE rental_bookings
  ADD CONSTRAINT rental_bookings_payment_due_day_valid
  CHECK (payment_due_day IS NULL OR (payment_due_day >= 1 AND payment_due_day <= 28));

NOTIFY pgrst, 'reload schema';
