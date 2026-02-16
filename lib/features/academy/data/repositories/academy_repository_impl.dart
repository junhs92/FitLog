import 'package:dartz/dartz.dart';

import '../../../../shared/models/result.dart';
import '../../domain/entities/academy_video_entity.dart';
import '../../domain/repositories/academy_repository.dart';
import '../datasources/academy_remote_datasource.dart';

class AcademyRepositoryImpl implements AcademyRepository {
  final AcademyRemoteDataSource _remoteDataSource;

  AcademyRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<AcademyVideoEntity>>> getVideos({
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final videos = await _remoteDataSource.getVideos(
        category: category,
        limit: limit,
        offset: offset,
      );
      return Right(videos);
    } catch (e) {
      return Left(ServerFailure('Failed to load videos: $e'));
    }
  }

  @override
  Future<Result<void>> syncVideos() async {
    try {
      await _remoteDataSource.syncVideos();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to sync videos: $e'));
    }
  }
}
