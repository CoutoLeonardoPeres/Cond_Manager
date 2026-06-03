import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';

extension FinancialPermissions on UserProfile {
  bool canViewFinancialIn(String condominiumId) {
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canManageInCondominium(condominiumId);
    }
    if (isPlatformAdmin) return true;
    return roleInCondominium(condominiumId)?.canViewFinancial ?? false;
  }

  bool canManageFinancialIn(String condominiumId) {
    if (permissions.isClient || permissions.isFieldTeam) return false;
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canManageInCondominium(condominiumId);
    }
    if (isPlatformAdmin) return true;
    final role = roleInCondominium(condominiumId);
    return role == UserRole.condominiumAdmin || role == UserRole.financial;
  }

  bool canDeleteFinancialIn(String condominiumId) {
    return permissions.canDeleteRecordsInCondominium(condominiumId) &&
        canManageFinancialIn(condominiumId);
  }

  bool get canViewManagementFinancial {
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canCreate;
    }
    if (isPlatformAdmin) return true;
    return condominiumRoles
        .where((r) => r.status == 'active')
        .any((r) => r.role.canViewFinancial);
  }

  bool get canManageManagementFinancial {
    if (permissions.isClient || permissions.isFieldTeam) return false;
    if (permissions.isAdmin || permissions.isManager || permissions.isAnalyst) {
      return permissions.canCreate;
    }
    if (isPlatformAdmin) return true;
    return condominiumRoles
        .where((r) => r.status == 'active')
        .any((r) => r.role == UserRole.condominiumAdmin || r.role == UserRole.financial);
  }
}
