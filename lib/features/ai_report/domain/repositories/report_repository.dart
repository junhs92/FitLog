import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_report.dart';

/// Repository interface for AI report operations
abstract class ReportRepository {
  /// Generate a session report using AI
  Future<Either<Failure, SessionReportEntity>> generateReport({
    required String sessionId,
    required ReportType type,
    String? trainerComment,
  });

  /// Get a report by ID
  Future<Either<Failure, SessionReportEntity>> getReport(String reportId);

  /// Get all reports for a session
  Future<Either<Failure, List<SessionReportEntity>>> getSessionReports(
    String sessionId,
  );

  /// Get all reports for a client
  Future<Either<Failure, List<SessionReportEntity>>> getClientReports({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Update report with trainer comment
  Future<Either<Failure, SessionReportEntity>> updateTrainerComment({
    required String reportId,
    required String comment,
  });

  /// Send report to client
  Future<Either<Failure, SessionReportEntity>> sendReport({
    required String reportId,
    required String channel, // 'kakao', 'sms', 'in_app'
  });

  /// Mark report as viewed
  Future<Either<Failure, void>> markAsViewed(String reportId);

  /// Get available report templates
  Future<Either<Failure, List<ReportTemplate>>> getTemplates(ReportType type);

  /// Delete a report
  Future<Either<Failure, void>> deleteReport(String reportId);

  /// Regenerate report with different template
  Future<Either<Failure, SessionReportEntity>> regenerateReport({
    required String reportId,
    String? templateId,
  });
}
