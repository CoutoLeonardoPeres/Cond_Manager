import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
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
    this.condominiumRoles = const [],
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? cpf;
  final bool isPlatformAdmin;
  final String status;
  final List<CondominiumRoleModel> condominiumRoles;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['user_condominium_roles'] as List<dynamic>? ?? [];
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      cpf: json['cpf'] as String?,
      isPlatformAdmin: json['is_platform_admin'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      condominiumRoles: rolesJson
          .map((e) => CondominiumRoleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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
        condominiumRoles: condominiumRoles.map((r) => r.toEntity()).toList(),
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
