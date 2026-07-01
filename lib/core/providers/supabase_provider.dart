import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Stream<AuthState> _authStateChanges(SupabaseClient client) async* {
  yield AuthState(
    AuthChangeEvent.initialSession,
    client.auth.currentSession,
  );
  yield* client.auth.onAuthStateChange;
}

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return _authStateChanges(client);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
