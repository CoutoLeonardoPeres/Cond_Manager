import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';

extension TicketPermissions on UserProfile {
  bool canManageTicketIn(String condominiumId) {
    if (permissions.isAdmin || permissions.isManager) return true;
    if (permissions.isAnalyst) {
      return permissions.canEdit && hasCompanyAccessToCondominium(condominiumId);
    }
    if (permissions.isFieldTeam || permissions.isClient) {
      return hasCompanyAccessToCondominium(condominiumId) ||
          roleInCondominium(condominiumId) != null;
    }
    final role = roleInCondominium(condominiumId);
    return role?.canManageCondominium ?? false;
  }

  bool canCreateTicketIn(String condominiumId) {
    if (permissions.isClient) {
      return roleInCondominium(condominiumId) != null;
    }
    return canManageTicketIn(condominiumId) || permissions.canCreate;
  }
}
