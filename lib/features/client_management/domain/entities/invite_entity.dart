/// Invite entity for trainer-client connection requests
class InviteEntity {
  final String id;
  final String trainerId;
  final String? clientId;
  final String? clientEmail;
  final String invitationCode;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;

  // Trainer info (populated when fetching invite by code)
  final String? trainerName;
  final String? trainerAvatarUrl;

  const InviteEntity({
    required this.id,
    required this.trainerId,
    this.clientId,
    this.clientEmail,
    required this.invitationCode,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.trainerName,
    this.trainerAvatarUrl,
  });

  factory InviteEntity.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;

    return InviteEntity(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String?,
      clientEmail: json['client_email'] as String?,
      invitationCode: json['invitation_code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      acceptedAt: json['invitation_accepted_at'] != null
          ? DateTime.parse(json['invitation_accepted_at'] as String)
          : null,
      trainerName: trainer?['full_name'] as String?,
      trainerAvatarUrl: trainer?['avatar_url'] as String?,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';

  String get trainerDisplayName => trainerName ?? 'Your Trainer';
}
