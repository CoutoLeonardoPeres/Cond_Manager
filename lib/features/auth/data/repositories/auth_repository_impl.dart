import 'package:cond_manager/core/errors/app_exception.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/auth/data/models/user_profile_model.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/features/auth/domain/repositories/auth_repository.dart';
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
            user_condominium_roles (
              id, condominium_id, role, unit_id, is_primary, status,
              condominiums ( name )
            )
          ''')
          .eq('id', user.id)
          .single();

      return Success(UserProfileModel.fromJson(data).toEntity());
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar perfil: $e'));
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar';
    }
    return message;
  }
}
