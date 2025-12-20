import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

/// Implementation of report repository
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, SessionReportEntity>> generateReport({
    required String sessionId,
    required ReportType type,
    String? trainerComment,
  }) async {
    try {
      final report = await _remoteDataSource.generateReport(
        sessionId: sessionId,
        type: type,
        trainerComment: trainerComment,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionReportEntity>> getReport(String reportId) async {
    try {
      final report = await _remoteDataSource.getReport(reportId);
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SessionReportEntity>>> getSessionReports(
    String sessionId,
  ) async {
    try {
      final reports = await _remoteDataSource.getSessionReports(sessionId);
      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SessionReportEntity>>> getClientReports({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final reports = await _remoteDataSource.getClientReports(
        clientId: clientId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionReportEntity>> updateTrainerComment({
    required String reportId,
    required String comment,
  }) async {
    try {
      final report = await _remoteDataSource.updateTrainerComment(
        reportId: reportId,
        comment: comment,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionReportEntity>> sendReport({
    required String reportId,
    required String channel,
  }) async {
    try {
      final report = await _remoteDataSource.sendReport(
        reportId: reportId,
        channel: channel,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsViewed(String reportId) async {
    try {
      await _remoteDataSource.markAsViewed(reportId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReportTemplate>>> getTemplates(
    ReportType type,
  ) async {
    try {
      final templates = await _remoteDataSource.getTemplates(type);
      return Right(templates);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport(String reportId) async {
    try {
      await _remoteDataSource.deleteReport(reportId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SessionReportEntity>> regenerateReport({
    required String reportId,
    String? templateId,
  }) async {
    try {
      final report = await _remoteDataSource.regenerateReport(
        reportId: reportId,
        templateId: templateId,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
