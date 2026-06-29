-- Restaura imóveis ITAP-102, ITAP-103, ITAP-104 e ITAP-105 (Praia de Itaparica)
-- Migration: 00038

DO $$
DECLARE
  v_company_id UUID;
  v_condo_id UUID;
  v_landlord_id UUID;
  v_landlord_name TEXT := 'Monica Gomes';
BEGIN
  SELECT id INTO v_company_id
  FROM management_companies
  ORDER BY created_at
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma empresa gestora encontrada.';
  END IF;

  SELECT id INTO v_condo_id
  FROM condominiums
  WHERE name ILIKE '%praia%itaparica%'
  ORDER BY created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    RAISE EXCEPTION 'Condomínio "Praia de Itaparica" não encontrado.';
  END IF;

  SELECT id INTO v_landlord_id
  FROM rental_parties
  WHERE company_id = v_company_id
    AND full_name = v_landlord_name
    AND category = 'landlord'::rental_party_category
  LIMIT 1;

  IF v_landlord_id IS NULL THEN
    INSERT INTO rental_parties (company_id, full_name, category, status)
    VALUES (v_company_id, v_landlord_name, 'landlord'::rental_party_category, 'active'::entity_status)
    RETURNING id INTO v_landlord_id;
  END IF;

  CREATE TEMP TABLE _restore_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT,
    due_day SMALLINT,
    monthly_rent NUMERIC(14, 2)
  ) ON COMMIT DROP;

  INSERT INTO _restore_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
    ('105', NULL, NULL, NULL);

  INSERT INTO rental_properties (
    company_id,
    condominium_id,
    owner_party_id,
    property_type,
    listing_mode,
    code,
    title,
    address_apartment,
    base_rent_amount,
    status
  )
  SELECT
    v_company_id,
    v_condo_id,
    v_landlord_id,
    'apartment'::rental_property_type,
    'long_term'::rental_listing_mode,
    'ITAP-' || r.apto,
    'Apto ' || r.apto,
    r.apto,
    r.monthly_rent,
    'active'::entity_status
  FROM _restore_rows r
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_properties p
    WHERE p.company_id = v_company_id
      AND p.code = 'ITAP-' || r.apto
  );

  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT DISTINCT
    v_company_id,
    r.tenant_name,
    'tenant'::rental_party_category,
    'active'::entity_status
  FROM _restore_rows r
  WHERE r.tenant_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_parties p
      WHERE p.company_id = v_company_id
        AND p.full_name = r.tenant_name
        AND p.category = 'tenant'::rental_party_category
    );

  INSERT INTO rental_bookings (
    company_id,
    property_id,
    guest_party_id,
    channel,
    status,
    guest_name,
    guests_count,
    check_in,
    check_out,
    is_fixed_rent,
    monthly_rent,
    payment_due_day,
    total_amount,
    notes
  )
  SELECT
    v_company_id,
    p.id,
    party.id,
    'direct'::rental_booking_channel,
    'confirmed'::rental_booking_status,
    r.tenant_name,
    1,
    DATE '2026-01-01',
    DATE '2027-01-01',
    TRUE,
    r.monthly_rent,
    r.due_day,
    r.monthly_rent,
    'Restaurado via migration 00038.'
  FROM _restore_rows r
  JOIN rental_properties p
    ON p.company_id = v_company_id
   AND p.code = 'ITAP-' || r.apto
  LEFT JOIN rental_parties party
    ON party.company_id = v_company_id
   AND party.full_name = r.tenant_name
   AND party.category = 'tenant'::rental_party_category
  WHERE r.tenant_name IS NOT NULL
    AND r.monthly_rent IS NOT NULL
    AND r.due_day IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_bookings b
      WHERE b.property_id = p.id
        AND b.check_in = DATE '2026-01-01'
        AND b.check_out = DATE '2027-01-01'
        AND b.status <> 'cancelled'::rental_booking_status
    );

  RAISE NOTICE 'Imóveis ITAP-102 a ITAP-105 restaurados (locador: %).', v_landlord_name;
END $$;

NOTIFY pgrst, 'reload schema';
