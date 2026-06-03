import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';

extension WorkOrderPermissions on UserProfile {
  bool get canCreateWorkOrdersAnywhere {
    if (permissions.isClient || permissions.isFieldTeam) return false;
    if (permissions.canCreate && (permissions.isAdmin || permissions.isManager || permissions.isAnalyst)) {
      return true;
    }
    if (isPlatformAdmin) return true;
    return condominiumRoles.any((r) {
      if (r.status != 'active') return false;
      return switch (r.role) {
        UserRole.condominiumAdmin ||
        UserRole.syndic ||
        UserRole.maintenanceManager ||
        UserRole.caretaker ||
        UserRole.internalEmployee =>
          true,
        _ => false,
      };
    });
  }

  bool canManageWorkOrderIn(String condominiumId) {
    if (permissions.isAdmin || permissions.isManager) return true;
    if (permissions.isAnalyst) {
      return permissions.canEdit && hasCompanyAccessToCondominium(condominiumId);
    }
    if (permissions.isFieldTeam) {
      return hasCompanyAccessToCondominium(condominiumId);
    }
    if (isPlatformAdmin) return true;
    final role = roleInCondominium(condominiumId);
    return role?.canManageCondominium ?? false;
  }
}
