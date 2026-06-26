import 'package:cond_manager/core/errors/app_exception.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/auth/data/models/user_profile_model.dart';
import 'package:cond_manager/features/auth/domain/entities/user_invitation_preview.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:cond_manager/shared/domain/enums/organization_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(AppAuthException(_mapAuthError(e.message)));
    } catch (e) {
      return Failure(NetworkException('Erro ao entrar: $e'));
    }
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(AppAuthException(_mapAuthError(e.message)));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar: $e'));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException('Erro ao enviar recuperação: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(NetworkException('Erro ao sair: $e'));
    }
  }

  @override
  Future<Result<UserProfile>> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) {
      return const Failure(AppAuthException('Usuário não autenticado'));
    }

    try {
      final data = await _client
          .from('profiles')
          .select('''
            *,
            company_memberships!company_memberships_user_id_fkey (
              id, company_id, role, status,
              management_companies ( legal_name, trade_name )
            ),
            user_condominium_roles!user_condominium_roles_user_id_fkey (
              id, condominium_id, role, unit_id, is_primary, status,
              condominiums ( name )
            )
          ''')
          .eq('id', user.id)
          .single();

      final map = Map<String, dynamic>.from(data);

      String? companyId;
      final memberships = map['company_memberships'] as List<dynamic>?;
      if (memberships != null && memberships.isNotEmpty) {
        companyId = (memberships.first as Map<String, dynamic>)['company_id'] as String?;
      }

      if (companyId != null) {
        final condos = await _client
            .from('condominiums')
            .select('id')
            .eq('management_company_id', companyId)
            .eq('status', 'active');
        map['accessible_condominiums'] = (condos as List<dynamic>)
            .map((c) => (c as Map<String, dynamic>)['id'] as String)
            .toList();
      } else {
        map['accessible_condominiums'] = map['user_condominium_roles'] != null
            ? (map['user_condominium_roles'] as List<dynamic>)
                .map((r) => (r as Map<String, dynamic>)['condominium_id'] as String)
                .toList()
            : <String>[];
      }

      if (companyId != null) {
        final modules = await _client
            .from('company_modules')
            .select('module')
            .eq('company_id', companyId)
            .eq('status', 'active');
        map['enabled_modules'] = (modules as List<dynamic>)
            .map((m) => (m as Map<String, dynamic>)['module'] as String)
            .toList();
      } else {
        map['enabled_modules'] = ['maintenance'];
      }

      return Success(UserProfileModel.fromJson(map).toEntity());
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar perfil: $e'));
    }
  }

  @override
  Future<Result<UserInvitationPreview>> getInvitationPreview(String token) async {
    try {
      final data = await _client.rpc(
        'get_user_invitation_preview',
        params: {'p_token': token},
      );

      final row = data is List && data.isNotEmpty
          ? data.first as Map<String, dynamic>
          : data as Map<String, dynamic>?;

      if (row == null || row['email'] == null) {
        return const Success(
          UserInvitationPreview(email: null, isValid: false),
        );
      }

      final namesRaw = row['condominium_names'];
      final names = namesRaw is List
          ? namesRaw.map((e) => e.toString()).toList()
          : <String>[];

      final orgRoleRaw = row['organization_role'] as String?;
      return Success(
        UserInvitationPreview(
          email: row['email'] as String,
          organizationRole:
              orgRoleRaw != null ? OrganizationRole.fromValue(orgRoleRaw) : null,
          companyName: row['company_name'] as String?,
          condominiumNames: names,
          expiresAt: row['expires_at'] != null
              ? DateTime.parse(row['expires_at'] as String)
              : null,
          isValid: row['is_valid'] as bool? ?? false,
        ),
      );
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar convite: $e'));
    }
  }

  @override
  Future<Result<void>> acceptInvitation(String token) async {
    try {
      await _client.rpc('accept_user_invitation', params: {'p_token': token});
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(AppAuthException(e.message));
    } catch (e) {
      return Failure(NetworkException('Erro ao aceitar convite: $e'));
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar';
    }
    if (lower.contains('email login') && lower.contains('disabled')) {
      return 'Login por e-mail está desativado no Supabase. '
          'Ative em Authentication → Providers → Email.';
    }
    if (lower.contains('signup') && lower.contains('disabled')) {
      return 'Cadastro por e-mail está desativado no Supabase. '
          'Ative em Authentication → Providers → Email.';
    }
    return message;
  }
}
