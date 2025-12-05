import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/client_entity.dart';

/// Client list item card widget
class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback? onTap;
  final VoidCallback? onSessionTap;

  const ClientCard({
    required this.client,
    this.onTap,
    this.onSessionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: AppSpacing.lg),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (client.goals.isNotEmpty)
                      Text(
                        client.goalsText,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (client.phone != null || client.email != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          client.phone ?? client.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral500,
                              ),
                        ),
                      ),
                  ],
                ),
              ),

              // Start session button
              if (onSessionTap != null)
                IconButton(
                  onPressed: onSessionTap,
                  icon: const Icon(Icons.play_circle_outline),
                  color: AppColors.primary,
                  tooltip: 'Start Session',
                ),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (client.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(client.profilePhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 24,
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
