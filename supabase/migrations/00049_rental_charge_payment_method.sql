-- Forma de pagamento registrada ao confirmar cobrança.

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS paid_payment_method TEXT;

NOTIFY pgrst, 'reload schema';
