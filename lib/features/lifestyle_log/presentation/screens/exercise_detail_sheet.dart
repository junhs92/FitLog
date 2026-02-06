import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/set_comment.dart';
import '../../domain/entities/exercise_stats_entity.dart';
import '../../domain/entities/exercise_volume_history_entity.dart';
import '../providers/lifestyle_provider.dart';
import '../widgets/exercise_volume_chart.dart';

/// Shows exercise detail sheet as a modal bottom sheet
void showExerciseDetailSheet(
  BuildContext context, {
  required String clientId,
  required ExerciseStatsEntity stats,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExerciseDetailSheet(
      clientId: clientId,
      stats: stats,
    ),
  );
}

/// Modal bottom sheet showing exercise details with volume chart
class ExerciseDetailSheet extends ConsumerWidget {
  final String clientId;
  final ExerciseStatsEntity stats;

  const ExerciseDetailSheet({
    required this.clientId,
    required this.stats,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeHistoryAsync = ref.watch(exerciseVolumeHistoryProvider((
      clientId: clientId,
      exerciseId: stats.exerciseId,
    )));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stats.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.neutral600,
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: volumeHistoryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (history) => ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Summary stats row
                      _SummaryStatsRow(stats: stats),
                      const SizedBox(height: AppSpacing.lg),
                      // Volume chart section
                      const Text(
                        '볼륨 추이',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ExerciseVolumeChart(history: history),
                      const SizedBox(height: AppSpacing.lg),
                      // Comment summary section (only if has comments)
                      if (history.hasComments) ...[
                        _CommentSummarySection(
                          commentSummary: history.commentSummary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Recent sessions section
                      if (history.sessions.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              '최근 세션',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutralBlack,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '총 ${history.sessionCount}회',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _RecentSessionsList(
                          sessions: history.sessions.reversed.take(10).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Summary stats row showing key metrics
class _SummaryStatsRow extends StatelessWidget {
  final ExerciseStatsEntity stats;

  const _SummaryStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStatItem(
              label: '최고중량',
              value: stats.maxWeightDisplay,
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.neutral200,
          ),
          Expanded(
            child: _SummaryStatItem(
              label: '1RM',
              value: stats.estimated1RMDisplay,
              color: AppColors.secondary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.neutral200,
          ),
          Expanded(
            child: _SummaryStatItem(
              label: '수행',
              value: '${stats.timesPerformed}회',
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single summary stat item
class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

/// Recent sessions list
class _RecentSessionsList extends StatelessWidget {
  final List<ExerciseSessionVolumeEntity> sessions;

  const _RecentSessionsList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _SessionRow(session: session);
        },
      ),
    );
  }
}

/// Individual session row
class _SessionRow extends StatelessWidget {
  final ExerciseSessionVolumeEntity session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date
              SizedBox(
                width: 80,
                child: Text(
                  DateFormat('M/d (E)').format(session.sessionDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              // Set count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${session.setCount}세트',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
              const Spacer(),
              // Volume
              Text(
                session.volumeDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              // PR indicator
              if (session.hasPR) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 18,
                ),
              ],
            ],
          ),
          // Session comments (if any)
          if (session.hasComments) ...[
            const SizedBox(height: 6),
            _SessionCommentsDisplay(comments: session.comments),
          ],
        ],
      ),
    );
  }
}

/// Comment summary section showing top comments with frequency
class _CommentSummarySection extends StatelessWidget {
  final List<ExerciseCommentSummaryEntity> commentSummary;

  const _CommentSummarySection({required this.commentSummary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 코칭 노트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commentSummary.take(8).map((summary) {
              return _CommentFrequencyChip(summary: summary);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Comment chip with frequency badge
class _CommentFrequencyChip extends StatelessWidget {
  final ExerciseCommentSummaryEntity summary;

  const _CommentFrequencyChip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final setComment = SetCommentExtension.fromDatabaseKey(summary.commentKey);
    final displayName = setComment?.shortDisplayName ?? summary.commentKey;
    final category = setComment?.category;

    // Get color based on category
    final (bgColor, textColor) = _getCategoryColors(category);

    // Build display text with detail if present
    final text = summary.detail != null
        ? '$displayName: ${summary.detail}'
        : displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${summary.count}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getCategoryColors(SetCommentCategory? category) {
    switch (category) {
      case SetCommentCategory.mistake:
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100)); // Orange
      case SetCommentCategory.coachingCue:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0)); // Blue
      case SetCommentCategory.condition:
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)); // Green
      case null:
        return (AppColors.neutral100, AppColors.neutral700); // Default gray
    }
  }
}

/// Compact inline display for session comments
class _SessionCommentsDisplay extends StatelessWidget {
  final List<String> comments;

  const _SessionCommentsDisplay({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: comments.take(4).map((comment) {
        return _MiniCommentChip(comment: comment);
      }).toList(),
    );
  }
}

/// Small chip for per-session comment display
class _MiniCommentChip extends StatelessWidget {
  final String comment;

  const _MiniCommentChip({required this.comment});

  @override
  Widget build(BuildContext context) {
    // Parse comment key and detail
    final parts = comment.split(':');
    final key = parts[0];
    final detail = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;

    final setComment = SetCommentExtension.fromDatabaseKey(key);
    final displayName = setComment?.shortDisplayName ?? key;
    final category = setComment?.category;

    // Get color based on category
    final (bgColor, textColor) = _getMiniChipColors(category);

    // Build display text with detail if present
    final text = detail != null ? '$displayName: $detail' : displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color) _getMiniChipColors(SetCommentCategory? category) {
    switch (category) {
      case SetCommentCategory.mistake:
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100)); // Orange
      case SetCommentCategory.coachingCue:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0)); // Blue
      case SetCommentCategory.condition:
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)); // Green
      case null:
        return (AppColors.neutral100, AppColors.neutral700); // Default gray
    }
  }
}
