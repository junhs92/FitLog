import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/schedule_entry.dart';

/// Card widget displaying a schedule entry
class ScheduleCard extends StatelessWidget {
  final ScheduleEntry schedule;
  final VoidCallback? onTap;
  final void Function(ScheduleStatus)? onStatusChange;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ScheduleCard({
    required this.schedule,
    this.onTap,
    this.onStatusChange,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                      _formatTime(schedule.scheduledAt),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _getStatusColor(schedule.status),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Client name
                    Text(
                      schedule.clientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Duration and notes
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.neutral600,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          schedule.durationDisplay,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral600,
                              ),
                        ),
                        if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.note,
                            size: 14,
                            color: AppColors.neutral600,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              schedule.notes!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.neutral600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Status badge for non-scheduled
                    if (schedule.status != ScheduleStatus.scheduled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildStatusBadge(context),
                    ],
                  ],
                ),
              ),

              // Action menu - always shown for all statuses
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  // Edit is always available
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.primary, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  // Status change options only for scheduled appointments
                  if (schedule.status == ScheduleStatus.scheduled) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text('Mark as Completed'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'no_show',
                      child: Row(
                        children: [
                          Icon(Icons.person_off, color: AppColors.warning, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text('Mark as No-Show'),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
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
      height: 48,
      decoration: BoxDecoration(
        color: _getStatusColor(schedule.status),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(schedule.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        schedule.status.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(schedule.status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  Color _getStatusColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.scheduled:
        return AppColors.primary;
      case ScheduleStatus.completed:
        return AppColors.success;
      case ScheduleStatus.cancelled:
        return AppColors.neutral500;
      case ScheduleStatus.noShow:
        return AppColors.warning;
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'edit':
        onEdit?.call();
        break;
      case 'complete':
        onStatusChange?.call(ScheduleStatus.completed);
        break;
      case 'no_show':
        onStatusChange?.call(ScheduleStatus.noShow);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}

/// Small schedule indicator for agenda view header
class ScheduleIndicator extends StatelessWidget {
  final int count;
  final ScheduleStatus? primaryStatus;

  const ScheduleIndicator({
    required this.count,
    this.primaryStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$count appointment${count == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
