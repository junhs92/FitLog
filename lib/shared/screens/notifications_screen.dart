import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

/// Screen for viewing notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(ref),
            child: const Text('모두 읽음'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _NotificationCard(
                notification: notifications[index],
                onTap: () => _handleNotificationTap(context, ref, notifications[index]),
                onDismiss: () => _deleteNotification(ref, notifications[index].id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead(WidgetRef ref) {
    ref.read(notificationServiceProvider).markAllAsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity notification,
  ) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationServiceProvider).markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }

    // Navigate based on notification type
    // TODO: Implement navigation based on notification.data
  }

  void _deleteNotification(WidgetRef ref, String notificationId) {
    ref.read(notificationServiceProvider).deleteNotification(notificationId);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.neutralWhite),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: notification.isRead
              ? AppColors.surfaceElevated
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      size: 20,
                      color: _getIconColor(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: AppColors.neutralBlack,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.sessionReminder:
        return Icons.alarm;
      case NotificationType.sessionComplete:
        return Icons.check_circle;
      case NotificationType.reportReady:
        return Icons.description;
      case NotificationType.trainerMessage:
        return Icons.message;
      case NotificationType.clientLog:
        return Icons.edit_note;
      case NotificationType.lifestyleAlert:
        return Icons.warning;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.programUpdate:
        return Icons.fitness_center;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.sessionReminder:
        return AppColors.warning;
      case NotificationType.sessionComplete:
        return AppColors.success;
      case NotificationType.reportReady:
        return AppColors.primary;
      case NotificationType.trainerMessage:
        return AppColors.secondary;
      case NotificationType.clientLog:
        return AppColors.primary;
      case NotificationType.lifestyleAlert:
        return AppColors.warning;
      case NotificationType.achievement:
        return AppColors.warning;
      case NotificationType.programUpdate:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

/// Notification badge widget for app bars
class NotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;

  const NotificationBadge({
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          countAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: AppColors.neutralWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
