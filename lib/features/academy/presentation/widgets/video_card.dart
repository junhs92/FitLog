import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/academy_video_entity.dart';
import '../providers/academy_provider.dart';
import 'youtube_player_widget.dart';

class VideoCard extends ConsumerWidget {
  final AcademyVideoEntity video;

  const VideoCard({required this.video, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playingVideoId = ref.watch(academyPlayingVideoProvider);
    final isPlaying = playingVideoId == video.videoId;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      elevation: 0,
      color: AppColors.neutralWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail or Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: isPlaying
                ? YouTubePlayerWidget(
                    videoId: video.videoId,
                    onClose: () {
                      ref.read(academyPlayingVideoProvider.notifier).state = null;
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      ref.read(academyPlayingVideoProvider.notifier).state =
                          video.videoId;
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail image
                        if (video.thumbnailUrl != null &&
                            video.thumbnailUrl!.isNotEmpty)
                          Image.network(
                            video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.neutral200,
                              child: const Icon(
                                Icons.play_circle_outline,
                                size: 48,
                                color: AppColors.neutral500,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.neutral200,
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: AppColors.neutral500,
                            ),
                          ),

                        // Play button overlay
                        const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 56,
                            color: Colors.white70,
                          ),
                        ),

                        // Duration badge
                        if (video.formattedDuration.isNotEmpty)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                video.formattedDuration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // Video info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  video.viewCount > 0
                      ? '조회수 ${video.formattedViewCount}  ·  ${video.formattedPublishedAt}'
                      : video.formattedPublishedAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
