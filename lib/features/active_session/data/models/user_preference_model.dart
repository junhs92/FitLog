/// Data model for user preferences (equipment, level, muscle groups)
class UserPreferenceModel {
  final String id;
  final String userId;
  final List<String> preferredEquipment;
  final List<String> avoidEquipment;
  final String level;
  final List<String> preferredGroups;
  final List<String> avoidMuscleGroups;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferenceModel({
    required this.id,
    required this.userId,
    this.preferredEquipment = const [],
    this.avoidEquipment = const [],
    this.level = 'intermediate',
    this.preferredGroups = const [],
    this.avoidMuscleGroups = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      preferredEquipment: (json['preferred_equipment'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      avoidEquipment: (json['avoid_equipment'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      level: json['level'] as String? ?? 'intermediate',
      preferredGroups: (json['preferred_groups'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      avoidMuscleGroups: (json['avoid_muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String).toList() ?? const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'preferred_equipment': preferredEquipment,
      'avoid_equipment': avoidEquipment,
      'level': level,
      'preferred_groups': preferredGroups,
      'avoid_muscle_groups': avoidMuscleGroups,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPreferenceModel copyWith({
    String? id,
    String? userId,
    List<String>? preferredEquipment,
    List<String>? avoidEquipment,
    String? level,
    List<String>? preferredGroups,
    List<String>? avoidMuscleGroups,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      preferredEquipment: preferredEquipment ?? this.preferredEquipment,
      avoidEquipment: avoidEquipment ?? this.avoidEquipment,
      level: level ?? this.level,
      preferredGroups: preferredGroups ?? this.preferredGroups,
      avoidMuscleGroups: avoidMuscleGroups ?? this.avoidMuscleGroups,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
