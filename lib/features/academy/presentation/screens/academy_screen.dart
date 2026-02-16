import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../domain/entities/academy_video_entity.dart';
import '../providers/academy_provider.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/video_card.dart';

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(academyVideosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academy'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const CategoryChipBar(),
          // Sync indicator
          if (videosState.isSyncing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '최신 영상을 가져오는 중...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _buildContent(context, ref, videosState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, AcademyVideosState state) {
    if (state.isLoading) {
      return const LoadingIndicator();
    }

    if (state.errorMessage != null && state.videos.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(academyVideosProvider.notifier).refresh(),
      );
    }

    if (state.videos.isEmpty) {
      return const ErrorView(
        message: '영상이 없습니다',
        icon: Icons.video_library_outlined,
      );
    }

    // Group videos by channel
    final channelGroups = <String, List<AcademyVideoEntity>>{};
    for (final video in state.videos) {
      channelGroups.putIfAbsent(video.channelId, () => []).add(video);
    }

    // Sort channels by latest video date (most recent first)
    final sortedEntries = channelGroups.entries.toList()
      ..sort(
          (a, b) => b.value.first.publishedAt.compareTo(a.value.first.publishedAt));

    return RefreshIndicator(
      onRefresh: () => ref.read(academyVideosProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final videos = entry.value;
          final channelName =
              videos.first.channelNameKo.isNotEmpty
                  ? videos.first.channelNameKo
                  : videos.first.channelId;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          channelName.isNotEmpty
                              ? channelName.characters.first
                              : '?',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        channelName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${videos.length}개',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral500,
                          ),
                    ),
                  ],
                ),
              ),
              // Videos for this channel
              ...videos.map((v) => VideoCard(video: v)),
              if (index < sortedEntries.length - 1)
                const Divider(
                  height: AppSpacing.lg,
                  thickness: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                  color: AppColors.neutral200,
                ),
            ],
          );
        },
      ),
    );
  }
}
