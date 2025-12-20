import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/notification_service.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Report type selector
          _ReportTypeSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
              });
              _generateReport();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Highlights
          if (report.highlights.isNotEmpty) ...[
            _HighlightsSection(highlights: report.highlights),
            const SizedBox(height: AppSpacing.lg),
          ],
          // Report content
          _ReportContentCard(report: report),
          const SizedBox(height: AppSpacing.lg),
          // Trainer comment
          _TrainerCommentSection(
            controller: _commentController,
            initialComment: report.trainerComment,
            onSave: () {
              ref.read(reportGenerationProvider.notifier)
                  .updateComment(_commentController.text);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
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
            // Secondary actions
            Row(
              children: [
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
                const SizedBox(width: AppSpacing.sm),
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
                    label: const Text('Share'),
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
    // TODO: Implement native share
    _copyToClipboard(report.content);
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
          Text(
            report.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
              height: 1.6,
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
