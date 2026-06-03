import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (auth.value?.session == null) return null;

  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getCurrentProfile();
  return result.when(
    success: (profile) => profile,
    failure: (error) => throw error,
  );
});

final selectedCondominiumIdProvider = StateProvider<String?>((ref) => null);
