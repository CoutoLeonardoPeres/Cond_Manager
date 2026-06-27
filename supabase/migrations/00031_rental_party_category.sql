-- Categoria de pessoas no módulo Locação (locador, locatário, inquilino, hóspede)
-- Migration: 00031

DO $$ BEGIN
  CREATE TYPE rental_party_category AS ENUM (
    'landlord',
    'tenant',
    'occupant',
    'guest'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS category rental_party_category NOT NULL DEFAULT 'tenant';

CREATE INDEX IF NOT EXISTS idx_rental_parties_category
  ON rental_parties(company_id, category);
