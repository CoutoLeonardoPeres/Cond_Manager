import 'package:cond_manager/core/utils/invite_link.dart';
import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/features/users/domain/repositories/users_repository.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<ManagementCompany>>> listCompanies() async {
    try {
      final data = await _client
          .from('management_companies')
          .select('id, legal_name, trade_name, cnpj')
          .eq('status', EntityStatus.active.value)
          .order('legal_name');

      final list = (data as List<dynamic>).map((raw) {
        final m = raw as Map<String, dynamic>;
        return ManagementCompany(
          id: m['id'] as String,
          legalName: m['legal_name'] as String,
          tradeName: m['trade_name'] as String?,
          cnpj: m['cnpj'] as String?,
        );
      }).toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar empresas: $e'));
    }
  }

  @override
  Future<Result<List<OrganizationUser>>> listUsers(
    OrganizationUserListFilter filter,
  ) async {
    try {
      var query = _client.from('company_memberships').select('''
            id, company_id, role, status,
            profiles ( id, email, full_name, phone, status ),
            management_companies ( legal_name, trade_name )
          ''');

      if (filter.companyId != null) {
        query = query.eq('company_id', filter.companyId!);
      }
      if (filter.role != null) {
        query = query.eq('role', filter.role!.value);
      }

      final data = await query.order('created_at', ascending: false);
      final users = <OrganizationUser>[];

      for (final raw in data as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final profile = map['profiles'] as Map<String, dynamic>?;
        if (profile == null) continue;

        final company = map['management_companies'] as Map<String, dynamic>?;
        final companyName = company != null
            ? (company['trade_name'] as String? ?? company['legal_name'] as String?)
            : null;

        final profileId = profile['id'] as String;
        final role = OrganizationRole.fromValue(map['role'] as String);

        final condoRoles = await _client
            .from('user_condominium_roles')
            .select('condominium_id, condominiums ( name )')
            .eq('user_id', profileId)
            .eq('status', EntityStatus.active.value);

        final condoIds = <String>[];
        final condoNames = <String>[];
        for (final cr in condoRoles as List<dynamic>) {
          final cm = cr as Map<String, dynamic>;
          condoIds.add(cm['condominium_id'] as String);
          final c = cm['condominiums'] as Map<String, dynamic>?;
          if (c != null) condoNames.add(c['name'] as String);
        }

        final user = OrganizationUser(
          profileId: profileId,
          email: profile['email'] as String,
          fullName: profile['full_name'] as String,
          phone: profile['phone'] as String?,
          status: profile['status'] as String? ?? 'active',
          membershipId: map['id'] as String,
          companyId: map['company_id'] as String,
          companyName: companyName,
          organizationRole: role,
          condominiumIds: condoIds,
          condominiumNames: condoNames,
        );

        if (filter.search != null && filter.search!.trim().isNotEmpty) {
          final q = filter.search!.toLowerCase();
          if (!user.fullName.toLowerCase().contains(q) &&
              !user.email.toLowerCase().contains(q)) {
            continue;
          }
        }

        users.add(user);
      }

      return Success(users);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar usuários: $e'));
    }
  }

  @override
  Future<Result<OrganizationUser>> getUser(String profileId) async {
    try {
      final data = await _client
          .from('company_memberships')
          .select('''
            id, company_id, role, status,
            profiles!inner ( id, email, full_name, phone, status ),
            management_companies ( legal_name, trade_name )
          ''')
          .eq('user_id', profileId)
          .maybeSingle();

      if (data == null) {
        return const Failure(NetworkException('Usuário não encontrado.'));
      }

      final map = data;
      final profile = map['profiles'] as Map<String, dynamic>;
      final company = map['management_companies'] as Map<String, dynamic>?;
      final companyName = company != null
          ? (company['trade_name'] as String? ?? company['legal_name'] as String?)
          : null;

      final role = OrganizationRole.fromValue(map['role'] as String);

      final condoRoles = await _client
          .from('user_condominium_roles')
          .select('condominium_id, condominiums ( name )')
          .eq('user_id', profileId)
          .eq('status', EntityStatus.active.value);

      final condoIds = <String>[];
      final condoNames = <String>[];
      for (final cr in condoRoles as List<dynamic>) {
        final cm = cr as Map<String, dynamic>;
        condoIds.add(cm['condominium_id'] as String);
        final c = cm['condominiums'] as Map<String, dynamic>?;
        if (c != null) condoNames.add(c['name'] as String);
      }

      return Success(
        OrganizationUser(
          profileId: profile['id'] as String,
          email: profile['email'] as String,
          fullName: profile['full_name'] as String,
          phone: profile['phone'] as String?,
          status: profile['status'] as String? ?? 'active',
          membershipId: map['id'] as String,
          companyId: map['company_id'] as String,
          companyName: companyName,
          organizationRole: role,
          condominiumIds: condoIds,
          condominiumNames: condoNames,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar usuário: $e'));
    }
  }

  @override
  Future<Result<InviteUserResult>> inviteUser(OrganizationUserSaveInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('email', input.email.trim().toLowerCase())
          .maybeSingle();

      if (existing != null) {
        final pid = existing['id'] as String;
        await _client.from('company_memberships').upsert({
          'user_id': pid,
          'company_id': input.companyId,
          'role': input.organizationRole.value,
          'status': input.status,
        }, onConflict: 'user_id,company_id');

        await _client.from('profiles').update({
          'full_name': input.fullName.trim(),
          'phone': input.phone?.trim(),
          'status': input.status,
        }).eq('id', pid);

        await _syncClientCondominiums(pid, input);
        return const Success(
          InviteUserResult(linkedExistingUser: true, emailSent: false),
        );
      }

      final inviteRole = input.organizationRole == OrganizationRole.client
          ? UserRole.resident.value
          : UserRole.internalEmployee.value;

      final row = await _client
          .from('user_invitations')
          .insert({
            'email': input.email.trim().toLowerCase(),
            'company_id': input.companyId,
            'organization_role': input.organizationRole.value,
            'condominium_id':
                input.condominiumIds.isNotEmpty ? input.condominiumIds.first : null,
            if (input.condominiumIds.isNotEmpty)
              'condominium_ids': input.condominiumIds,
            'role': inviteRole,
            'invited_by': userId,
          })
          .select('token')
          .single();

      final token = row['token'] as String;
      final inviteLink = buildInviteLink(token);
      final emailResult = await _sendInviteEmail(
        token: token,
        inviteLink: inviteLink,
        fullName: input.fullName.trim(),
      );

      return Success(
        InviteUserResult(
          inviteToken: token,
          emailSent: emailResult.emailSent,
          emailError: emailResult.emailError,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao convidar usuário: $e'));
    }
  }

  @override
  Future<Result<void>> updateUser({
    required String profileId,
    required String fullName,
    String? phone,
    required OrganizationRole organizationRole,
    required String companyId,
    required List<String> condominiumIds,
    required String status,
  }) async {
    try {
      await _client.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'status': status,
      }).eq('id', profileId);

      await _client.from('company_memberships').update({
        'role': organizationRole.value,
        'status': status,
      }).eq('user_id', profileId).eq('company_id', companyId);

      await _syncClientCondominiums(
        profileId,
        OrganizationUserSaveInput(
          email: '',
          fullName: fullName,
          organizationRole: organizationRole,
          companyId: companyId,
          condominiumIds: condominiumIds,
          status: status,
        ),
      );

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar usuário: $e'));
    }
  }

  @override
  Future<Result<void>> deactivateUser(String profileId, String companyId) async {
    try {
      await _client.from('company_memberships').update({
        'status': EntityStatus.inactive.value,
      }).eq('user_id', profileId).eq('company_id', companyId);

      await _client.from('profiles').update({
        'status': EntityStatus.inactive.value,
      }).eq('id', profileId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao desativar usuário: $e'));
    }
  }

  Future<void> _syncClientCondominiums(
    String profileId,
    OrganizationUserSaveInput input,
  ) async {
    if (input.organizationRole != OrganizationRole.client) return;

    await _client
        .from('user_condominium_roles')
        .delete()
        .eq('user_id', profileId)
        .eq('role', UserRole.resident.value);

    for (final condoId in input.condominiumIds) {
      await _client.from('user_condominium_roles').upsert({
        'user_id': profileId,
        'condominium_id': condoId,
        'role': UserRole.resident.value,
        'status': EntityStatus.active.value,
      }, onConflict: 'user_id,condominium_id,role');
    }
  }

  Future<({bool emailSent, String? emailError})> _sendInviteEmail({
    required String token,
    required String inviteLink,
    required String fullName,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-user-invite',
        body: {
          'token': token,
          'inviteLink': inviteLink,
          'fullName': fullName,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Erro ao enviar e-mail (${response.status})';
        return (emailSent: false, emailError: message);
      }

      return (emailSent: true, emailError: null);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] != null
          ? details['error'].toString()
          : e.reasonPhrase ?? 'Edge Function indisponível';
      return (emailSent: false, emailError: message);
    } catch (e) {
      return (emailSent: false, emailError: e.toString());
    }
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
