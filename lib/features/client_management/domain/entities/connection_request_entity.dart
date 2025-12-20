/// Status of a connection request
enum ConnectionRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const ConnectionRequestStatus(this.value);

  static ConnectionRequestStatus fromString(String value) {
    return ConnectionRequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ConnectionRequestStatus.pending,
    );
  }
}

/// Connection request entity for trainer-client connections
class ConnectionRequestEntity {
  final String id;
  final String trainerId;
  final String clientId;
  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  /// Trainer info (populated when viewing as client)
  final String? trainerName;
  final String? trainerEmail;
  final String? trainerAvatarUrl;

  /// Client info (populated when viewing as trainer)
  final String? clientName;
  final String? clientEmail;
  final String? clientAvatarUrl;

  const ConnectionRequestEntity({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.trainerName,
    this.trainerEmail,
    this.trainerAvatarUrl,
    this.clientName,
    this.clientEmail,
    this.clientAvatarUrl,
  });

  bool get isPending => status == ConnectionRequestStatus.pending;
  bool get isApproved => status == ConnectionRequestStatus.approved;
  bool get isRejected => status == ConnectionRequestStatus.rejected;

  String get trainerInitials {
    if (trainerName == null || trainerName!.isEmpty) return '?';
    final parts = trainerName!.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String get clientInitials {
    if (clientName == null || clientName!.isEmpty) return '?';
    final parts = clientName!.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  ConnectionRequestEntity copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    ConnectionRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? trainerName,
    String? trainerEmail,
    String? trainerAvatarUrl,
    String? clientName,
    String? clientEmail,
    String? clientAvatarUrl,
  }) {
    return ConnectionRequestEntity(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      trainerName: trainerName ?? this.trainerName,
      trainerEmail: trainerEmail ?? this.trainerEmail,
      trainerAvatarUrl: trainerAvatarUrl ?? this.trainerAvatarUrl,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAvatarUrl: clientAvatarUrl ?? this.clientAvatarUrl,
    );
  }
}
