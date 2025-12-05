import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Session preview data for dashboard
class SessionPreview {
  final String clientName;
  final String clientInitials;
  final String? profilePhotoUrl;
  final DateTime scheduledTime;
  final bool isCompleted;

  const SessionPreview({
    required this.clientName,
    required this.clientInitials,
    this.profilePhotoUrl,
    required this.scheduledTime,
    this.isCompleted = false,
  });
}

/// Today's sessions preview card
class TodaySessionsCard extends StatelessWidget {
  final List<SessionPreview> sessions;
  final VoidCallback onViewAll;
  final void Function(SessionPreview session) onSessionTap;

  const TodaySessionsCard({
    required this.sessions,
    required this.onViewAll,
    required this.onSessionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Sessions",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (sessions.isEmpty)
              _buildEmptyState(context)
            else
              ...sessions.take(3).map(
                    (session) => _buildSessionItem(context, session),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No sessions scheduled for today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, SessionPreview session) {
    final timeString = _formatTime(session.scheduledTime);

    return InkWell(
      onTap: () => onSessionTap(session),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(session),
            const SizedBox(width: AppSpacing.md),

            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.clientName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    timeString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral700,
                        ),
                  ),
                ],
              ),
            ),

            // Status
            if (session.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Done',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.neutral500,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(SessionPreview session) {
    if (session.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(session.profilePhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        session.clientInitials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
