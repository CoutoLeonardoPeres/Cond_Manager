-- Despesas de condomínio no módulo locação (financial_records estendido)
-- Migration: 00050

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS rental_expense_entry_type TEXT
    CHECK (rental_expense_entry_type IS NULL OR rental_expense_entry_type IN ('fixed_bill', 'service', 'material')),
  ADD COLUMN IF NOT EXISTS condominium_bill_type TEXT,
  ADD COLUMN IF NOT EXISTS expense_service_type TEXT,
  ADD COLUMN IF NOT EXISTS material_category_id UUID REFERENCES material_categories(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_recurring_template BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS recurrence_template_id UUID REFERENCES financial_records(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS recurrence_day_of_month INT
    CHECK (recurrence_day_of_month IS NULL OR (recurrence_day_of_month >= 1 AND recurrence_day_of_month <= 28)),
  ADD COLUMN IF NOT EXISTS recurrence_active BOOLEAN NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_financial_unit ON financial_records(unit_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_expense_entry ON financial_records(rental_expense_entry_type)
  WHERE rental_expense_entry_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_financial_recurring_template ON financial_records(is_recurring_template)
  WHERE is_recurring_template = true;
CREATE INDEX IF NOT EXISTS idx_financial_recurrence_template ON financial_records(recurrence_template_id);

COMMENT ON COLUMN financial_records.rental_expense_entry_type IS
  'Origem módulo locação: conta fixa, serviço técnico ou material';
COMMENT ON COLUMN financial_records.condominium_bill_type IS
  'Tipo de conta fixa (água, energia, internet, etc.)';
COMMENT ON COLUMN financial_records.is_recurring_template IS
  'Modelo mensal reutilizável; gera lançamentos via recurrence_template_id';

-- Gestores da empresa com módulo locação podem lançar despesas do condomínio
DROP POLICY IF EXISTS financial_modify ON financial_records;
CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      ))
    OR (scope = 'management_company' AND can_manage_management_financial())
  )
  WITH CHECK (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      ))
    OR (scope = 'management_company' AND can_manage_management_financial())
  );

NOTIFY pgrst, 'reload schema';
