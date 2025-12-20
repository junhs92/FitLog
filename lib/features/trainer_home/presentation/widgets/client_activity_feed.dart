import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Activity type for client logs
enum ClientActivityType {
  meal('meal', 'Meal Logged', '식사 기록', '🍽️'),
  water('water', 'Water Logged', '수분 섭취', '💧'),
  sleep('sleep', 'Sleep Logged', '수면 기록', '😴'),
  mood('mood', 'Mood Logged', '기분 기록', '😊'),
  weight('weight', 'Weight Logged', '체중 기록', '⚖️'),
  photo('photo', 'Photo Added', '사진 추가', '📷'),
  activity('activity', 'Activity Logged', '활동 기록', '🏃');

  final String id;
  final String name;
  final String nameKo;
  final String emoji;

  const ClientActivityType(this.id, this.name, this.nameKo, this.emoji);

  String get displayName => nameKo;
}

/// Client activity entry
class ClientActivityEntry {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final ClientActivityType type;
  final String summary;
  final String? summaryKo;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  const ClientActivityEntry({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.type,
    required this.summary,
    this.summaryKo,
    this.details,
    required this.timestamp,
  });

  String get displaySummary => summaryKo ?? summary;
}

/// Provider for client activity feed
final clientActivityFeedProvider = StreamProvider.family<
    List<ClientActivityEntry>, String>((ref, trainerId) {
  final client = Supabase.instance.client;

  // Subscribe to real-time updates from multiple tables
  return client
      .from('client_activity_log')
      .stream(primaryKey: ['id'])
      .eq('trainer_id', trainerId)
      .order('timestamp', ascending: false)
      .limit(50)
      .map((data) {
        return data.map((item) {
          return ClientActivityEntry(
            id: item['id'] as String,
            clientId: item['client_id'] as String,
            clientName: item['client_name'] as String? ?? 'Client',
            clientPhotoUrl: item['client_photo_url'] as String?,
            type: ClientActivityType.values.firstWhere(
              (t) => t.id == item['type'],
              orElse: () => ClientActivityType.activity,
            ),
            summary: item['summary'] as String,
            summaryKo: item['summary_ko'] as String?,
            details: item['details'] as Map<String, dynamic>?,
            timestamp: DateTime.parse(item['timestamp'] as String),
          );
        }).toList();
      });
});

/// Widget showing real-time client activity feed
class ClientActivityFeed extends ConsumerWidget {
  final String trainerId;
  final int maxItems;
  final VoidCallback? onSeeAll;

  const ClientActivityFeed({
    required this.trainerId,
    this.maxItems = 10,
    this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clientActivityFeedProvider(trainerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dynamic_feed,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  '클라이언트 활동',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('전체 보기'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Activity list
        activityAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Error: $e'),
          ),
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(maxItems).length,
              itemBuilder: (context, index) {
                return _ActivityItem(activity: activities[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '아직 클라이언트 활동이 없습니다',
              style: TextStyle(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ClientActivityEntry activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor().withValues(alpha: 0.1),
          child: Text(
            activity.type.emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Row(
          children: [
            Text(
              activity.clientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.type.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor(),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            activity.displaySummary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Text(
          _formatTime(activity.timestamp),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (activity.type) {
      case ClientActivityType.meal:
        return const Color(0xFF81C784);
      case ClientActivityType.water:
        return const Color(0xFF64B5F6);
      case ClientActivityType.sleep:
        return const Color(0xFF9575CD);
      case ClientActivityType.mood:
        return const Color(0xFFFFB74D);
      case ClientActivityType.weight:
        return AppColors.primary;
      case ClientActivityType.photo:
        return AppColors.secondary;
      case ClientActivityType.activity:
        return AppColors.success;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '방금';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
}

/// Compact version for dashboard
class ClientActivityFeedCompact extends ConsumerWidget {
  final String trainerId;
  final VoidCallback? onTap;

  const ClientActivityFeedCompact({
    required this.trainerId,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clientActivityFeedProvider(trainerId));

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: activityAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Text('Failed to load'),
            data: (activities) {
              final recentCount = activities
                  .where((a) =>
                      DateTime.now().difference(a.timestamp).inHours < 24)
                  .length;

              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dynamic_feed,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '클라이언트 활동',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralBlack,
                          ),
                        ),
                        Text(
                          '오늘 $recentCount개의 새 활동',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.neutral400,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
