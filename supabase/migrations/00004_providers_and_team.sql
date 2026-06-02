-- Cond Manager - Providers, Suppliers and Internal Team
-- Migration: 00004

CREATE TABLE providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID REFERENCES condominiums(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  provider_type provider_type NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('cpf', 'cnpj')),
  document_number TEXT NOT NULL,
  legal_name TEXT NOT NULL,
  trade_name TEXT,
  specialties service_type[] NOT NULL DEFAULT '{}',
  phones TEXT[] NOT NULL DEFAULT '{}',
  emails TEXT[] NOT NULL DEFAULT '{}',
  street TEXT,
  number TEXT,
  complement TEXT,
  neighborhood TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  rating NUMERIC(3, 2) CHECK (rating >= 0 AND rating <= 5),
  rating_count INT NOT NULL DEFAULT 0,
  status entity_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_providers_condominium ON providers(condominium_id);
CREATE INDEX idx_providers_type ON providers(provider_type);
CREATE INDEX idx_providers_status ON providers(status);
CREATE INDEX idx_providers_document ON providers(document_number);

CREATE TABLE provider_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  document_type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  valid_from DATE,
  valid_until DATE,
  is_valid BOOLEAN NOT NULL DEFAULT TRUE,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_provider_docs_provider ON provider_documents(provider_id);
CREATE INDEX idx_provider_docs_valid_until ON provider_documents(valid_until);

CREATE TABLE provider_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  contract_number TEXT,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  value NUMERIC(14, 2),
  file_url TEXT,
  file_path TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE provider_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  work_order_id UUID, -- FK added later
  evaluator_id UUID NOT NULL REFERENCES profiles(id),
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER providers_updated_at
  BEFORE UPDATE ON providers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER provider_documents_updated_at
  BEFORE UPDATE ON provider_documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER provider_contracts_updated_at
  BEFORE UPDATE ON provider_contracts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
