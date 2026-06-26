import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';

extension UserManagementPermissions on AppPermissions {
  /// Papéis que o usuário atual pode atribuir ao convidar ou editar.
  List<OrganizationRole> get assignableOrganizationRoles {
    if (isAdmin) return OrganizationRole.values;
    if (isManager) {
      return OrganizationRole.values
          .where((r) => r != OrganizationRole.manager)
          .toList();
    }
    return const [];
  }

  bool canAssignOrganizationRole(OrganizationRole role) {
    return assignableOrganizationRoles.contains(role);
  }

  /// Admin gerencia todos; gerente não gerencia admin nem outros gerentes.
  bool canManageOrganizationUser(OrganizationUser user) {
    if (!canManageUsers) return false;
    if (isAdmin) return true;
    if (user.isPlatformAdmin) return false;
    if (user.organizationRole == OrganizationRole.manager) return false;
    return true;
  }
}
