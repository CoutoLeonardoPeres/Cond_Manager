import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';

extension MaterialPermissions on UserProfile {
  bool canManageMaterialsIn(String condominiumId) {
    if (permissions.isClient || permissions.isFieldTeam) return false;
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canManageInCondominium(condominiumId);
    }
    if (isPlatformAdmin) return true;
    return roleInCondominium(condominiumId)?.canManageCondominium ?? false;
  }

  bool canDeleteMaterialsIn(String condominiumId) {
    return permissions.canDeleteRecordsInCondominium(condominiumId);
  }

  bool get canCreateMaterial {
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canCreate;
    }
    if (isPlatformAdmin) return true;
    return condominiumRoles
        .where((r) => r.status == 'active')
        .any((r) => r.role.canManageCondominium);
  }
}
