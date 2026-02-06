import '../../domain/entities/session_package.dart';

/// Data model extending SessionPackage with JSON serialization
class SessionPackageModel extends SessionPackage {
  const SessionPackageModel({
    required super.id,
    required super.trainerId,
    required super.clientId,
    required super.packageName,
    required super.totalSessions,
    super.sessionsUsed,
    super.price,
    required super.purchasedAt,
    super.expiresAt,
    super.isActive,
    super.notes,
    required super.createdAt,
  });

  /// Parse from Supabase JSON response
  factory SessionPackageModel.fromJson(Map<String, dynamic> json) {
    return SessionPackageModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      packageName: json['package_name'] as String,
      totalSessions: json['total_sessions'] as int,
      sessionsUsed: json['sessions_used'] as int? ?? 0,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for INSERT operations
  Map<String, dynamic> toInsertJson(String trainerId) => {
        'trainer_id': trainerId,
        'client_id': clientId,
        'package_name': packageName,
        'total_sessions': totalSessions,
        'sessions_used': sessionsUsed,
        if (price != null) 'price': price,
        if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  /// Convert to JSON for UPDATE operations
  Map<String, dynamic> toUpdateJson() => {
        'package_name': packageName,
        'total_sessions': totalSessions,
        'sessions_used': sessionsUsed,
        'price': price,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'is_active': isActive,
        'notes': notes,
      };

  /// Create from entity
  factory SessionPackageModel.fromEntity(SessionPackage entity) {
    return SessionPackageModel(
      id: entity.id,
      trainerId: entity.trainerId,
      clientId: entity.clientId,
      packageName: entity.packageName,
      totalSessions: entity.totalSessions,
      sessionsUsed: entity.sessionsUsed,
      price: entity.price,
      purchasedAt: entity.purchasedAt,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
