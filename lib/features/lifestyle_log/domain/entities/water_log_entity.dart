import 'package:equatable/equatable.dart';

/// Entity representing water intake log
class WaterLogEntity extends Equatable {
  final String id;
  final String clientId;
  final DateTime logDate;
  final int amountMl;
  final DateTime loggedAt;

  const WaterLogEntity({
    required this.id,
    required this.clientId,
    required this.logDate,
    required this.amountMl,
    required this.loggedAt,
  });

  /// Amount in liters for display
  double get amountLiters => amountMl / 1000;

  /// Display string (e.g., "250 ml" or "1.5 L")
  String get displayAmount {
    if (amountMl >= 1000) {
      return '${amountLiters.toStringAsFixed(1)} L';
    }
    return '$amountMl ml';
  }

  WaterLogEntity copyWith({
    String? id,
    String? clientId,
    DateTime? logDate,
    int? amountMl,
    DateTime? loggedAt,
  }) {
    return WaterLogEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      logDate: logDate ?? this.logDate,
      amountMl: amountMl ?? this.amountMl,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  List<Object?> get props => [id, clientId, logDate, amountMl, loggedAt];
}

/// Daily water summary
class DailyWaterSummary extends Equatable {
  final DateTime date;
  final int totalMl;
  final int goalMl;
  final List<WaterLogEntity> logs;

  const DailyWaterSummary({
    required this.date,
    required this.totalMl,
    required this.goalMl,
    required this.logs,
  });

  /// Progress percentage (0.0 to 1.0+)
  double get progress => goalMl > 0 ? totalMl / goalMl : 0;

  /// Whether goal is reached
  bool get goalReached => totalMl >= goalMl;

  /// Remaining amount to reach goal
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  /// Display for total
  String get displayTotal {
    if (totalMl >= 1000) {
      return '${(totalMl / 1000).toStringAsFixed(1)} L';
    }
    return '$totalMl ml';
  }

  /// Display for goal
  String get displayGoal {
    if (goalMl >= 1000) {
      return '${(goalMl / 1000).toStringAsFixed(1)} L';
    }
    return '$goalMl ml';
  }

  @override
  List<Object?> get props => [date, totalMl, goalMl, logs];
}
