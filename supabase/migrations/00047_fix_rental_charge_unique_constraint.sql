-- O índice único impedia editar cobranças quando já existia outra do mesmo mês.
-- A deduplicação continua na função generate_rental_monthly_charges.

DROP INDEX IF EXISTS idx_rental_charges_lease_ref_month;
DROP INDEX IF EXISTS idx_rental_charges_booking_ref_month;

NOTIFY pgrst, 'reload schema';
