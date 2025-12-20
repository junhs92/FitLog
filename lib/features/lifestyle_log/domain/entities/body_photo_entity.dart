import 'package:equatable/equatable.dart';

/// Body photo angle/type
enum PhotoAngle {
  front,
  side,
  back,
}

/// Entity representing a body progress photo
class BodyPhotoEntity extends Equatable {
  final String id;
  final String clientId;
  final DateTime photoDate;
  final PhotoAngle angle;
  final String photoUrl;
  final double? weight;
  final String? notes;
  final DateTime createdAt;

  const BodyPhotoEntity({
    required this.id,
    required this.clientId,
    required this.photoDate,
    required this.angle,
    required this.photoUrl,
    this.weight,
    this.notes,
    required this.createdAt,
  });

  /// Angle display name
  String get angleName {
    switch (angle) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.side:
        return 'Side';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  /// Angle icon
  String get angleIcon {
    switch (angle) {
      case PhotoAngle.front:
        return '👤';
      case PhotoAngle.side:
        return '👥';
      case PhotoAngle.back:
        return '🔙';
    }
  }

  BodyPhotoEntity copyWith({
    String? id,
    String? clientId,
    DateTime? photoDate,
    PhotoAngle? angle,
    String? photoUrl,
    double? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyPhotoEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      photoDate: photoDate ?? this.photoDate,
      angle: angle ?? this.angle,
      photoUrl: photoUrl ?? this.photoUrl,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        photoDate,
        angle,
        photoUrl,
        weight,
        notes,
        createdAt,
      ];
}
