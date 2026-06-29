-- Repara contratos ITAP faltantes usando reservas já cadastradas (match por imóvel, não por nome exato)
-- Migration: 00040

DO $$
BEGIN
  WITH src AS (
    SELECT DISTINCT ON (p.id)
      b.company_id,
      p.id AS property_id,
      COALESCE(b.guest_party_id, party_by_name.id) AS tenant_party_id,
      p.code,
      COALESCE(b.monthly_rent, p.base_rent_amount) AS monthly_rent,
      b.payment_due_day AS due_day,
      b.guest_name
    FROM rental_properties p
    JOIN rental_bookings b
      ON b.property_id = p.id
     AND b.check_in = DATE '2026-01-01'
     AND b.check_out = DATE '2027-01-01'
     AND b.status <> 'cancelled'::rental_booking_status
    LEFT JOIN rental_parties party_by_name
      ON party_by_name.company_id = b.company_id
     AND party_by_name.category = 'tenant'::rental_party_category
     AND upper(trim(party_by_name.full_name)) = upper(trim(b.guest_name))
    WHERE p.code LIKE 'ITAP-%'
      AND COALESCE(b.is_fixed_rent, FALSE) = TRUE
    ORDER BY p.id, b.created_at DESC
  ),
  inserted_leases AS (
    INSERT INTO rental_leases (
      company_id,
      property_id,
      primary_tenant_party_id,
      lease_number,
      listing_mode,
      status,
      start_date,
      end_date,
      monthly_rent,
      due_day_of_month,
      notes
    )
    SELECT
      s.company_id,
      s.property_id,
      s.tenant_party_id,
      s.code || '-2026',
      'long_term'::rental_listing_mode,
      'active'::rental_lease_status,
      DATE '2026-01-01',
      DATE '2026-12-31',
      s.monthly_rent,
      s.due_day,
      'Contrato reparado a partir da reserva (00040).'
    FROM src s
    WHERE s.monthly_rent IS NOT NULL
      AND s.due_day IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM rental_leases l
        WHERE l.property_id = s.property_id
          AND l.status = 'active'::rental_lease_status
          AND l.start_date <= DATE '2026-12-31'
          AND (l.end_date IS NULL OR l.end_date >= DATE '2026-01-01')
      )
    RETURNING id, primary_tenant_party_id
  )
  INSERT INTO rental_lease_tenants (lease_id, party_id, is_primary)
  SELECT il.id, il.primary_tenant_party_id, TRUE
  FROM inserted_leases il
  WHERE il.primary_tenant_party_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_lease_tenants lt
      WHERE lt.lease_id = il.id
        AND lt.party_id = il.primary_tenant_party_id
    );

  RAISE NOTICE 'Contratos ITAP reparados (00040).';
END $$;

NOTIFY pgrst, 'reload schema';
