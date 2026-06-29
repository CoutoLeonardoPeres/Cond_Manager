-- Carga inicial: imóveis, inquilinos e reservas (aluguel fixo) — Condomínio Praia de Itaparica
-- Migration: 00037
--
-- Pré-requisitos:
--   1. Condomínio "Praia de Itaparica" já cadastrado (ajuste o filtro em v_condo_name se o nome for diferente).
--   2. Empresa gestora com módulo locação ativo.
--   3. Migration 00036 aplicada (is_fixed_rent, monthly_rent, payment_due_day em rental_bookings).
--
-- Período: alugado de 01/01/2026 a 31/12/2026 (check_out exclusivo em 01/01/2027).
-- Locador de todos os imóveis: Monica Gomes (categoria landlord em rental_parties).

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
    RAISE EXCEPTION 'Nenhuma empresa gestora encontrada. Cadastre uma management_company antes.';
  END IF;

  SELECT id INTO v_condo_id
  FROM condominiums
  WHERE name ILIKE '%praia%itaparica%'
  ORDER BY created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    RAISE EXCEPTION 'Condomínio "Praia de Itaparica" não encontrado. Cadastre-o antes de rodar esta migration.';
  END IF;

  CREATE TEMP TABLE _itaparica_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT,
    due_day SMALLINT,
    monthly_rent NUMERIC(14, 2)
  ) ON COMMIT DROP;

  INSERT INTO _itaparica_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
    ('105', NULL, NULL, NULL),
    ('106', 'EDIMAR', 16, 830.00),
    ('107', 'THIAGO', 25, 730.00),
    ('108', 'JÚLIA', 16, 830.00),
    ('109', 'HAROLDO', 15, 830.00),
    ('110', 'EDUARDO', 6, 830.00),
    ('111', 'GEOVANE', 17, 830.00),
    ('112', 'ELIANE', 15, 830.00),
    ('113', 'ALEXANDER', 25, 1400.00),
    ('114', 'JOSÉ LÚCIO', 7, 1350.00),
    ('115', 'PAULO', 19, 1400.00),
    ('116', 'CARIOCA', 14, 1400.00),
    ('117', 'ANTÔNIO', 1, 1400.00),
    ('118', 'SIRLENE', 12, 1400.00),
    ('119', 'ROBSON', 3, 1400.00),
    ('120', 'ERIC', 13, 1400.00),
    ('121', 'RODRIGO', 17, 1400.00),
    ('122', 'RICARDO', 1, 1400.00),
    ('123', 'LAURA', 4, 1400.00),
    ('124', 'GABRIEL', 1, 1250.00),
    ('125', 'AILTON', 28, 830.00),   -- planilha: 31.03 → dia 28 (limite do sistema)
    ('126', 'JUAN LUCAS', 2, 830.00),
    ('127', 'DANILO', 10, 830.00),
    ('128', 'FERNADO', 16, 830.00),
    ('129', 'MARCELO PAIOL', NULL, NULL),
    ('130', 'SCARLAT', 16, 830.00),
    ('131', 'ROSA', 8, 830.00),
    ('132', 'ROBERTO', 10, 830.00),
    ('133', 'FLAVIANO', 2, 830.00),
    ('134', 'CLÁUDIO', 5, 830.00),
    ('QUARTINHO', 'FABRÍCIO', 5, 500.00);

  -- Locador(a) de todos os imóveis
  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT v_company_id, v_landlord_name, 'landlord'::rental_party_category, 'active'::entity_status
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_parties p
    WHERE p.company_id = v_company_id
      AND p.full_name = v_landlord_name
      AND p.category = 'landlord'::rental_party_category
  );

  SELECT id INTO v_landlord_id
  FROM rental_parties
  WHERE company_id = v_company_id
    AND full_name = v_landlord_name
    AND category = 'landlord'::rental_party_category
  LIMIT 1;

  IF v_landlord_id IS NULL THEN
    RAISE EXCEPTION 'Não foi possível cadastrar ou localizar o locador %.', v_landlord_name;
  END IF;

  -- Imóveis
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
    CASE
      WHEN r.apto ~ '^[0-9]+$' THEN 'Apto ' || r.apto
      ELSE r.apto
    END,
    r.apto,
    r.monthly_rent,
    'active'::entity_status
  FROM _itaparica_rows r
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_properties p
    WHERE p.company_id = v_company_id
      AND p.code = 'ITAP-' || r.apto
  );

  -- Garante locador nos imóveis já existentes (reexecução idempotente)
  UPDATE rental_properties p
  SET owner_party_id = v_landlord_id,
      updated_at = NOW()
  WHERE p.company_id = v_company_id
    AND p.code LIKE 'ITAP-%'
    AND p.condominium_id = v_condo_id
    AND (p.owner_party_id IS NULL OR p.owner_party_id IS DISTINCT FROM v_landlord_id);

  -- Inquilinos / locatários
  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT DISTINCT
    v_company_id,
    r.tenant_name,
    'tenant'::rental_party_category,
    'active'::entity_status
  FROM _itaparica_rows r
  WHERE r.tenant_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_parties p
      WHERE p.company_id = v_company_id
        AND p.full_name = r.tenant_name
        AND p.category = 'tenant'::rental_party_category
    );

  -- Reservas com aluguel fixo (jan–dez/2026)
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
    'Importado da planilha Praia de Itaparica (00037).'
  FROM _itaparica_rows r
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

  RAISE NOTICE 'Carga Praia de Itaparica concluída para empresa % e condomínio %.', v_company_id, v_condo_id;
END $$;

NOTIFY pgrst, 'reload schema';
