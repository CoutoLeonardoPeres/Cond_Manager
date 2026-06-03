import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/auth/domain/entities/user_invitation_preview.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  User? get currentUser;
  Stream<AuthState> get authStateChanges;

  Future<Result<void>> signIn({required String email, required String password});
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<Result<void>> resetPassword(String email);
  Future<Result<void>> signOut();
  Future<Result<UserProfile>> getCurrentProfile();
  Future<Result<UserInvitationPreview>> getInvitationPreview(String token);
  Future<Result<void>> acceptInvitation(String token);
}
