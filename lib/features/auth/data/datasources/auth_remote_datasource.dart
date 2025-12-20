import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String name, String role);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel> updateProfile(Map<String, dynamic> data);
  Stream<UserModel?> get authStateChanges;
}

/// Implementation of AuthRemoteDataSource using Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed');
    }

    // Fetch user profile from accounts table using user_id
    final userData = await _client
        .from(ApiConstants.accountsTable)
        .select()
        .eq('user_id', response.user!.id)
        .single();

    // Update last login
    await _client
        .from(ApiConstants.accountsTable)
        .update({
          'last_login_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', response.user!.id);

    return UserModel.fromJson(userData);
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String name,
    String role,
  ) async {
    // Pass user data via metadata - the database trigger will create the account
    // This is more secure as it doesn't expose direct table access to clients
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'role': role,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed');
    }

    // After signup, user may not have a session yet (email confirmation pending)
    // Return user data from the signup response, not from database
    // The database trigger creates the account record server-side
    // Full account data will be fetched on login when session is active
    return UserModel(
      id: '', // Will be set when fetched from DB on login
      userId: response.user!.id,
      email: email,
      name: name,
      role: role,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final userData = await _client
        .from(ApiConstants.accountsTable)
        .select()
        .eq('user_id', user.id)
        .single();

    return UserModel.fromJson(userData);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Add updated_at timestamp
    data['updated_at'] = DateTime.now().toIso8601String();

    await _client
        .from(ApiConstants.accountsTable)
        .update(data)
        .eq('user_id', user.id);

    final userData = await _client
        .from(ApiConstants.accountsTable)
        .select()
        .eq('user_id', user.id)
        .single();

    return UserModel.fromJson(userData);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) {
        return null;
      }

      try {
        final userData = await _client
            .from(ApiConstants.accountsTable)
            .select()
            .eq('user_id', event.session!.user.id)
            .single();

        return UserModel.fromJson(userData);
      } catch (e) {
        return null;
      }
    });
  }
}
