import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../client_management/domain/entities/client_entity.dart';

/// Recent clients preview card for dashboard
class RecentClientsCard extends StatelessWidget {
  final List<ClientEntity> clients;
  final VoidCallback onViewAll;
  final void Function(ClientEntity client) onClientTap;

  const RecentClientsCard({
    required this.clients,
    required this.onViewAll,
    required this.onClientTap,
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
                  'Recent Clients',
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
            if (clients.isEmpty)
              _buildEmptyState(context)
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: clients.length > 5 ? 5 : clients.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _buildClientChip(context, clients[index]);
                  },
                ),
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
              Icons.people_outline,
              size: 48,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No clients yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientChip(BuildContext context, ClientEntity client) {
    return InkWell(
      onTap: () => onClientTap(client),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar(client),
            const SizedBox(height: AppSpacing.xs),
            Text(
              client.name.split(' ').first,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ClientEntity client) {
    if (client.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(client.profilePhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        client.initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
