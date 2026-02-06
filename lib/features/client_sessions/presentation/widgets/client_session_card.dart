import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/session_entity.dart';
import '../providers/client_session_provider.dart';

/// Card widget displaying a client's session with trainer info and report link
class ClientSessionCard extends ConsumerWidget {
  final SessionEntity session;
  final VoidCallback? onTap;
  final VoidCallback? onViewReport;

  const ClientSessionCard({
    required this.session,
    this.onTap,
    this.onViewReport,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = session.status == SessionStatus.completed;
    final sessionDate = session.scheduledAt ?? session.startedAt ?? session.createdAt;

    // Check if this session has a report
    final hasReportAsync = isCompleted
        ? ref.watch(sessionReportProvider(session.id))
        : null;

    final hasReport = hasReportAsync?.valueOrNull != null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              _buildStatusIndicator(),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time
                    Text(
                      _formatTime(sessionDate),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getStatusColor(session.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Session type/description
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _getSessionTitle(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Session stats (if completed)
                    if (isCompleted) ...[
                      Row(
                        children: [
                          // Duration
                          if (session.duration != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              session.durationDisplay,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          // Exercise count
                          if (session.savedTotalExercises != null) ...[
                            Icon(
                              Icons.list,
                              size: 14,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${session.savedTotalExercises} exercises',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Status badge or View Report button
                    Row(
                      children: [
                        // Status badge
                        _buildStatusBadge(context),

                        // View Report button (if completed and has report)
                        if (isCompleted && hasReport) ...[
                          const Spacer(),
                          TextButton.icon(
                            onPressed: onViewReport,
                            icon: const Icon(Icons.description, size: 16),
                            label: const Text('View Report'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 4,
      height: 56,
      decoration: BoxDecoration(
        color: _getStatusColor(session.status),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(session.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(session.status),
            size: 14,
            color: _getStatusColor(session.status),
          ),
          const SizedBox(width: 4),
          Text(
            session.status.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getStatusColor(session.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getSessionTitle() {
    // Use focus area or session type for title
    if (session.focusArea != null) {
      return _formatFocusArea(session.focusArea!);
    }
    if (session.sessionType != null && session.sessionType!.isNotEmpty) {
      return session.sessionType!;
    }
    return 'PT Session';
  }

  String _formatFocusArea(String focusArea) {
    final formatted = focusArea.replaceAll('_', ' ');
    if (formatted.isEmpty) return 'PT Session';
    return '${formatted[0].toUpperCase()}${formatted.substring(1)} Training';
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return AppColors.primary;
      case SessionStatus.active:
        return AppColors.secondary;
      case SessionStatus.completed:
        return AppColors.success;
      case SessionStatus.cancelled:
        return AppColors.neutral500;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Icons.event;
      case SessionStatus.active:
        return Icons.play_circle;
      case SessionStatus.completed:
        return Icons.check_circle;
      case SessionStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Empty state for no sessions on selected day
class NoSessionsForDay extends StatelessWidget {
  final DateTime date;

  const NoSessionsForDay({required this.date, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_available,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isPast ? 'No sessions recorded' : 'No sessions scheduled',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isPast
                  ? 'Past sessions will appear here'
                  : 'Sessions scheduled by your trainer will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
