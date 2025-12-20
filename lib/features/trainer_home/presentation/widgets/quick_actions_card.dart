import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Quick action button for dashboard
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: buttonColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: buttonColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: buttonColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: buttonColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick actions section for dashboard
class QuickActionsCard extends StatelessWidget {
  final VoidCallback onStartSession;
  final VoidCallback onAddClient;
  final VoidCallback onViewClients;
  final VoidCallback? onGenerateProgram;

  const QuickActionsCard({
    required this.onStartSession,
    required this.onAddClient,
    required this.onViewClients,
    this.onGenerateProgram,
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                QuickActionButton(
                  label: 'Start Session',
                  icon: Icons.play_circle_outline,
                  onTap: onStartSession,
                  color: AppColors.success,
                ),
                QuickActionButton(
                  label: 'Add Client',
                  icon: Icons.person_add_outlined,
                  onTap: onAddClient,
                ),
                QuickActionButton(
                  label: 'View All Clients',
                  icon: Icons.people_outline,
                  onTap: onViewClients,
                  color: AppColors.secondary,
                ),
                if (onGenerateProgram != null)
                  QuickActionButton(
                    label: 'Generate Program',
                    icon: Icons.auto_awesome,
                    onTap: onGenerateProgram!,
                    color: AppColors.info,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
