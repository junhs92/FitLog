import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../ai_report/domain/entities/session_report.dart';
import '../../../ai_report/presentation/providers/report_provider.dart';
import '../../../muscle_map/presentation/providers/muscle_activity_provider.dart';
import '../../../muscle_map/presentation/widgets/report_muscle_map.dart';

/// Read-only report detail screen for clients
class ClientReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ClientReportDetailScreen({required this.reportId, super.key});

  @override
  ConsumerState<ClientReportDetailScreen> createState() => _ClientReportDetailScreenState();
}

class _ClientReportDetailScreenState extends ConsumerState<ClientReportDetailScreen> {
  bool _hasMarkedViewed = false;

  @override
  void initState() {
    super.initState();
    // Load the report when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportGenerationProvider.notifier).loadReport(widget.reportId);
    });
  }

  void _markAsViewed(SessionReportEntity report) {
    if (_hasMarkedViewed) return;
    _hasMarkedViewed = true;

    // Mark as viewed if not already
    if (report.status != ReportStatus.viewed) {
      ref.read(reportRepositoryProvider).markAsViewed(widget.reportId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportGenerationProvider);

    // Mark as viewed when report loads
    if (state.report != null && !_hasMarkedViewed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markAsViewed(state.report!);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Session Report'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!)
              : state.report == null
                  ? _buildEmpty()
                  : _buildContent(state.report!),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.read(reportGenerationProvider.notifier).loadReport(widget.reportId);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 48, color: AppColors.neutral400),
          SizedBox(height: AppSpacing.md),
          Text(
            'Report not available',
            style: TextStyle(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SessionReportEntity report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Report header with date
          _ReportHeader(report: report),
          const SizedBox(height: AppSpacing.lg),

          // Highlights
          if (report.highlights.isNotEmpty) ...[
            _HighlightsSection(highlights: report.highlights),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Muscle map section
          _MuscleMapSection(sessionId: report.sessionId),
          const SizedBox(height: AppSpacing.lg),

          // Report content
          _ReportContentCard(report: report),

          // Trainer comment (read-only)
          if (report.trainerComment != null && report.trainerComment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _TrainerCommentCard(comment: report.trainerComment!),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final SessionReportEntity report;

  const _ReportHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM d, yyyy').format(report.generatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral600,
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

class _HighlightsSection extends StatelessWidget {
  final List<ReportHighlight> highlights;

  const _HighlightsSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, size: 20, color: AppColors.warning),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Highlights',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: highlights.map((h) => _HighlightChip(highlight: h)).toList(),
        ),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final ReportHighlight highlight;

  const _HighlightChip({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(highlight.type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                highlight.displayTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getColor(),
                ),
              ),
              if (highlight.displayDescription.isNotEmpty)
                Text(
                  highlight.displayDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getColor().withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (highlight.type) {
      case HighlightType.pr:
        return AppColors.warning;
      case HighlightType.improvement:
        return AppColors.success;
      case HighlightType.consistency:
        return AppColors.primary;
      case HighlightType.effort:
        return AppColors.secondary;
      case HighlightType.milestone:
        return AppColors.primary;
      case HighlightType.caution:
        return AppColors.error;
    }
  }
}

class _MuscleMapSection extends ConsumerWidget {
  final String sessionId;

  const _MuscleMapSection({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleActivityAsync = ref.watch(sessionMuscleActivityProvider(sessionId));

    return muscleActivityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activity) {
        if (activity.musclesWorked.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.accessibility_new, size: 20, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Muscles Worked',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ReportMuscleMap(sessionActivity: activity),
          ],
        );
      },
    );
  }
}

class _ReportContentCard extends StatelessWidget {
  final SessionReportEntity report;

  const _ReportContentCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Session Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(height: 24),
          MarkdownBody(
            data: report.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
              h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
              listBullet: Theme.of(context).textTheme.bodyMedium,
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.neutral300, width: 1),
                ),
              ),
              blockSpacing: 12,
              listIndent: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerCommentCard extends StatelessWidget {
  final String comment;

  const _TrainerCommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.message, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'From Your Trainer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
