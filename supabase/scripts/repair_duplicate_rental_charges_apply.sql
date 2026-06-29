-- APAGAR duplicatas: mantém cobrança do CONTRATO, remove da RESERVA.
-- Cole e execute APENAS este bloco no SQL Editor (uma query só).

DELETE FROM rental_charges
WHERE id IN (
  SELECT rc_booking.id
  FROM rental_charges rc_booking
  INNER JOIN rental_charges rc_lease
    ON rc_lease.property_id = rc_booking.property_id
   AND rc_lease.lease_id IS NOT NULL
   AND rc_lease.charge_type = 'rent'
   AND rc_lease.status <> 'cancelled'
   AND rc_lease.financial_record_id IS NULL
  WHERE rc_booking.booking_id IS NOT NULL
    AND rc_booking.charge_type = 'rent'
    AND rc_booking.status <> 'cancelled'
    AND rc_booking.financial_record_id IS NULL
    AND COALESCE(rc_lease.reference_month, date_trunc('month', rc_lease.due_date)::date)
      = COALESCE(rc_booking.reference_month, date_trunc('month', rc_booking.due_date)::date)
);
