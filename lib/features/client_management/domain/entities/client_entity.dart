/// Client domain entity
class ClientEntity {
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

  const ClientEntity({
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

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Get formatted goals string
  String get goalsText => goals.join(', ');

  ClientEntity copyWith({
    String? id,
    String? trainerId,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    List<String>? goals,
    String? healthHistory,
    String? notes,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientEntity(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goals: goals ?? this.goals,
      healthHistory: healthHistory ?? this.healthHistory,
      notes: notes ?? this.notes,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
