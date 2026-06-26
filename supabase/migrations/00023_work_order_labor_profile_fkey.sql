-- Garante colunas estendidas de mão de obra na OS (caso 00016 não tenha sido aplicada)
-- Migration: 00023

DO $$ BEGIN
  CREATE TYPE labor_source AS ENUM ('third_party', 'internal_team');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE work_order_labor
  ADD COLUMN IF NOT EXISTS labor_source labor_source NOT NULL DEFAULT 'third_party',
  ADD COLUMN IF NOT EXISTS service_type service_type NOT NULL DEFAULT 'other',
  ADD COLUMN IF NOT EXISTS worker_count INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS travel_cost NUMERIC(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_id UUID;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_profile_id_fkey
    FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_worker_count_positive CHECK (worker_count >= 1);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_travel_nonneg CHECK (travel_cost >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON COLUMN work_order_labor.profile_id IS
  'Funcionário interno vinculado (equipe própria); worker_name permanece como rótulo exibido';
