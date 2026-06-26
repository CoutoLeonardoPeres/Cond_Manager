import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';

/// Controle de módulos contratados (Manutenção / Locação).
class CompanyModuleAccess {
  const CompanyModuleAccess(this.profile);

  final UserProfile? profile;

  List<AppModule> get enabledModules {
    if (profile == null) return const [];
    if (profile!.isPlatformAdmin) return AppModule.values;
    return profile!.enabledModules;
  }

  bool hasModule(AppModule module) => enabledModules.contains(module);

  bool get hasMaintenance => hasModule(AppModule.maintenance);

  bool get hasRental => hasModule(AppModule.rental);

  bool get hasMultipleModules => enabledModules.length > 1;

  AppModule get defaultModule {
    if (hasMaintenance) return AppModule.maintenance;
    if (hasRental) return AppModule.rental;
    return AppModule.maintenance;
  }
}

extension CompanyModuleAccessX on UserProfile? {
  CompanyModuleAccess get modules => CompanyModuleAccess(this);
}
