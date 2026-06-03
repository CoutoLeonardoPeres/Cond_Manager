import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:equatable/equatable.dart';

class UserInvitationPreview extends Equatable {
  const UserInvitationPreview({
    required this.email,
    this.organizationRole,
    this.companyName,
    this.condominiumNames = const [],
    this.expiresAt,
    required this.isValid,
  });

  final String? email;
  final OrganizationRole? organizationRole;
  final String? companyName;
  final List<String> condominiumNames;
  final DateTime? expiresAt;
  final bool isValid;

  @override
  List<Object?> get props => [email, isValid];
}
