import '../../domain/entities/body_photo_entity.dart';

/// Data model for body photos with JSON serialization
class BodyPhotoModel extends BodyPhotoEntity {
  const BodyPhotoModel({
    required super.id,
    required super.clientId,
    required super.photoDate,
    required super.angle,
    required super.photoUrl,
    super.weight,
    super.notes,
    required super.createdAt,
  });

  /// Create from JSON map
  factory BodyPhotoModel.fromJson(Map<String, dynamic> json) {
    return BodyPhotoModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      photoDate: DateTime.parse(json['photo_date'] as String),
      angle: _angleFromString(json['angle'] as String),
      photoUrl: json['photo_url'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'photo_date': photoDate.toIso8601String().split('T')[0],
      'angle': _angleToString(angle),
      'photo_url': photoUrl,
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from entity
  factory BodyPhotoModel.fromEntity(BodyPhotoEntity entity) {
    return BodyPhotoModel(
      id: entity.id,
      clientId: entity.clientId,
      photoDate: entity.photoDate,
      angle: entity.angle,
      photoUrl: entity.photoUrl,
      weight: entity.weight,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  static PhotoAngle _angleFromString(String value) {
    switch (value) {
      case 'front':
        return PhotoAngle.front;
      case 'side':
        return PhotoAngle.side;
      case 'back':
        return PhotoAngle.back;
      default:
        return PhotoAngle.front;
    }
  }

  static String _angleToString(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'front';
      case PhotoAngle.side:
        return 'side';
      case PhotoAngle.back:
        return 'back';
    }
  }
}
