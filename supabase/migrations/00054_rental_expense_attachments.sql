-- Anexos (NF / recibo) das despesas de locação
-- Migration: 00054

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'rental-expense-receipts',
  'rental-expense-receipts',
  false,
  20971520,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/pdf'
  ]
)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS rental_expense_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  financial_record_id UUID NOT NULL REFERENCES financial_records(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_expense_attachments_record
  ON rental_expense_attachments(financial_record_id, created_at);

ALTER TABLE rental_expense_attachments ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION can_view_rental_expense_attachment(p_financial_record_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM financial_records fr
    WHERE fr.id = p_financial_record_id
      AND fr.rental_expense_entry_type IS NOT NULL
      AND (
        (
          fr.scope = 'condominium'
          AND fr.condominium_id IS NOT NULL
          AND can_view_financial(fr.condominium_id)
        )
        OR (
          fr.scope = 'management_company'
          AND fr.management_company_id IS NOT NULL
          AND can_view_management_financial(fr.management_company_id)
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION can_modify_rental_expense_attachment(p_financial_record_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM financial_records fr
    WHERE fr.id = p_financial_record_id
      AND fr.rental_expense_entry_type IS NOT NULL
      AND (
        (
          fr.scope = 'condominium'
          AND fr.condominium_id IS NOT NULL
          AND (
            get_user_role(fr.condominium_id) IN ('condominium_admin', 'financial')
            OR (
              user_has_module('rental')
              AND EXISTS (
                SELECT 1 FROM condominiums c
                WHERE c.id = fr.condominium_id
                  AND c.management_company_id IS NOT NULL
                  AND c.management_company_id = get_user_company_id()
                  AND is_company_manager(c.management_company_id)
              )
            )
          )
        )
        OR (
          fr.scope = 'management_company'
          AND fr.management_company_id IS NOT NULL
          AND can_manage_management_financial(fr.management_company_id)
          AND (is_platform_admin() OR fr.management_company_id = get_user_company_id())
        )
      )
  );
$$;

DROP POLICY IF EXISTS rental_expense_attachments_select ON rental_expense_attachments;
CREATE POLICY rental_expense_attachments_select ON rental_expense_attachments FOR SELECT
  USING (can_view_rental_expense_attachment(financial_record_id));

DROP POLICY IF EXISTS rental_expense_attachments_modify ON rental_expense_attachments;
CREATE POLICY rental_expense_attachments_modify ON rental_expense_attachments FOR ALL
  USING (can_modify_rental_expense_attachment(financial_record_id))
  WITH CHECK (
    can_modify_rental_expense_attachment(financial_record_id)
    AND company_id = get_user_company_id()
  );

DROP POLICY IF EXISTS storage_rental_expense_receipts ON storage.objects;
CREATE POLICY storage_rental_expense_receipts ON storage.objects FOR ALL
  USING (
    bucket_id = 'rental-expense-receipts'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
        AND can_view_rental_expense_attachment((storage.foldername(name))[2]::UUID)
      )
    )
  )
  WITH CHECK (
    bucket_id = 'rental-expense-receipts'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
        AND can_modify_rental_expense_attachment((storage.foldername(name))[2]::UUID)
        AND (storage.foldername(name))[1]::UUID = get_user_company_id()
      )
    )
  );

NOTIFY pgrst, 'reload schema';
