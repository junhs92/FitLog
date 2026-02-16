import '../../../../shared/models/result.dart';
import '../entities/academy_video_entity.dart';

abstract class AcademyRepository {
  Future<Result<List<AcademyVideoEntity>>> getVideos({
    String? category,
    int limit = 10,
    int offset = 0,
  });

  Future<Result<void>> syncVideos();
}
