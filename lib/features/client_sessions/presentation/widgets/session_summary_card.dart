import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../calendar/domain/entities/session_package.dart';
import '../providers/client_session_provider.dart';

/// Card showing session package summary (completed/remaining count + progress bar)
class SessionSummaryCard extends StatelessWidget {
  final ClientSessionPackageSummary summary;

  const SessionSummaryCard({
    required this.summary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: summary.warningLevel.shouldShowWarning
            ? Border.all(
                color: _getWarningColor(summary.warningLevel),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Completed sessions
              Expanded(
                child: _StatColumn(
                  value: summary.completedSessions.toString(),
                  label: 'Completed',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 40,
                color: AppColors.neutral200,
              ),
              // Remaining sessions
              Expanded(
                child: _StatColumn(
                  value: summary.hasPackage
                      ? summary.remainingSessions.toString()
                      : '-',
                  label: 'Remaining',
                  icon: Icons.schedule,
                  color: _getRemainingColor(summary),
                ),
              ),
            ],
          ),

          // Progress bar (only if has package)
          if (summary.hasPackage) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: summary.progressPercentage,
                minHeight: 8,
                backgroundColor: AppColors.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(summary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${summary.completedSessions} / ${summary.totalSessions} sessions used',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],

          // Warning message
          if (summary.warningLevel.shouldShowWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _getWarningColor(summary.warningLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: _getWarningColor(summary.warningLevel),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    summary.warningLevel.displayMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getWarningColor(summary.warningLevel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expiry date (if applicable)
          if (summary.expiresAt != null &&
              summary.warningLevel != PackageWarningLevel.expired) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Expires: ${_formatDate(summary.expiresAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getWarningColor(PackageWarningLevel level) {
    switch (level) {
      case PackageWarningLevel.none:
        return AppColors.success;
      case PackageWarningLevel.low:
        return AppColors.warning;
      case PackageWarningLevel.critical:
        return AppColors.error;
      case PackageWarningLevel.expired:
        return AppColors.error;
    }
  }

  Color _getRemainingColor(ClientSessionPackageSummary summary) {
    if (!summary.hasPackage) return AppColors.neutral500;

    switch (summary.warningLevel) {
      case PackageWarningLevel.none:
        return AppColors.primary;
      case PackageWarningLevel.low:
        return AppColors.warning;
      case PackageWarningLevel.critical:
      case PackageWarningLevel.expired:
        return AppColors.error;
    }
  }

  Color _getProgressColor(ClientSessionPackageSummary summary) {
    if (summary.progressPercentage >= 1.0) {
      return AppColors.success;
    }
    return AppColors.primary;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}
