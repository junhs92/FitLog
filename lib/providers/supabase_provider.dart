import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for Supabase auth
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// Provider for Supabase storage
final supabaseStorageProvider = Provider<SupabaseStorageClient>((ref) {
  return ref.watch(supabaseClientProvider).storage;
});

/// Provider for current auth session
final authSessionProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseAuthProvider).onAuthStateChange;
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseAuthProvider).currentUser;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
