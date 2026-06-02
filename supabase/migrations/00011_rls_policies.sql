-- Cond Manager - Row Level Security Policies
-- Migration: 00011

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_condominium_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE condominiums ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE towers ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY profiles_select ON profiles FOR SELECT
  USING (id = auth.uid() OR is_platform_admin());

CREATE POLICY profiles_update ON profiles FOR UPDATE
  USING (id = auth.uid() OR is_platform_admin());

-- USER CONDOMINIUM ROLES
CREATE POLICY ucr_select ON user_condominium_roles FOR SELECT
  USING (user_id = auth.uid() OR has_condominium_access(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_insert ON user_condominium_roles FOR INSERT
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_update ON user_condominium_roles FOR UPDATE
  USING (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_delete ON user_condominium_roles FOR DELETE
  USING (can_manage_condominium(condominium_id) OR is_platform_admin());

-- INVITATIONS
CREATE POLICY invitations_select ON user_invitations FOR SELECT
  USING (has_condominium_access(condominium_id) OR is_platform_admin());

CREATE POLICY invitations_insert ON user_invitations FOR INSERT
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- CONDOMINIUMS
CREATE POLICY condominiums_select ON condominiums FOR SELECT
  USING (has_condominium_access(id) OR is_platform_admin());

CREATE POLICY condominiums_insert ON condominiums FOR INSERT
  WITH CHECK (is_platform_admin());

CREATE POLICY condominiums_update ON condominiums FOR UPDATE
  USING (can_manage_condominium(id) OR is_platform_admin());

CREATE POLICY condominiums_delete ON condominiums FOR DELETE
  USING (is_platform_admin());

-- STRUCTURE TABLES (blocks, towers, units, common_areas, equipment)
CREATE POLICY blocks_all ON blocks FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY towers_all ON towers FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY units_select ON units FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY units_modify ON units FOR ALL
  USING (can_manage_condominium(condominium_id) OR is_platform_admin())
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY common_areas_all ON common_areas FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY equipment_all ON equipment FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- PROVIDERS
CREATE POLICY providers_select ON providers FOR SELECT
  USING (
    is_platform_admin()
    OR (condominium_id IS NOT NULL AND has_condominium_access(condominium_id))
    OR user_id = auth.uid()
  );

CREATE POLICY providers_modify ON providers FOR ALL
  USING (can_manage_condominium(condominium_id) OR is_platform_admin())
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY provider_docs_select ON provider_documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM providers p
      WHERE p.id = provider_id
        AND (has_condominium_access(p.condominium_id) OR p.user_id = auth.uid())
    )
  );

CREATE POLICY provider_docs_modify ON provider_documents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM providers p
      WHERE p.id = provider_id
        AND (can_manage_condominium(p.condominium_id) OR is_platform_admin())
    )
  );

-- MATERIALS
CREATE POLICY materials_select ON materials FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY materials_modify ON materials FOR ALL
  USING (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker', 'internal_employee'
    ) OR is_platform_admin()
  )
  WITH CHECK (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker'
    ) OR is_platform_admin()
  );

CREATE POLICY stock_movements_all ON stock_movements FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker', 'internal_employee'
    ) OR is_platform_admin()
  );

CREATE POLICY material_categories_all ON material_categories FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- TICKETS
CREATE POLICY tickets_select ON tickets FOR SELECT
  USING (
    has_condominium_access(condominium_id)
    AND (
      requester_id = auth.uid()
      OR assigned_to = auth.uid()
      OR get_user_role(condominium_id) NOT IN ('resident')
      OR is_platform_admin()
    )
  );

CREATE POLICY tickets_insert ON tickets FOR INSERT
  WITH CHECK (
    has_condominium_access(condominium_id)
    AND requester_id = auth.uid()
  );

CREATE POLICY tickets_update ON tickets FOR UPDATE
  USING (
    has_condominium_access(condominium_id)
    AND (
      requester_id = auth.uid()
      OR can_manage_condominium(condominium_id)
      OR assigned_to = auth.uid()
      OR is_platform_admin()
    )
  );

CREATE POLICY ticket_attachments_all ON ticket_attachments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY ticket_interactions_select ON ticket_interactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id
        AND has_condominium_access(t.condominium_id)
        AND (NOT is_internal OR can_manage_condominium(t.condominium_id))
    )
  );

CREATE POLICY ticket_interactions_insert ON ticket_interactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
    AND author_id = auth.uid()
  );

-- WORK ORDERS
CREATE POLICY work_orders_select ON work_orders FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY work_orders_insert ON work_orders FOR INSERT
  WITH CHECK (
    can_manage_condominium(condominium_id)
    OR get_user_role(condominium_id) IN ('maintenance_manager', 'caretaker', 'internal_employee')
    OR is_platform_admin()
  );

CREATE POLICY work_orders_update ON work_orders FOR UPDATE
  USING (
    has_condominium_access(condominium_id)
    AND (
      can_manage_condominium(condominium_id)
      OR internal_responsible_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM providers p
        WHERE p.id = provider_id AND p.user_id = auth.uid()
      )
      OR is_platform_admin()
    )
  );

CREATE POLICY wo_history_select ON work_order_status_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_materials_all ON work_order_materials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_labor_all ON work_order_labor FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_attachments_all ON work_order_attachments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_approvals_select ON work_order_approvals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_approvals_update ON work_order_approvals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND can_approve_work_orders(wo.condominium_id)
    )
  );

-- PREVENTIVE
CREATE POLICY preventive_plans_all ON preventive_plans FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY preventive_checklist_all ON preventive_checklist_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  );

CREATE POLICY preventive_executions_all ON preventive_executions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  );

-- NOTIFICATIONS
CREATE POLICY notifications_own ON notifications FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- FINANCIAL
CREATE POLICY financial_select ON financial_records FOR SELECT
  USING (can_view_financial(condominium_id));

CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    get_user_role(condominium_id) IN ('condominium_admin', 'financial')
    OR is_platform_admin()
  )
  WITH CHECK (
    get_user_role(condominium_id) IN ('condominium_admin', 'financial')
    OR is_platform_admin()
  );

-- STORAGE POLICIES
CREATE POLICY storage_avatars ON storage.objects FOR ALL
  USING (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY storage_condominium ON storage.objects FOR ALL
  USING (
    bucket_id = 'condominium-assets'
    AND has_condominium_access((storage.foldername(name))[1]::UUID)
  );

CREATE POLICY storage_tickets ON storage.objects FOR ALL
  USING (
    bucket_id = 'tickets'
    AND EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = (storage.foldername(name))[2]::UUID
        AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY storage_work_orders ON storage.objects FOR ALL
  USING (
    bucket_id = 'work-orders'
    AND EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = (storage.foldername(name))[2]::UUID
        AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY storage_provider_docs ON storage.objects FOR ALL
  USING (bucket_id = 'provider-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY storage_signatures ON storage.objects FOR ALL
  USING (bucket_id = 'signatures' AND auth.uid() IS NOT NULL);

-- Realtime (habilitar nas tabelas críticas via dashboard ou):
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE work_orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE work_order_approvals;
