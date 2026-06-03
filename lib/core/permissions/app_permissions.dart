import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';

/// Papéis efetivos do usuário no app.
enum AppAccessTier {
  platformAdmin,
  manager,
  analyst,
  fieldTeam,
  client,
  legacyStaff,
}

class AppPermissions {
  const AppPermissions(this.profile);

  final UserProfile? profile;

  AppAccessTier get tier {
    if (profile == null) return AppAccessTier.client;
    if (profile!.isPlatformAdmin) return AppAccessTier.platformAdmin;
    final org = profile!.primaryOrganizationRole;
    if (org != null) {
      return switch (org) {
        OrganizationRole.manager => AppAccessTier.manager,
        OrganizationRole.analyst => AppAccessTier.analyst,
        OrganizationRole.fieldTeam => AppAccessTier.fieldTeam,
        OrganizationRole.client => AppAccessTier.client,
      };
    }
    if (profile!.condominiumRoles.any((r) => r.role == UserRole.resident)) {
      return AppAccessTier.client;
    }
    return AppAccessTier.legacyStaff;
  }

  bool get isAdmin => tier == AppAccessTier.platformAdmin;

  bool get isManager => tier == AppAccessTier.manager || isAdmin;

  bool get isAnalyst => tier == AppAccessTier.analyst;

  bool get isFieldTeam => tier == AppAccessTier.fieldTeam;

  bool get isClient => tier == AppAccessTier.client;

  bool get canDelete => isAdmin || isManager;

  bool get canEdit =>
      isAdmin || isManager || isAnalyst || tier == AppAccessTier.legacyStaff;

  bool get canCreate =>
      isAdmin ||
      isManager ||
      isAnalyst ||
      isFieldTeam ||
      tier == AppAccessTier.legacyStaff;

  bool get canManageUsers => isAdmin || isManager;

  bool get canManageCondominiumsGlobal => isAdmin;

  bool canEditCondominium(String condominiumId) {
    if (isAdmin) return true;
    if (isManager) return profile!.hasCompanyAccessToCondominium(condominiumId);
    return false;
  }

  bool get canAccessUsersModule => canManageUsers;

  bool canDeleteRecordsInCondominium(String condominiumId) {
    if (!canDelete) return false;
    if (isAdmin) return true;
    if (isManager) return profile!.hasCompanyAccessToCondominium(condominiumId);
    if (tier == AppAccessTier.legacyStaff) {
      return profile!.roleInCondominium(condominiumId)?.canManageCondominium ?? false;
    }
    return false;
  }

  bool canAccessRoute(String path) {
    if (isAdmin || isManager || isAnalyst || tier == AppAccessTier.legacyStaff) {
      if (path.startsWith('/users') && !canManageUsers) return false;
      if (path.startsWith('/condominiums/new') && !canManageCondominiumsGlobal) {
        return isManager;
      }
      return true;
    }
    if (isFieldTeam) {
      return path == '/' ||
          path.startsWith('/tickets') ||
          path.startsWith('/work-orders');
    }
    if (isClient) {
      return path == '/' || path.startsWith('/tickets');
    }
    return false;
  }

  List<String> get allowedNavPaths {
    if (isAdmin || isManager || isAnalyst || tier == AppAccessTier.legacyStaff) {
      final paths = [
        '/',
        '/condominiums',
        '/tickets',
        '/work-orders',
        '/providers',
        '/materials',
        '/preventive',
        '/financial',
      ];
      if (canManageUsers) paths.add('/users');
      return paths;
    }
    if (isFieldTeam) return ['/', '/tickets', '/work-orders'];
    if (isClient) return ['/', '/tickets'];
    return ['/'];
  }

  String get homeRoute {
    if (isClient || isFieldTeam) return '/tickets';
    return '/';
  }

  bool canManageInCondominium(String condominiumId) {
    if (isAdmin || isManager) return true;
    if (isAnalyst) return profile!.hasCompanyAccessToCondominium(condominiumId);
    if (isFieldTeam) return profile!.hasCompanyAccessToCondominium(condominiumId);
    if (tier == AppAccessTier.legacyStaff) {
      return profile!.roleInCondominium(condominiumId)?.canManageCondominium ?? false;
    }
    return false;
  }

  bool canViewCondominium(String condominiumId) {
    if (isAdmin || isManager || isAnalyst || isFieldTeam) {
      return profile!.hasCompanyAccessToCondominium(condominiumId) ||
          profile!.roleInCondominium(condominiumId) != null;
    }
    if (isClient) {
      return profile!.roleInCondominium(condominiumId) != null;
    }
    return profile!.roleInCondominium(condominiumId) != null;
  }
}

extension AppPermissionsX on UserProfile? {
  AppPermissions get permissions => AppPermissions(this);
}
