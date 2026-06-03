-- Cond Manager - Mão de obra detalhada na OS (HH, profissionais, deslocamento)
-- Migration: 00016

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
  ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

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

CREATE OR REPLACE FUNCTION work_order_labor_compute_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.total_cost := (NEW.worker_count * NEW.hours * NEW.hourly_rate) + NEW.travel_cost;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS work_order_labor_compute_total_trg ON work_order_labor;
CREATE TRIGGER work_order_labor_compute_total_trg
  BEFORE INSERT OR UPDATE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION work_order_labor_compute_total();

CREATE OR REPLACE FUNCTION refresh_work_order_labor_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  wo_id UUID;
  labor_sum NUMERIC(14, 2);
  travel_sum NUMERIC(14, 2);
  material_sum NUMERIC(14, 2);
BEGIN
  wo_id := COALESCE(NEW.work_order_id, OLD.work_order_id);

  SELECT COALESCE(SUM(worker_count * hours * hourly_rate), 0),
         COALESCE(SUM(travel_cost), 0)
    INTO labor_sum, travel_sum
    FROM work_order_labor
   WHERE work_order_id = wo_id;

  SELECT COALESCE(material_cost, 0) INTO material_sum
    FROM work_orders WHERE id = wo_id;

  UPDATE work_orders
     SET labor_cost = labor_sum,
         travel_cost = travel_sum,
         actual_cost = material_sum + labor_sum + travel_sum
   WHERE id = wo_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_ins ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_ins
  AFTER INSERT ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_upd ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_upd
  AFTER UPDATE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_del ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_del
  AFTER DELETE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

-- Recalcular linhas existentes
UPDATE work_order_labor
   SET total_cost = (worker_count * hours * hourly_rate) + travel_cost;
