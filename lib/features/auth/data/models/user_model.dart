import '../../../../shared/models/user_role.dart';
import '../../domain/entities/user_entity.dart';

/// User data model for API/database operations
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.phone,
    this.profilePhotoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Create from JSON (Supabase response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'client',
      phone: json['phone'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: UserRole.fromString(role),
      phone: phone,
      profilePhotoUrl: profilePhotoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role.value,
      phone: entity.phone,
      profilePhotoUrl: entity.profilePhotoUrl,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
    );
  }
}
