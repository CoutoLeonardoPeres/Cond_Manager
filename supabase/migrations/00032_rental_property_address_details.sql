-- Detalhes de endereço para imóveis (edifício, bloco/torre, apartamento)
-- Migration: 00032

ALTER TABLE rental_properties
  ADD COLUMN IF NOT EXISTS address_building TEXT,
  ADD COLUMN IF NOT EXISTS address_block TEXT,
  ADD COLUMN IF NOT EXISTS address_apartment TEXT;
