import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
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
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? cpf;
  final bool isPlatformAdmin;
  final String status;
  final CompanyMembership? companyMembership;
  final List<CondominiumRole> condominiumRoles;
  final List<String> accessibleCondominiumIds;

  OrganizationRole? get primaryOrganizationRole => companyMembership?.role;

  String? get companyId => companyMembership?.companyId;

  UserRole? roleInCondominium(String condominiumId) {
    final match = condominiumRoles.where(
      (r) => r.condominiumId == condominiumId && r.status == 'active',
    );
    if (match.isEmpty) return null;
    return match.first.role;
  }

  bool hasCompanyAccessToCondominium(String condominiumId) {
    if (companyId == null) return false;
    return accessibleCondominiumIds.contains(condominiumId);
  }

  @override
  List<Object?> get props => [id, email, fullName, isPlatformAdmin, companyMembership, condominiumRoles];
}

class CompanyMembership extends Equatable {
  const CompanyMembership({
    required this.id,
    required this.companyId,
    this.companyName,
    required this.role,
    this.status = 'active',
  });

  final String id;
  final String companyId;
  final String? companyName;
  final OrganizationRole role;
  final String status;

  @override
  List<Object?> get props => [id, companyId, role];
}

class CondominiumRole extends Equatable {
  const CondominiumRole({
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
  final String? condominiumName;
  final UserRole role;
  final String? unitId;
  final bool isPrimary;
  final String status;

  @override
  List<Object?> get props => [id, condominiumId, role];
}
