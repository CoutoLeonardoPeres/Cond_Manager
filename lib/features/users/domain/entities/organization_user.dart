import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:equatable/equatable.dart';

class InviteUserResult {
  const InviteUserResult({
    this.inviteToken,
    this.emailSent = false,
    this.emailError,
    this.linkedExistingUser = false,
  });

  /// Token do convite (null se usuário já existia e foi vinculado).
  final String? inviteToken;

  /// E-mail enviado pela Edge Function.
  final bool emailSent;

  /// Mensagem quando o e-mail não foi enviado (function indisponível, Resend, etc.).
  final String? emailError;

  /// Usuário já tinha conta — vinculado direto, sem convite.
  final bool linkedExistingUser;
}

class OrganizationUser extends Equatable {
  const OrganizationUser({
    required this.profileId,
    required this.email,
    required this.fullName,
    this.phone,
    required this.status,
    this.membershipId,
    this.companyId,
    this.companyName,
    this.organizationRole,
    this.condominiumNames = const [],
    this.condominiumIds = const [],
  });

  final String profileId;
  final String email;
  final String fullName;
  final String? phone;
  final String status;
  final String? membershipId;
  final String? companyId;
  final String? companyName;
  final OrganizationRole? organizationRole;
  final List<String> condominiumNames;
  final List<String> condominiumIds;

  String get roleLabel {
    if (organizationRole != null) return organizationRole!.label;
    if (condominiumNames.isNotEmpty) return 'Cliente condomínio';
    return '—';
  }

  @override
  List<Object?> get props => [profileId];
}

class OrganizationUserListFilter extends Equatable {
  const OrganizationUserListFilter({
    this.companyId,
    this.role,
    this.search,
  });

  final String? companyId;
  final OrganizationRole? role;
  final String? search;

  OrganizationUserListFilter copyWith({
    String? companyId,
    OrganizationRole? role,
    String? search,
    bool clearRole = false,
  }) {
    return OrganizationUserListFilter(
      companyId: companyId ?? this.companyId,
      role: clearRole ? null : (role ?? this.role),
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [companyId, role];
}

class OrganizationUserSaveInput extends Equatable {
  const OrganizationUserSaveInput({
    required this.email,
    required this.fullName,
    this.phone,
    required this.organizationRole,
    required this.companyId,
    this.condominiumIds = const [],
    this.status = 'active',
  });

  final String email;
  final String fullName;
  final String? phone;
  final OrganizationRole organizationRole;
  final String companyId;
  final List<String> condominiumIds;
  final String status;

  @override
  List<Object?> get props => [email, organizationRole];
}

class ManagementCompany extends Equatable {
  const ManagementCompany({
    required this.id,
    required this.legalName,
    this.tradeName,
    this.cnpj,
  });

  final String id;
  final String legalName;
  final String? tradeName;
  final String? cnpj;

  String get displayName =>
      tradeName?.trim().isNotEmpty == true ? tradeName! : legalName;

  @override
  List<Object?> get props => [id];
}
