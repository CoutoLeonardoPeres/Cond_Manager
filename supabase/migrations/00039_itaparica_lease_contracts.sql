-- Contratos de locação (longo prazo) para inquilinos da planilha Praia de Itaparica
-- Migration: 00039
--
-- Cria rental_leases jan–dez/2026 para cada imóvel ITAP-* com inquilino, aluguel e dia de vencimento.
-- Idempotente: não duplica contrato ativo no mesmo período para o mesmo imóvel.

DO $$
DECLARE
  v_company_id UUID;
  v_condo_id UUID;
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

  CREATE TEMP TABLE _lease_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT NOT NULL,
    due_day SMALLINT NOT NULL,
    monthly_rent NUMERIC(14, 2) NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO _lease_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
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
    ('125', 'AILTON', 28, 830.00),
    ('126', 'JUAN LUCAS', 2, 830.00),
    ('127', 'DANILO', 10, 830.00),
    ('128', 'FERNADO', 16, 830.00),
    ('130', 'SCARLAT', 16, 830.00),
    ('131', 'ROSA', 8, 830.00),
    ('132', 'ROBERTO', 10, 830.00),
    ('133', 'FLAVIANO', 2, 830.00),
    ('134', 'CLÁUDIO', 5, 830.00),
    ('QUARTINHO', 'FABRÍCIO', 5, 500.00);

  WITH inserted_leases AS (
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
      v_company_id,
      p.id,
      party.id,
      'ITAP-' || r.apto || '-2026',
      'long_term'::rental_listing_mode,
      'active'::rental_lease_status,
      DATE '2026-01-01',
      DATE '2026-12-31',
      r.monthly_rent,
      r.due_day,
      'Contrato importado da planilha Praia de Itaparica (00039).'
    FROM _lease_rows r
    JOIN rental_properties p
      ON p.company_id = v_company_id
     AND p.condominium_id = v_condo_id
     AND p.code = 'ITAP-' || r.apto
    JOIN rental_parties party
      ON party.company_id = v_company_id
     AND party.category = 'tenant'::rental_party_category
     AND (
       upper(trim(party.full_name)) = upper(trim(r.tenant_name))
       OR party.id IN (
         SELECT b.guest_party_id
         FROM rental_bookings b
         WHERE b.property_id = p.id
           AND b.check_in = DATE '2026-01-01'
           AND b.status <> 'cancelled'::rental_booking_status
           AND b.guest_party_id IS NOT NULL
       )
     )
    WHERE NOT EXISTS (
      SELECT 1
      FROM rental_leases l
      WHERE l.property_id = p.id
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

  RAISE NOTICE 'Contratos Praia de Itaparica criados (empresa %, condomínio %).', v_company_id, v_condo_id;
END $$;

NOTIFY pgrst, 'reload schema';
