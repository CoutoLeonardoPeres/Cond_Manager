-- Cond Manager - Módulos (Manutenção + Locação) e gestão de aluguéis
-- Migration: 00028

DO $$ BEGIN
  CREATE TYPE app_module AS ENUM ('maintenance', 'rental');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_property_type AS ENUM (
    'room',
    'house',
    'apartment',
    'studio',
    'loft',
    'building',
    'commercial_room',
    'office',
    'warehouse',
    'store',
    'chalet',
    'farm',
    'land',
    'parking_space',
    'hostel_bed',
    'hotel_room',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_listing_mode AS ENUM (
    'long_term',
    'short_term',
    'seasonal',
    'daily',
    'corporate',
    'vacation_rental'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_lease_status AS ENUM (
    'draft',
    'active',
    'expired',
    'terminated',
    'suspended'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_booking_status AS ENUM (
    'inquiry',
    'reserved',
    'confirmed',
    'checked_in',
    'checked_out',
    'cancelled',
    'no_show'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_charge_type AS ENUM (
    'rent',
    'deposit',
    'fee',
    'utility',
    'cleaning',
    'fine',
    'refund',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_charge_status AS ENUM (
    'pending',
    'paid',
    'overdue',
    'cancelled',
    'refunded'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_booking_channel AS ENUM (
    'direct',
    'airbnb',
    'booking_com',
    'expedia',
    'decolar',
    'whatsapp',
    'agency',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Módulos contratados por empresa gestora
CREATE TABLE IF NOT EXISTS company_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  module app_module NOT NULL,
  status entity_status NOT NULL DEFAULT 'active',
  enabled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(company_id, module)
);

CREATE INDEX IF NOT EXISTS idx_company_modules_company ON company_modules(company_id);

DROP TRIGGER IF EXISTS company_modules_updated_at ON company_modules;
CREATE TRIGGER company_modules_updated_at
  BEFORE UPDATE ON company_modules
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO company_modules (company_id, module, status)
SELECT id, 'maintenance', 'active'
FROM management_companies
ON CONFLICT (company_id, module) DO NOTHING;

CREATE OR REPLACE FUNCTION company_has_module(p_company_id UUID, p_module app_module)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM company_modules cm
      WHERE cm.company_id = p_company_id
        AND cm.module = p_module
        AND cm.status = 'active'
        AND (cm.expires_at IS NULL OR cm.expires_at > NOW())
    );
$$;

CREATE OR REPLACE FUNCTION user_has_module(p_module app_module)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR (
      get_user_company_id() IS NOT NULL
      AND company_has_module(get_user_company_id(), p_module)
    );
$$;

-- Partes (proprietários, inquilinos, hóspedes, fiadores)
CREATE TABLE IF NOT EXISTS rental_parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  document_type TEXT,
  document_number TEXT,
  address_street TEXT,
  address_number TEXT,
  address_complement TEXT,
  address_neighborhood TEXT,
  address_city TEXT,
  address_state TEXT,
  address_zip TEXT,
  notes TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_parties_company ON rental_parties(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_parties_email ON rental_parties(company_id, email);

CREATE TRIGGER rental_parties_updated_at
  BEFORE UPDATE ON rental_parties
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Imóveis / unidades locáveis
CREATE TABLE IF NOT EXISTS rental_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  condominium_id UUID REFERENCES condominiums(id) ON DELETE SET NULL,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  owner_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  property_type rental_property_type NOT NULL DEFAULT 'apartment',
  listing_mode rental_listing_mode NOT NULL DEFAULT 'long_term',
  code TEXT,
  title TEXT NOT NULL,
  description TEXT,
  address_street TEXT,
  address_number TEXT,
  address_complement TEXT,
  address_neighborhood TEXT,
  address_city TEXT,
  address_state TEXT,
  address_zip TEXT,
  address_country TEXT DEFAULT 'BR',
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  area_sqm NUMERIC(12, 2),
  bedrooms SMALLINT,
  bathrooms SMALLINT,
  parking_spots SMALLINT,
  max_guests SMALLINT,
  floors SMALLINT,
  base_rent_amount NUMERIC(14, 2),
  base_daily_rate NUMERIC(14, 2),
  deposit_amount NUMERIC(14, 2),
  cleaning_fee NUMERIC(14, 2),
  condominium_fee NUMERIC(14, 2),
  iptu_annual NUMERIC(14, 2),
  is_furnished BOOLEAN NOT NULL DEFAULT FALSE,
  allows_pets BOOLEAN NOT NULL DEFAULT FALSE,
  status entity_status NOT NULL DEFAULT 'active',
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_properties_company ON rental_properties(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_properties_type ON rental_properties(company_id, property_type);
CREATE INDEX IF NOT EXISTS idx_rental_properties_condo ON rental_properties(condominium_id);

CREATE TRIGGER rental_properties_updated_at
  BEFORE UPDATE ON rental_properties
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Subunidades (quartos, salas em prédio, etc.)
CREATE TABLE IF NOT EXISTS rental_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE CASCADE,
  unit_code TEXT,
  name TEXT NOT NULL,
  property_type rental_property_type,
  floor SMALLINT,
  area_sqm NUMERIC(12, 2),
  bedrooms SMALLINT,
  bathrooms SMALLINT,
  max_guests SMALLINT,
  base_monthly_rent NUMERIC(14, 2),
  base_daily_rate NUMERIC(14, 2),
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_units_property ON rental_units(property_id);

CREATE TRIGGER rental_units_updated_at
  BEFORE UPDATE ON rental_units
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Contratos de locação (longo prazo)
CREATE TABLE IF NOT EXISTS rental_leases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE RESTRICT,
  unit_id UUID REFERENCES rental_units(id) ON DELETE SET NULL,
  primary_tenant_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  lease_number TEXT,
  listing_mode rental_listing_mode NOT NULL DEFAULT 'long_term',
  status rental_lease_status NOT NULL DEFAULT 'draft',
  start_date DATE NOT NULL,
  end_date DATE,
  signed_at TIMESTAMPTZ,
  monthly_rent NUMERIC(14, 2) NOT NULL,
  deposit_amount NUMERIC(14, 2),
  due_day_of_month SMALLINT CHECK (due_day_of_month IS NULL OR due_day_of_month BETWEEN 1 AND 28),
  adjustment_index TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_leases_company ON rental_leases(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_leases_property ON rental_leases(property_id);

CREATE TRIGGER rental_leases_updated_at
  BEFORE UPDATE ON rental_leases
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS rental_lease_tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id UUID NOT NULL REFERENCES rental_leases(id) ON DELETE CASCADE,
  party_id UUID NOT NULL REFERENCES rental_parties(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(lease_id, party_id)
);

-- Reservas (curta temporada / hotel / Airbnb)
CREATE TABLE IF NOT EXISTS rental_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE RESTRICT,
  unit_id UUID REFERENCES rental_units(id) ON DELETE SET NULL,
  guest_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  booking_number TEXT,
  channel rental_booking_channel NOT NULL DEFAULT 'direct',
  status rental_booking_status NOT NULL DEFAULT 'inquiry',
  guest_name TEXT NOT NULL,
  guest_email TEXT,
  guest_phone TEXT,
  guests_count SMALLINT NOT NULL DEFAULT 1,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  nightly_rate NUMERIC(14, 2),
  total_amount NUMERIC(14, 2),
  paid_amount NUMERIC(14, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_bookings_dates_valid CHECK (check_out > check_in)
);

CREATE INDEX IF NOT EXISTS idx_rental_bookings_company ON rental_bookings(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_bookings_dates ON rental_bookings(check_in, check_out);

CREATE TRIGGER rental_bookings_updated_at
  BEFORE UPDATE ON rental_bookings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Cobranças / recebimentos
CREATE TABLE IF NOT EXISTS rental_charges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  lease_id UUID REFERENCES rental_leases(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES rental_bookings(id) ON DELETE SET NULL,
  party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  charge_type rental_charge_type NOT NULL DEFAULT 'rent',
  status rental_charge_status NOT NULL DEFAULT 'pending',
  description TEXT NOT NULL,
  amount NUMERIC(14, 2) NOT NULL,
  due_date DATE,
  paid_at TIMESTAMPTZ,
  reference_month DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_charges_source CHECK (lease_id IS NOT NULL OR booking_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_rental_charges_company ON rental_charges(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_charges_due ON rental_charges(due_date);

CREATE TRIGGER rental_charges_updated_at
  BEFORE UPDATE ON rental_charges
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE company_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_lease_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_charges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS company_modules_select ON company_modules;
CREATE POLICY company_modules_select ON company_modules FOR SELECT
  USING (is_platform_admin() OR has_company_access(company_id));

DROP POLICY IF EXISTS company_modules_modify ON company_modules;
CREATE POLICY company_modules_modify ON company_modules FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

DROP POLICY IF EXISTS rental_company_select ON rental_parties;
CREATE POLICY rental_parties_select ON rental_parties FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_parties_modify ON rental_parties;
CREATE POLICY rental_parties_modify ON rental_parties FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_properties_select ON rental_properties;
CREATE POLICY rental_properties_select ON rental_properties FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_properties_modify ON rental_properties;
CREATE POLICY rental_properties_modify ON rental_properties FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_units_select ON rental_units;
CREATE POLICY rental_units_select ON rental_units FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_units_modify ON rental_units;
CREATE POLICY rental_units_modify ON rental_units FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_leases_select ON rental_leases;
CREATE POLICY rental_leases_select ON rental_leases FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_leases_modify ON rental_leases;
CREATE POLICY rental_leases_modify ON rental_leases FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_lease_tenants_select ON rental_lease_tenants;
CREATE POLICY rental_lease_tenants_select ON rental_lease_tenants FOR SELECT
  USING (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND has_company_access(l.company_id)
        AND user_has_module('rental')
    )
  );

DROP POLICY IF EXISTS rental_lease_tenants_modify ON rental_lease_tenants;
CREATE POLICY rental_lease_tenants_modify ON rental_lease_tenants FOR ALL
  USING (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND can_manage_company_users(l.company_id)
        AND user_has_module('rental')
    )
  )
  WITH CHECK (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND can_manage_company_users(l.company_id)
        AND user_has_module('rental')
    )
  );

DROP POLICY IF EXISTS rental_bookings_select ON rental_bookings;
CREATE POLICY rental_bookings_select ON rental_bookings FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_bookings_modify ON rental_bookings;
CREATE POLICY rental_bookings_modify ON rental_bookings FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_charges_select ON rental_charges;
CREATE POLICY rental_charges_select ON rental_charges FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_charges_modify ON rental_charges;
CREATE POLICY rental_charges_modify ON rental_charges FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

NOTIFY pgrst, 'reload schema';
