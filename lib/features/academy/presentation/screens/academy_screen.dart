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

class AcademyScreen extends ConsumerStatefulWidget {
  const AcademyScreen({super.key});

  @override
  ConsumerState<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends ConsumerState<AcademyScreen> {
  static const int _maxPerChannel = 5;
  final Set<String> _expandedChannels = {};

  @override
  Widget build(BuildContext context) {
    final videosState = ref.watch(academyVideosProvider);

    // Reset expanded state when category changes
    ref.listen(academyCategoryProvider, (_, __) {
      _expandedChannels.clear();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academy'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const CategoryChipBar(),
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
            child: _buildContent(videosState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AcademyVideosState state) {
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
      ..sort((a, b) =>
          b.value.first.publishedAt.compareTo(a.value.first.publishedAt));

    return RefreshIndicator(
      onRefresh: () => ref.read(academyVideosProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final allVideos = entry.value;
          final channelId = entry.key;
          final channelName = allVideos.first.channelNameKo.isNotEmpty
              ? allVideos.first.channelNameKo
              : channelId;

          final isExpanded = _expandedChannels.contains(channelId);
          final hasMore = allVideos.length > _maxPerChannel;
          final displayVideos = isExpanded
              ? allVideos
              : allVideos.take(_maxPerChannel).toList();
          final remainingCount = allVideos.length - _maxPerChannel;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel header
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: const Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          channelName.isNotEmpty
                              ? channelName.characters.first
                              : '?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutralWhite,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        channelName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '영상 ${allVideos.length}개',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              // Videos (capped at 5 unless expanded)
              ...displayVideos.map((v) => VideoCard(video: v)),
              // Load more / collapse button
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedChannels.remove(channelId);
                          } else {
                            _expandedChannels.add(channelId);
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isExpanded
                                ? '접기'
                                : '더보기 ($remainingCount개)',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (index < sortedEntries.length - 1)
                Container(
                  height: AppSpacing.sm,
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  color: AppColors.neutral100,
                ),
            ],
          );
        },
      ),
    );
  }
}
