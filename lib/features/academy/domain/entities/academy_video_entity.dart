class AcademyVideoEntity {
  final String id;
  final String videoId;
  final String channelId;
  final String channelNameKo;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String category;
  final DateTime publishedAt;
  final int viewCount;
  final String? duration;

  const AcademyVideoEntity({
    required this.id,
    required this.videoId,
    required this.channelId,
    this.channelNameKo = '',
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.category,
    required this.publishedAt,
    this.viewCount = 0,
    this.duration,
  });

  /// Format ISO 8601 duration (PT1H2M3S) to human-readable (1:02:03)
  String get formattedDuration {
    if (duration == null || duration!.isEmpty) return '';
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(duration!);
    if (match == null) return '';

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format view count to shortened form (e.g., 1.2만)
  String get formattedViewCount {
    if (viewCount >= 100000000) {
      return '${(viewCount / 100000000).toStringAsFixed(1)}억회';
    } else if (viewCount >= 10000) {
      return '${(viewCount / 10000).toStringAsFixed(1)}만회';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}천회';
    }
    return '${viewCount}회';
  }

  /// Format published date to relative time (e.g., "3일 전")
  String get formattedPublishedAt {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inDays >= 365) {
      return '${diff.inDays ~/ 365}년 전';
    } else if (diff.inDays >= 30) {
      return '${diff.inDays ~/ 30}개월 전';
    } else if (diff.inDays >= 7) {
      return '${diff.inDays ~/ 7}주 전';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}시간 전';
    }
    return '방금 전';
  }
}
