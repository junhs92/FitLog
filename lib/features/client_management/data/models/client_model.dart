import '../../domain/entities/client_entity.dart';

/// Client data model for API/database operations
/// Maps to accounts table joined with trainer_client_relationships
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
  final String? notes; // From trainer_client_relationships.trainer_notes
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? relationshipId; // trainer_client_relationships.id

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
    this.notes,
    this.profilePhotoUrl,
    required this.createdAt,
    this.updatedAt,
    this.relationshipId,
  });

  /// Create from JSON (Supabase response with joined accounts data)
  /// Expected structure: {trainer_id, trainer_notes, client: {...accounts fields}}
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    // Handle nested client data from join query
    final clientData = json['client'] as Map<String, dynamic>? ?? json;

    return ClientModel(
      id: clientData['id'] as String,
      trainerId: json['trainer_id'] as String? ?? '',
      name: clientData['full_name'] as String? ?? '',
      email: clientData['email'] as String?,
      phone: clientData['phone'] as String?,
      dateOfBirth: clientData['date_of_birth'] != null
          ? DateTime.parse(clientData['date_of_birth'] as String)
          : null,
      gender: clientData['gender'] as String?,
      height: (clientData['height_cm'] as num?)?.toDouble(),
      weight: (clientData['weight_kg'] as num?)?.toDouble(),
      goals: clientData['fitness_goals'] != null
          ? List<String>.from(clientData['fitness_goals'] as List)
          : const [],
      notes: json['trainer_notes'] as String?,
      profilePhotoUrl: clientData['avatar_url'] as String?,
      createdAt: clientData['created_at'] != null
          ? DateTime.parse(clientData['created_at'] as String)
          : DateTime.now(),
      updatedAt: clientData['updated_at'] != null
          ? DateTime.parse(clientData['updated_at'] as String)
          : null,
      relationshipId: json['id'] as String?,
    );
  }

  /// Convert to JSON for API (accounts table format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height_cm': height,
      'weight_kg': weight,
      'fitness_goals': goals,
      'avatar_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for updating accounts table
  Map<String, dynamic> toAccountUpdateJson() {
    return {
      'full_name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height_cm': height,
      'weight_kg': weight,
      'fitness_goals': goals,
      'avatar_url': profilePhotoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert trainer notes to JSON for updating relationship
  Map<String, dynamic> toRelationshipUpdateJson() {
    return {
      'trainer_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to JSON for insert (without id, created_at auto-generated)
  @Deprecated('Use accounts table directly for creating users')
  Map<String, dynamic> toInsertJson() {
    return {
      'full_name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height_cm': height,
      'weight_kg': weight,
      'fitness_goals': goals,
      'avatar_url': profilePhotoUrl,
    };
  }

  /// Convert to JSON for update
  @Deprecated('Use toAccountUpdateJson or toRelationshipUpdateJson instead')
  Map<String, dynamic> toUpdateJson() {
    return toAccountUpdateJson();
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
      notes: entity.notes,
      profilePhotoUrl: entity.profilePhotoUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
