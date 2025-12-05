import '../../domain/entities/client_entity.dart';

/// Client data model for API/database operations
class ClientModel {
  final String id;
  final String trainerId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final List<String> goals;
  final String? healthHistory;
  final String? notes;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClientModel({
    required this.id,
    required this.trainerId,
    required this.name,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.goals = const [],
    this.healthHistory,
    this.notes,
    this.profilePhotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      goals: json['goals'] != null
          ? List<String>.from(json['goals'] as List)
          : const [],
      healthHistory: json['health_history'] as String?,
      notes: json['notes'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height': height,
      'weight': weight,
      'goals': goals,
      'health_history': healthHistory,
      'notes': notes,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for insert (without id, created_at auto-generated)
  Map<String, dynamic> toInsertJson() {
    return {
      'trainer_id': trainerId,
      'name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height': height,
      'weight': weight,
      'goals': goals,
      'health_history': healthHistory,
      'notes': notes,
      'profile_photo_url': profilePhotoUrl,
    };
  }

  /// Convert to JSON for update
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height': height,
      'weight': weight,
      'goals': goals,
      'health_history': healthHistory,
      'notes': notes,
      'profile_photo_url': profilePhotoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to domain entity
  ClientEntity toEntity() {
    return ClientEntity(
      id: id,
      trainerId: trainerId,
      name: name,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      height: height,
      weight: weight,
      goals: goals,
      healthHistory: healthHistory,
      notes: notes,
      profilePhotoUrl: profilePhotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ClientModel.fromEntity(ClientEntity entity) {
    return ClientModel(
      id: entity.id,
      trainerId: entity.trainerId,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      height: entity.height,
      weight: entity.weight,
      goals: entity.goals,
      healthHistory: entity.healthHistory,
      notes: entity.notes,
      profilePhotoUrl: entity.profilePhotoUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
