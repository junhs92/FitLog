import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/client_profile_provider.dart';

/// Client profile screen
class ClientProfileScreen extends ConsumerWidget {
  final String clientId;

  const ClientProfileScreen({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider(clientId));
    final statsAsync = ref.watch(clientStatsProvider(clientId));
    final trainerAsync = ref.watch(assignedTrainerProvider(clientId));

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: profileAsync.when(
                    data: (profile) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.neutralWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neutralWhite,
                              width: 3,
                            ),
                          ),
                          child: profile?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile?.displayName ?? 'Client User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralWhite,
                          ),
                        ),
                        Text(
                          profile != null && profile.weeksSinceJoined > 4
                              ? 'Active Member'
                              : 'New Member',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutralWhite,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (_, __) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 48, color: Colors.white),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Client User',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutralWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Profile Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          value: '${stats.sessionCount}',
                          label: 'Sessions',
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickStatCard(
                          value: '${stats.consistencyPercent}%',
                          label: 'Consistency',
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickStatCard(
                          value: '${stats.weeksSinceJoined}',
                          label: 'Weeks',
                          icon: Icons.calendar_month,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Row(
                    children: [
                      Expanded(child: _QuickStatCard(value: '-', label: 'Sessions', icon: Icons.fitness_center)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickStatCard(value: '-', label: 'Consistency', icon: Icons.trending_up)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickStatCard(value: '-', label: 'Weeks', icon: Icons.calendar_month)),
                    ],
                  ),
                  error: (_, __) => const Row(
                    children: [
                      Expanded(child: _QuickStatCard(value: '0', label: 'Sessions', icon: Icons.fitness_center)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickStatCard(value: '0%', label: 'Consistency', icon: Icons.trending_up)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickStatCard(value: '0', label: 'Weeks', icon: Icons.calendar_month)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Account Section
                _SectionHeader(title: 'Account'),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Personal Info',
                  subtitle: 'Name, email, phone',
                  onTap: () => _showPersonalInfoSheet(context, profileAsync.value),
                ),
                _ProfileMenuItem(
                  icon: Icons.flag_outlined,
                  title: 'Goals',
                  subtitle: 'Fitness and health targets',
                  onTap: () => _showGoalsSheet(context, profileAsync.value),
                ),
                _ProfileMenuItem(
                  icon: Icons.medical_information_outlined,
                  title: 'Health Profile',
                  subtitle: 'Medical info, allergies',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.lg),
                // Trainer Section
                _SectionHeader(title: 'My Trainer'),
                const SizedBox(height: AppSpacing.sm),
                _TrainerSection(trainerAsync: trainerAsync),
                const SizedBox(height: AppSpacing.lg),
                // Settings Section
                _SectionHeader(title: 'Settings'),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Push, email, reminders',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  subtitle: 'Data sharing, visibility',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme, units',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.lg),
                // Support Section
                _SectionHeader(title: 'Support'),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contact Support',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.lg),
                // Logout Button
                _LogoutButton(onTap: () => _showLogoutDialog(context, ref)),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, ClientProfile? profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(label: 'Name', value: profile?.displayName ?? 'Not set'),
              _InfoRow(label: 'Email', value: profile?.email ?? 'Not set'),
              _InfoRow(label: 'Phone', value: profile?.phone ?? 'Not set'),
              _InfoRow(label: 'Date of Birth', value: profile?.formattedDateOfBirth ?? 'Not specified'),
              _InfoRow(label: 'Gender', value: profile?.formattedGender ?? 'Not specified'),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalsSheet(BuildContext context, ClientProfile? profile) {
    final goals = profile?.fitnessGoals ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'My Goals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No goals set yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ),
                )
              else
                ...goals.map((goal) => _GoalItem(
                  icon: _getGoalIcon(goal),
                  title: goal,
                  progress: 0.0, // Progress tracking not yet implemented
                )),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Edit Goals'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(String goal) {
    final lowerGoal = goal.toLowerCase();
    if (lowerGoal.contains('muscle') || lowerGoal.contains('strength')) {
      return Icons.fitness_center;
    }
    if (lowerGoal.contains('weight') || lowerGoal.contains('kg')) {
      return Icons.monitor_weight;
    }
    if (lowerGoal.contains('water') || lowerGoal.contains('hydra')) {
      return Icons.water_drop;
    }
    if (lowerGoal.contains('sleep')) {
      return Icons.bedtime;
    }
    if (lowerGoal.contains('cardio') || lowerGoal.contains('run')) {
      return Icons.directions_run;
    }
    return Icons.flag;
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.neutralBlack,
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _QuickStatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
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
          ),
        ),
      ),
    );
  }
}

class _TrainerSection extends StatelessWidget {
  final AsyncValue<TrainerInfo?> trainerAsync;

  const _TrainerSection({required this.trainerAsync});

  @override
  Widget build(BuildContext context) {
    return trainerAsync.when(
      data: (trainer) {
        if (trainer == null) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: const Center(
              child: Text(
                'No trainer assigned yet',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral500,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: trainer.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          trainer.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const Text(
                      'Personal Trainer',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: trainer.status == 'active'
                              ? AppColors.success
                              : AppColors.neutral400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trainer.status == 'active' ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: trainer.status == 'active'
                                ? AppColors.success
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Center(
          child: Text(
            'No trainer assigned yet',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final double progress;

  const _GoalItem({
    required this.icon,
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.neutral200,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
