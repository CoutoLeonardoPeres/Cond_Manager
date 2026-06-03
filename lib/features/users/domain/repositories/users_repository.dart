import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';

abstract class UsersRepository {
  Future<Result<List<ManagementCompany>>> listCompanies();

  Future<Result<List<OrganizationUser>>> listUsers(OrganizationUserListFilter filter);

  Future<Result<OrganizationUser>> getUser(String profileId);

  Future<Result<InviteUserResult>> inviteUser(OrganizationUserSaveInput input);

  Future<Result<void>> updateUser({
    required String profileId,
    required String fullName,
    String? phone,
    required OrganizationRole organizationRole,
    required String companyId,
    required List<String> condominiumIds,
    required String status,
  });

  Future<Result<void>> deactivateUser(String profileId, String companyId);
}
