import '../../domain/entities/academy_video_entity.dart';

class AcademyVideoModel extends AcademyVideoEntity {
  const AcademyVideoModel({
    required super.id,
    required super.videoId,
    required super.channelId,
    super.channelNameKo,
    required super.title,
    super.description,
    super.thumbnailUrl,
    required super.category,
    required super.publishedAt,
    super.viewCount,
    super.duration,
  });

  factory AcademyVideoModel.fromJson(Map<String, dynamic> json) {
    final channel = json['academy_channels'] as Map<String, dynamic>?;
    return AcademyVideoModel(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      channelId: json['channel_id'] as String,
      channelNameKo: channel?['channel_name_ko'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      duration: json['duration'] as String?,
    );
  }
}
