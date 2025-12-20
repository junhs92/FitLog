import '../../domain/entities/water_log_entity.dart';

/// Data model for water logs with JSON serialization
class WaterLogModel extends WaterLogEntity {
  const WaterLogModel({
    required super.id,
    required super.clientId,
    required super.logDate,
    required super.amountMl,
    required super.loggedAt,
  });

  /// Create from JSON map
  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      amountMl: json['amount_ml'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'log_date': logDate.toIso8601String().split('T')[0],
      'amount_ml': amountMl,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  /// Create from entity
  factory WaterLogModel.fromEntity(WaterLogEntity entity) {
    return WaterLogModel(
      id: entity.id,
      clientId: entity.clientId,
      logDate: entity.logDate,
      amountMl: entity.amountMl,
      loggedAt: entity.loggedAt,
    );
  }
}
