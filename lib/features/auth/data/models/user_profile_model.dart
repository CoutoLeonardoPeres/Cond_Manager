import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.cpf,
    this.isPlatformAdmin = false,
    this.status = 'active',
    this.companyMembership,
    this.condominiumRoles = const [],
    this.accessibleCondominiumIds = const [],
    this.enabledModules = const [AppModule.maintenance],
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? cpf;
  final bool isPlatformAdmin;
  final String status;
  final CompanyMembershipModel? companyMembership;
  final List<CondominiumRoleModel> condominiumRoles;
  final List<String> accessibleCondominiumIds;
  final List<AppModule> enabledModules;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['user_condominium_roles'] as List<dynamic>? ?? [];
    final memberships = json['company_memberships'] as List<dynamic>? ?? [];

    CompanyMembershipModel? membership;
    if (memberships.isNotEmpty) {
      membership = CompanyMembershipModel.fromJson(
        memberships.first as Map<String, dynamic>,
      );
    }

    final condoIdsRaw = json['accessible_condominiums'] as List<dynamic>? ?? [];
    final condoIds = condoIdsRaw.map((e) {
      if (e is String) return e;
      if (e is Map<String, dynamic>) return e['id'] as String;
      return e.toString();
    }).toList();

    final modulesRaw = json['enabled_modules'] as List<dynamic>? ?? [];
    final modules = modulesRaw.isEmpty
        ? const [AppModule.maintenance]
        : modulesRaw
            .map((e) => AppModule.fromValue(e is String ? e : e['module'] as String))
            .toList();

    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      cpf: json['cpf'] as String?,
      isPlatformAdmin: json['is_platform_admin'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      companyMembership: membership,
      condominiumRoles: rolesJson
          .map((e) => CondominiumRoleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      accessibleCondominiumIds: condoIds,
      enabledModules: modules,
    );
  }

  UserProfile toEntity() => UserProfile(
        id: id,
        email: email,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
        cpf: cpf,
        isPlatformAdmin: isPlatformAdmin,
        status: status,
        companyMembership: companyMembership?.toEntity(),
        condominiumRoles: condominiumRoles.map((r) => r.toEntity()).toList(),
        accessibleCondominiumIds: accessibleCondominiumIds,
        enabledModules: enabledModules,
      );
}

class CompanyMembershipModel {
  const CompanyMembershipModel({
    required this.id,
    required this.companyId,
    this.companyName,
    required this.role,
    this.status = 'active',
  });

  final String id;
  final String companyId;
  final String? companyName;
  final String role;
  final String status;

  factory CompanyMembershipModel.fromJson(Map<String, dynamic> json) {
    final company = json['management_companies'];
    String? name;
    if (company is Map<String, dynamic>) {
      name = company['trade_name'] as String? ?? company['legal_name'] as String?;
    }
    return CompanyMembershipModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: name,
      role: json['role'] as String,
      status: json['status'] as String? ?? 'active',
    );
  }

  CompanyMembership toEntity() => CompanyMembership(
        id: id,
        companyId: companyId,
        companyName: companyName,
        role: OrganizationRole.fromValue(role),
        status: status,
      );
}

class CondominiumRoleModel {
  const CondominiumRoleModel({
    required this.id,
    required this.condominiumId,
    required this.role,
    this.condominiumName,
    this.unitId,
    this.isPrimary = false,
    this.status = 'active',
  });

  final String id;
  final String condominiumId;
  final String role;
  final String? condominiumName;
  final String? unitId;
  final bool isPrimary;
  final String status;

  factory CondominiumRoleModel.fromJson(Map<String, dynamic> json) {
    final condo = json['condominiums'] as Map<String, dynamic>?;
    return CondominiumRoleModel(
      id: json['id'] as String,
      condominiumId: json['condominium_id'] as String,
      role: json['role'] as String,
      condominiumName: condo?['name'] as String?,
      unitId: json['unit_id'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }

  CondominiumRole toEntity() => CondominiumRole(
        id: id,
        condominiumId: condominiumId,
        role: UserRole.fromValue(role),
        condominiumName: condominiumName,
        unitId: unitId,
        isPrimary: isPrimary,
        status: status,
      );
}
