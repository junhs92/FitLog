import '../../../../shared/models/result.dart';
import '../entities/user_entity.dart';

/// Authentication repository contract
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Get current authenticated user
  Future<Result<UserEntity?>> getCurrentUser();

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Result<UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? profilePhotoUrl,
  });

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;
}
