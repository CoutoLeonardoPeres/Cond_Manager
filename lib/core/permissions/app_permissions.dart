import 'package:cond_manager/core/modules/company_module_access.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
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

  CompanyModuleAccess get moduleAccess => CompanyModuleAccess(profile);

  bool hasModule(AppModule module) => moduleAccess.hasModule(module);

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

  bool get isOrganizationManager => tier == AppAccessTier.manager;

  bool get canViewAccessLogs => isAdmin || isOrganizationManager;

  bool get canManageCondominiumsGlobal => isAdmin;

  bool get canManageCompanyModules => isAdmin;

  bool get canCreateCondominium => isAdmin || isManager;

  bool get hasMaintenanceAndRental =>
      hasModule(AppModule.maintenance) && hasModule(AppModule.rental);

  bool get canManageRental =>
      hasModule(AppModule.rental) && (isAdmin || isManager || isAnalyst);

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
    if (path.startsWith('/admin')) {
      return isAdmin;
    }
    if (path.startsWith('/rental')) {
      return _canAccessRentalRoute(path);
    }
    if (!hasModule(AppModule.maintenance)) return false;
    return _canAccessMaintenanceRoute(path);
  }

  bool _canAccessMaintenanceRoute(String path) {
    if (isAdmin || isManager || isAnalyst || tier == AppAccessTier.legacyStaff) {
      if (path.startsWith('/users') && !canManageUsers) return false;
      if (path.startsWith('/access-logs') && !canViewAccessLogs) return false;
      if (path.startsWith('/condominiums/new') && !canCreateCondominium) return false;
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

  bool _canAccessRentalRoute(String path) {
    if (!hasModule(AppModule.rental)) return false;
    if (path.startsWith('/rental/condominiums/new') && !canCreateCondominium) return false;
    if (path.startsWith('/rental/reports') && !canManageRental) return false;
    if (isAdmin || isManager || isAnalyst) return true;
    if (isFieldTeam) {
      return path == '/rental' ||
          path.startsWith('/rental/bookings') ||
          path.startsWith('/rental/properties');
    }
    return false;
  }

  List<String> allowedNavPathsForModule(AppModule module) {
    return switch (module) {
      AppModule.maintenance => _maintenanceNavPaths,
      AppModule.rental => _rentalNavPaths,
    };
  }

  List<String> get _maintenanceNavPaths {
    if (!hasModule(AppModule.maintenance)) return const [];
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
      if (canViewAccessLogs) paths.add('/access-logs');
      if (canManageCompanyModules) paths.add('/admin/modules');
      return paths;
    }
    if (isFieldTeam) return ['/', '/tickets', '/work-orders'];
    if (isClient) return ['/', '/tickets'];
    return ['/'];
  }

  List<String> get _rentalNavPaths {
    if (!hasModule(AppModule.rental)) return const [];
    if (isAdmin || isManager || isAnalyst) {
      return [
        '/rental',
        '/rental/condominiums',
        '/rental/properties',
        '/rental/leases',
        '/rental/bookings',
        '/rental/calendar',
        '/rental/parties',
        '/rental/charges',
        '/rental/expenses',
        '/rental/reports',
      ];
    }
    if (isFieldTeam) {
      return ['/rental', '/rental/properties', '/rental/bookings'];
    }
    return const [];
  }

  String homeRouteForModule(AppModule module) {
    if (module == AppModule.rental) return '/rental';
    if (isClient || isFieldTeam) return '/tickets';
    return '/';
  }

  String get homeRoute => homeRouteForModule(moduleAccess.defaultModule);

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
