import '../../../../shared/models/result.dart';
import '../entities/body_photo_entity.dart';
import '../repositories/lifestyle_repository.dart';

/// Use case to log body progress photos
class LogBodyPhoto {
  final LifestyleRepository _repository;

  LogBodyPhoto(this._repository);

  /// Upload and log a body photo
  Future<Result<BodyPhotoEntity>> call({
    required String clientId,
    required DateTime date,
    required PhotoAngle angle,
    required String localFilePath,
    double? weight,
    String? notes,
  }) {
    return _repository.logBodyPhoto(
      clientId: clientId,
      date: date,
      angle: angle,
      localFilePath: localFilePath,
      weight: weight,
      notes: notes,
    );
  }

  /// Delete a body photo
  Future<Result<void>> delete(String photoId) {
    return _repository.deleteBodyPhoto(photoId);
  }

  /// Get body photos
  Future<Result<List<BodyPhotoEntity>>> getPhotos({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
    PhotoAngle? angle,
    int limit = 50,
  }) {
    return _repository.getBodyPhotos(
      clientId: clientId,
      fromDate: fromDate,
      toDate: toDate,
      angle: angle,
      limit: limit,
    );
  }
}
