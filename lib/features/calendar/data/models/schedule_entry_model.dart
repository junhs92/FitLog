import '../../../../core/utils/timestamp_utils.dart';
import '../../domain/entities/schedule_entry.dart';

/// Data model extending ScheduleEntry with JSON serialization
class ScheduleEntryModel extends ScheduleEntry {
  const ScheduleEntryModel({
    required super.id,
    required super.trainerId,
    required super.clientId,
    required super.clientName,
    super.clientPhotoUrl,
    required super.scheduledAt,
    super.durationMinutes,
    required super.status,
    super.notes,
    required super.createdAt,
  });

  /// Parse from Supabase JSON response
  factory ScheduleEntryModel.fromJson(Map<String, dynamic> json) {
    // Handle nested accounts join
    final clientAccount = json['accounts'] as Map<String, dynamic>?;

    return ScheduleEntryModel(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      clientName: clientAccount?['full_name'] as String? ?? 'Unknown',
      clientPhotoUrl: clientAccount?['avatar_url'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: ScheduleStatusExtension.fromDbValue(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for INSERT operations
  Map<String, dynamic> toInsertJson(String trainerId) => {
        'trainer_id': trainerId,
        'client_id': clientId,
        'scheduled_at': toLocalIso8601(scheduledAt),
        'duration_minutes': durationMinutes,
        'notes': notes,
      };

  /// Convert to JSON for UPDATE operations
  Map<String, dynamic> toUpdateJson() {
    final json = <String, dynamic>{};
    json['scheduled_at'] = toLocalIso8601(scheduledAt);
    json['duration_minutes'] = durationMinutes;
    json['status'] = status.dbValue;
    if (notes != null) json['notes'] = notes;
    return json;
  }

  /// Create from entity
  factory ScheduleEntryModel.fromEntity(ScheduleEntry entity) {
    return ScheduleEntryModel(
      id: entity.id,
      trainerId: entity.trainerId,
      clientId: entity.clientId,
      clientName: entity.clientName,
      clientPhotoUrl: entity.clientPhotoUrl,
      scheduledAt: entity.scheduledAt,
      durationMinutes: entity.durationMinutes,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
