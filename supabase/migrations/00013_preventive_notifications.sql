-- Permite gestores criarem alertas de preventiva para responsáveis do condomínio
CREATE POLICY notifications_insert_management ON notifications FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR (
      condominium_id IS NOT NULL
      AND (can_manage_condominium(condominium_id) OR is_platform_admin())
    )
  );

-- WITH CHECK em checklist e execuções (insert/update)
CREATE POLICY preventive_checklist_modify ON preventive_checklist_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id
        AND (can_manage_condominium(pp.condominium_id) OR is_platform_admin())
    )
  );

CREATE POLICY preventive_executions_modify ON preventive_executions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id
        AND (can_manage_condominium(pp.condominium_id) OR is_platform_admin())
    )
  );
