import 'package:equatable/equatable.dart';

/// Warning level for session package status
enum PackageWarningLevel {
  none,
  low,
  critical,
  expired,
}

extension PackageWarningLevelExtension on PackageWarningLevel {
  String get displayMessage {
    switch (this) {
      case PackageWarningLevel.none:
        return '';
      case PackageWarningLevel.low:
        return 'Low sessions remaining';
      case PackageWarningLevel.critical:
        return 'No sessions remaining';
      case PackageWarningLevel.expired:
        return 'Package expired';
    }
  }

  bool get shouldShowWarning => this != PackageWarningLevel.none;
}

/// Domain entity for a client's session package
class SessionPackage extends Equatable {
  final String id;
  final String trainerId;
  final String clientId;
  final String packageName;
  final int totalSessions;
  final int sessionsUsed;
  final double? price;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  const SessionPackage({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.packageName,
    required this.totalSessions,
    this.sessionsUsed = 0,
    this.price,
    required this.purchasedAt,
    this.expiresAt,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  /// Get remaining sessions
  int get sessionsRemaining => totalSessions - sessionsUsed;

  /// Check if package is expired
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Check if package is depleted
  bool get isDepleted => sessionsUsed >= totalSessions;

  /// Check if package is valid for use
  bool get isValid => isActive && !isExpired && !isDepleted;

  /// Get warning level based on remaining sessions
  PackageWarningLevel get warningLevel {
    if (isExpired) return PackageWarningLevel.expired;
    if (sessionsRemaining <= 0) return PackageWarningLevel.critical;
    if (sessionsRemaining <= 2) return PackageWarningLevel.low;
    return PackageWarningLevel.none;
  }

  /// Get progress percentage (used / total)
  double get progressPercentage {
    if (totalSessions == 0) return 0;
    return sessionsUsed / totalSessions;
  }

  SessionPackage copyWith({
    String? id,
    String? trainerId,
    String? clientId,
    String? packageName,
    int? totalSessions,
    int? sessionsUsed,
    double? price,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return SessionPackage(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      clientId: clientId ?? this.clientId,
      packageName: packageName ?? this.packageName,
      totalSessions: totalSessions ?? this.totalSessions,
      sessionsUsed: sessionsUsed ?? this.sessionsUsed,
      price: price ?? this.price,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trainerId,
        clientId,
        totalSessions,
        sessionsUsed,
        isActive,
      ];
}
