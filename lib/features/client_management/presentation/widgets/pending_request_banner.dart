import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/connection_request_entity.dart';
import '../providers/connection_request_provider.dart';

/// Banner widget showing pending connection requests for clients
class PendingRequestBanner extends ConsumerStatefulWidget {
  const PendingRequestBanner({super.key});

  @override
  ConsumerState<PendingRequestBanner> createState() => _PendingRequestBannerState();
}

class _PendingRequestBannerState extends ConsumerState<PendingRequestBanner> {
  @override
  void initState() {
    super.initState();
    // Load pending requests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionRequestProvider.notifier).loadPendingRequests();
    });
  }

  Future<void> _acceptRequest(ConnectionRequestEntity request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Connection'),
        content: Text(
          'Accept connection from ${request.trainerName ?? "this trainer"}?\n\n'
          'They will be able to view your health records and create workout programs for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(connectionRequestProvider.notifier)
        .acceptRequest(request.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected with ${request.trainerName ?? "trainer"}'
                : 'Failed to accept request',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectRequest(ConnectionRequestEntity request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text(
          'Reject connection request from ${request.trainerName ?? "this trainer"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(connectionRequestProvider.notifier)
        .rejectRequest(request.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Request rejected' : 'Failed to reject request',
          ),
          backgroundColor: success ? AppColors.neutral700 : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionRequestProvider);
    final pendingRequests = state.pendingRequests;

    if (pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: pendingRequests.map((request) => _RequestCard(
        request: request,
        onAccept: () => _acceptRequest(request),
        onReject: () => _rejectRequest(request),
      )).toList(),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ConnectionRequestEntity request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Trainer Connection Request',
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: request.trainerAvatarUrl != null
                      ? NetworkImage(request.trainerAvatarUrl!)
                      : null,
                  child: request.trainerAvatarUrl == null
                      ? Text(
                          request.trainerInitials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.trainerName ?? 'Trainer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (request.trainerEmail != null)
                        Text(
                          request.trainerEmail!,
                          style: TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
