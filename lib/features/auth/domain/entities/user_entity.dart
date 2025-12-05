import '../../../../shared/models/user_role.dart';

/// User domain entity
class UserEntity {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.phone,
    this.profilePhotoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Check if user is a trainer
  bool get isTrainer => role == UserRole.trainer;

  /// Check if user is a client
  bool get isClient => role == UserRole.client;

  /// Get display name (name or email)
  String get displayName => name ?? email.split('@').first;

  /// Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
