-- Fotos de imóveis (locação) + bucket de storage
-- Migration: 00034

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'rental-properties',
  'rental-properties',
  false,
  20971520,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS rental_property_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_property_photos_property
  ON rental_property_photos(property_id, sort_order);

ALTER TABLE rental_property_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_property_photos_select ON rental_property_photos;
CREATE POLICY rental_property_photos_select ON rental_property_photos FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_property_photos_modify ON rental_property_photos;
CREATE POLICY rental_property_photos_modify ON rental_property_photos FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS storage_rental_properties ON storage.objects;
CREATE POLICY storage_rental_properties ON storage.objects FOR ALL
  USING (
    bucket_id = 'rental-properties'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
      )
    )
  )
  WITH CHECK (
    bucket_id = 'rental-properties'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
      )
    )
  );
