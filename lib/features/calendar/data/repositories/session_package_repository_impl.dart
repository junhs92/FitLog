import 'package:dartz/dartz.dart';

import '../../../../shared/models/result.dart';
import '../../domain/entities/session_package.dart';
import '../../domain/repositories/session_package_repository.dart';
import '../datasources/session_package_remote_datasource.dart';

/// Implementation of SessionPackageRepository
class SessionPackageRepositoryImpl implements SessionPackageRepository {
  final SessionPackageRemoteDataSource _dataSource;
  final String _trainerId;

  SessionPackageRepositoryImpl({
    required SessionPackageRemoteDataSource dataSource,
    required String trainerId,
  })  : _dataSource = dataSource,
        _trainerId = trainerId;

  @override
  Future<Result<List<SessionPackage>>> getClientPackages({
    required String clientId,
    bool activeOnly = true,
  }) async {
    try {
      final packages = await _dataSource.getClientPackages(
        trainerId: _trainerId,
        clientId: clientId,
        activeOnly: activeOnly,
      );
      return Right(packages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionPackage?>> getActivePackage(String clientId) async {
    try {
      final package = await _dataSource.getActivePackage(
        trainerId: _trainerId,
        clientId: clientId,
      );
      return Right(package);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionPackage>> createPackage({
    required String clientId,
    required String packageName,
    required int totalSessions,
    double? price,
    DateTime? expiresAt,
    String? notes,
  }) async {
    try {
      final package = await _dataSource.createPackage(
        trainerId: _trainerId,
        clientId: clientId,
        packageName: packageName,
        totalSessions: totalSessions,
        price: price,
        expiresAt: expiresAt,
        notes: notes,
      );
      return Right(package);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionPackage>> deductSession(String packageId) async {
    try {
      final package = await _dataSource.deductSession(packageId);
      return Right(package);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<SessionPackage>> updatePackage({
    required String packageId,
    String? packageName,
    int? totalSessions,
    double? price,
    DateTime? expiresAt,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final package = await _dataSource.updatePackage(
        packageId: packageId,
        packageName: packageName,
        totalSessions: totalSessions,
        price: price,
        expiresAt: expiresAt,
        isActive: isActive,
        notes: notes,
      );
      return Right(package);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> getTotalRemainingSessions(String clientId) async {
    try {
      final remaining = await _dataSource.getTotalRemainingSessions(
        trainerId: _trainerId,
        clientId: clientId,
      );
      return Right(remaining);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
