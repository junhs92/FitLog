import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/notification_service.dart';
import '../../../muscle_map/presentation/providers/muscle_activity_provider.dart';
import '../../../muscle_map/presentation/widgets/report_muscle_map.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../../../active_session/presentation/widgets/achievement_card.dart';
import '../../domain/entities/session_report.dart';
import '../providers/report_provider.dart';

/// Screen for viewing and sharing a session report
class ReportViewScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? reportId;

  const ReportViewScreen({
    required this.sessionId,
    this.reportId,
    super.key,
  });

  @override
  ConsumerState<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends ConsumerState<ReportViewScreen> {
  ReportType _selectedType = ReportType.summary;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.reportId != null) {
        ref.read(reportGenerationProvider.notifier).loadReport(widget.reportId!);
      } else {
        _generateReport();
      }
    });
  }

  void _generateReport() {
    ref.read(reportGenerationProvider.notifier).generateReport(
          sessionId: widget.sessionId,
          type: _selectedType,
          trainerComment: _commentController.text.isEmpty
              ? null
              : _commentController.text,
        );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportGenerationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('세션 리포트'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          if (state.report != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyToClipboard(state.report!.content),
              tooltip: '복사',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!)
              : state.report == null
                  ? _buildEmpty()
                  : _buildContent(state.report!),
      bottomNavigationBar: state.report != null
          ? _buildBottomActions(state.report!)
          : null,
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
              onPressed: _generateReport,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('리포트를 생성할 수 없습니다'),
    );
  }

  Widget _buildContent(SessionReportEntity report) {
    return _buildVisualReportCard(report);
  }

  Widget _buildVisualReportCard(SessionReportEntity report) {
    final visualDataAsync = ref.watch(visualReportDataProvider(widget.sessionId));

    return visualDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('데이터를 불러올 수 없습니다')),
      data: (visualData) {
        if (visualData == null) {
          return const Center(child: Text('세션 데이터가 없습니다'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Gradient Header
              _ReportHeader(report: report, stats: visualData.stats),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid with actual data
                    _StatsGridFromData(stats: visualData.stats),
                    const SizedBox(height: AppSpacing.lg),

                    // Achievements Section
                    _AchievementsSection(sessionId: widget.sessionId),

                    // Highlights Section
                    if (report.highlights.isNotEmpty) ...[
                      _VisualHighlightsSection(highlights: report.highlights),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Exercise List
                    _ExerciseListSection(exercises: visualData.exercises),
                    const SizedBox(height: AppSpacing.lg),

                    // Muscle Map
                    _MuscleMapSection(sessionId: widget.sessionId),
                    const SizedBox(height: AppSpacing.lg),

                    // Trainer Comment Section
                    if (report.trainerComment != null &&
                        report.trainerComment!.isNotEmpty)
                      _TrainerMessageCard(comment: report.trainerComment!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(SessionReportEntity report) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary action row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeliveryOptions(report),
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Client'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Secondary actions - first row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generateAndShareLink(report),
                    icon: const Icon(Icons.link),
                    label: const Text('Share Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generatePdf(report),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Secondary actions - second row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendViaKakao(report),
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text('KakaoTalk'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(report),
                    icon: const Icon(Icons.share),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryOptions(SessionReportEntity report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryOptionsSheet(
        sessionId: widget.sessionId,
        report: report,
        trainerComment: _commentController.text,
        onDeliveryComplete: (method, success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Report sent successfully via $method!'
                    : 'Failed to send report',
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(SessionReportEntity report) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      await ref.read(reportGenerationProvider.notifier).generatePdf();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사됨'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _sendViaKakao(SessionReportEntity report) {
    ref.read(reportGenerationProvider.notifier).sendReport('kakao');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('카카오톡으로 전송됨'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareReport(SessionReportEntity report) {
    _copyToClipboard(report.content);
  }

  Future<void> _generateAndShareLink(SessionReportEntity report) async {
    final messenger = ScaffoldMessenger.of(context);

    // Check if we already have an HTML URL
    if (report.htmlUrl != null && report.htmlUrl!.isNotEmpty) {
      await Share.share(
        '${report.title}\n\n${report.htmlUrl}',
        subject: report.title,
      );
      return;
    }

    // Generate new HTML report
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Creating shareable link...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final htmlUrl = await ref.read(reportGenerationProvider.notifier).generateHtmlReport();

      messenger.hideCurrentSnackBar();

      if (htmlUrl != null) {
        await Share.share(
          '${report.title}\n\n$htmlUrl',
          subject: report.title,
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to generate shareable link'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ReportTypeSelector extends StatelessWidget {
  final ReportType selectedType;
  final Function(ReportType) onTypeSelected;

  const _ReportTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(
          type: ReportType.summary,
          isSelected: selectedType == ReportType.summary,
          onTap: () => onTypeSelected(ReportType.summary),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          type: ReportType.full,
          isSelected: selectedType == ReportType.full,
          onTap: () => onTypeSelected(ReportType.full),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          type: ReportType.kakaoTalk,
          isSelected: selectedType == ReportType.kakaoTalk,
          onTap: () => onTypeSelected(ReportType.kakaoTalk),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.neutral200,
            ),
          ),
          child: Text(
            type.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
            ),
          ),
        ),
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
        const Text(
          '하이라이트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
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

/// Section showing muscles worked in the session
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
        return ReportMuscleMap(sessionActivity: activity);
      },
    );
  }
}

/// Section showing auto-detected achievements for the session
class _AchievementsSection extends ConsumerWidget {
  final String sessionId;

  const _AchievementsSection({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(sessionAchievementsProvider(sessionId));

    return achievementsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AchievementSection(achievements: achievements),
        );
      },
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
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(highlight.type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            highlight.displayTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getColor(),
            ),
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
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              _StatusBadge(status: report.status),
            ],
          ),
          const Divider(height: 24),
          MarkdownBody(
            data: report.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
              h2: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              h3: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral800,
              ),
              p: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
                height: 1.6,
              ),
              listBullet: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
              ),
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

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReportStatus.draft:
        color = AppColors.neutral500;
        break;
      case ReportStatus.generated:
        color = AppColors.primary;
        break;
      case ReportStatus.sent:
        color = AppColors.success;
        break;
      case ReportStatus.viewed:
        color = AppColors.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _TrainerCommentSection extends StatelessWidget {
  final TextEditingController controller;
  final String? initialComment;
  final VoidCallback onSave;

  const _TrainerCommentSection({
    required this.controller,
    this.initialComment,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.text.isEmpty && initialComment != null) {
      controller.text = initialComment!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '트레이너 코멘트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '클라이언트에게 전달할 메시지를 작성하세요...',
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save),
              onPressed: onSave,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for delivery options
class _DeliveryOptionsSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final SessionReportEntity report;
  final String? trainerComment;
  final void Function(String method, bool success) onDeliveryComplete;

  const _DeliveryOptionsSheet({
    required this.sessionId,
    required this.report,
    this.trainerComment,
    required this.onDeliveryComplete,
  });

  @override
  ConsumerState<_DeliveryOptionsSheet> createState() => _DeliveryOptionsSheetState();
}

class _DeliveryOptionsSheetState extends ConsumerState<_DeliveryOptionsSheet> {
  bool _sendEmail = true;
  bool _sendNotification = true;
  bool _includePdf = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Send Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Options
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Email option
                _DeliveryOption(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: 'Send report via email with highlights',
                  value: _sendEmail,
                  onChanged: (v) => setState(() => _sendEmail = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Push notification option
                _DeliveryOption(
                  icon: Icons.notifications,
                  title: 'Push Notification',
                  subtitle: 'Send in-app notification to client',
                  value: _sendNotification,
                  onChanged: (v) => setState(() => _sendNotification = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                // PDF attachment option
                _DeliveryOption(
                  icon: Icons.picture_as_pdf,
                  title: 'Include PDF',
                  subtitle: 'Generate and attach PDF report',
                  value: _includePdf,
                  onChanged: (v) => setState(() => _includePdf = v),
                  enabled: _sendEmail,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Send button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neutralWhite,
                        ),
                      )
                    : const Text(
                        'Send Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReport() async {
    if (!_sendEmail && !_sendNotification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one delivery method'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(reportGenerationProvider.notifier);

      // Generate PDF if needed
      String? pdfUrl;
      if (_includePdf && _sendEmail) {
        pdfUrl = await notifier.generatePdf();
      }

      // Send email if selected
      if (_sendEmail) {
        await notifier.sendReportEmail(
          trainerNotes: widget.trainerComment,
          pdfUrl: pdfUrl,
        );
      }

      // Send notification if selected
      if (_sendNotification) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.sendReportReadyNotification(
          clientId: widget.report.clientId,
          sessionId: widget.sessionId,
          sessionDate: widget.report.generatedAt.toString(),
          pdfUrl: pdfUrl,
        );
      }

      setState(() => _isLoading = false);

      final methods = <String>[];
      if (_sendEmail) methods.add('email');
      if (_sendNotification) methods.add('notification');

      widget.onDeliveryComplete(methods.join(' & '), true);
    } catch (e) {
      setState(() => _isLoading = false);
      widget.onDeliveryComplete('', false);
    }
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.neutral200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? AppColors.primary : AppColors.neutral500,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value ? AppColors.primary : AppColors.neutralBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual Report Header with gradient background
class _ReportHeader extends StatelessWidget {
  final SessionReportEntity report;
  final VisualReportStats? stats;

  const _ReportHeader({required this.report, this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDate(stats?.sessionDate ?? report.generatedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (stats != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.timer, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${stats!.durationMinutes}분',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats Grid using actual data from provider
class _StatsGridFromData extends StatelessWidget {
  final VisualReportStats stats;

  const _StatsGridFromData({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운동 통계',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                value: '${stats.exerciseCount}',
                label: '운동',
                color: const Color(0xFF667eea),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.repeat,
                value: '${stats.totalSets}',
                label: '세트',
                color: const Color(0xFF764ba2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                value: _formatVolume(stats.totalVolume),
                label: '총 볼륨',
                color: const Color(0xFFf093fb),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.numbers,
                value: '${stats.totalReps}',
                label: '총 반복',
                color: const Color(0xFF4facfe),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }
}

/// Exercise List Section showing all exercises with details
class _ExerciseListSection extends StatelessWidget {
  final List<VisualReportExercise> exercises;

  const _ExerciseListSection({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운동 내역',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        const SizedBox(height: 12),
        ...exercises.map((e) => _ExerciseDetailCard(exercise: e)),
      ],
    );
  }
}

/// Individual exercise card with sets and comparison
class _ExerciseDetailCard extends StatelessWidget {
  final VisualReportExercise exercise;

  const _ExerciseDetailCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                ),
                // Show comparison badge
                if (exercise.volumeChange != null) _buildChangeBadge(),
              ],
            ),
          ),
          // Sets Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row
                const Row(
                  children: [
                    SizedBox(width: 40, child: Text('세트', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral500))),
                    Expanded(child: Text('무게', textAlign: TextAlign.center, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral500))),
                    Expanded(child: Text('반복', textAlign: TextAlign.center, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral500))),
                    SizedBox(width: 50, child: Text('RPE', textAlign: TextAlign.center, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral500))),
                  ],
                ),
                const Divider(height: 16),
                // Set rows
                ...exercise.sets.map((set) => _buildSetRow(set)),
              ],
            ),
          ),
          // Trainer Comments Section (if any)
          if (exercise.hasTrainerComments)
            _ExerciseTrainerCommentsSection(
              comments: exercise.trainerComments,
              memo: exercise.trainerMemo,
            ),
          // Summary footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('볼륨', _formatWeight(exercise.totalVolume)),
                _buildSummaryItem('최대 무게', '${_formatWeight(exercise.maxWeight)}kg'),
                _buildSummaryItem('총 반복', '${exercise.totalReps}회'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBadge() {
    final change = exercise.volumeChange!;
    final isPositive = change >= 0;
    final color = isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${change.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(VisualReportSet set) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Text(
                  '${set.setNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (set.isPR) ...[
                  const SizedBox(width: 4),
                  const Text('🏆', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${_formatWeight(set.weight)}kg',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              '${set.reps}회',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              set.rpe != null ? set.rpe!.toStringAsFixed(0) : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: set.rpe != null ? _getRpeColor(set.rpe!) : AppColors.neutral400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667eea),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }

  String _formatWeight(double weight) {
    return weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1);
  }

  Color _getRpeColor(double rpe) {
    if (rpe >= 9) return const Color(0xFFef4444);
    if (rpe >= 7) return const Color(0xFFf59e0b);
    return const Color(0xFF10b981);
  }
}

/// Trainer comments section for individual exercise
class _ExerciseTrainerCommentsSection extends StatelessWidget {
  final List<VisualReportTrainerComment> comments;
  final String? memo;

  const _ExerciseTrainerCommentsSection({required this.comments, this.memo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.comment,
                size: 16,
                color: const Color(0xFF667eea),
              ),
              const SizedBox(width: 6),
              const Text(
                '트레이너 코멘트',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: comments.map((c) => _TrainerCommentChip(comment: c)).toList(),
            ),
          ],
          if (memo != null && memo!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note, size: 16, color: Color(0xFF667eea)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    memo!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual trainer comment chip
class _TrainerCommentChip extends StatelessWidget {
  final VisualReportTrainerComment comment;

  const _TrainerCommentChip({required this.comment});

  Color get _chipColor {
    // Determine color based on comment key/category
    final key = comment.key.toLowerCase();
    if (key.contains('pain') || key.contains('fatigue') || key.contains('weak') ||
        key.contains('breakdown') || key.contains('issue') || key.contains('loss')) {
      return const Color(0xFFef4444); // Red for condition/warning
    } else if (key.contains('squeeze') || key.contains('feel') || key.contains('mind') ||
        key.contains('control') || key.contains('explosive') || key.contains('breathe') ||
        key.contains('rom') || key.contains('pause')) {
      return const Color(0xFF10b981); // Green for coaching cues
    } else {
      return const Color(0xFFf59e0b); // Amber for common mistakes
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            comment.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        // Show detail below chip if exists
        if (comment.detail != null && comment.detail!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              '→ ${comment.detail}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Visual highlights section with beautiful cards
class _VisualHighlightsSection extends StatelessWidget {
  final List<ReportHighlight> highlights;

  const _VisualHighlightsSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 하이라이트',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        const SizedBox(height: 12),
        ...highlights.map((h) => _VisualHighlightCard(highlight: h)),
      ],
    );
  }
}

/// Individual highlight card with gradient border
class _VisualHighlightCard extends StatelessWidget {
  final ReportHighlight highlight;

  const _VisualHighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  highlight.type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (highlight.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      highlight.displayDescription,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    switch (highlight.type) {
      case HighlightType.pr:
        return const Color(0xFFf59e0b);
      case HighlightType.improvement:
        return const Color(0xFF10b981);
      case HighlightType.consistency:
        return const Color(0xFF667eea);
      case HighlightType.effort:
        return const Color(0xFFec4899);
      case HighlightType.milestone:
        return const Color(0xFF8b5cf6);
      case HighlightType.caution:
        return const Color(0xFFef4444);
    }
  }
}

/// Trainer message card
class _TrainerMessageCard extends StatelessWidget {
  final String comment;

  const _TrainerMessageCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.1),
            const Color(0xFF764ba2).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667eea).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.message,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '트레이너 코멘트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.neutral700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
