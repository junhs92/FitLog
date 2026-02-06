import '../../../../shared/models/result.dart';
import '../entities/session_package.dart';

/// Abstract interface for session package operations
abstract class SessionPackageRepository {
  /// Get all packages for a specific client
  Future<Result<List<SessionPackage>>> getClientPackages({
    required String clientId,
    bool activeOnly = true,
  });

  /// Get the primary active package (oldest non-expired, non-depleted)
  Future<Result<SessionPackage?>> getActivePackage(String clientId);

  /// Create a new session package
  Future<Result<SessionPackage>> createPackage({
    required String clientId,
    required String packageName,
    required int totalSessions,
    double? price,
    DateTime? expiresAt,
    String? notes,
  });

  /// Deduct a session from a package
  Future<Result<SessionPackage>> deductSession(String packageId);

  /// Update package details
  Future<Result<SessionPackage>> updatePackage({
    required String packageId,
    String? packageName,
    int? totalSessions,
    double? price,
    DateTime? expiresAt,
    bool? isActive,
    String? notes,
  });

  /// Get total remaining sessions for a client (across all active packages)
  Future<Result<int>> getTotalRemainingSessions(String clientId);
}
