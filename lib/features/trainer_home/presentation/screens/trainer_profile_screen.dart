import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../client_management/presentation/providers/client_provider.dart';
import '../../../../navigation/routes.dart';

class TrainerProfileScreen extends ConsumerWidget {
  const TrainerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('내 프로필'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  _ProfileHeader(user: user),
                  const SizedBox(height: AppSpacing.xl),

                  // Stats section
                  _SectionLabel(label: '통계'),
                  const SizedBox(height: AppSpacing.sm),
                  _StatsCard(clientsAsync: clientsAsync),
                  const SizedBox(height: AppSpacing.xl),

                  // Settings section
                  _SectionLabel(label: '설정'),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsCard(
                    items: [
                      _SettingsItem(
                        icon: Icons.fitness_center_outlined,
                        label: '내 운동 템플릿',
                        onTap: () => context.go(Routes.trainerTemplates),
                      ),
                      _SettingsItem(
                        icon: Icons.school_outlined,
                        label: '아카데미',
                        onTap: () => context.go(Routes.trainerAcademy),
                      ),
                      _SettingsItem(
                        icon: Icons.settings_outlined,
                        label: '설정',
                        onTap: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Account section
                  _SectionLabel(label: '계정'),
                  const SizedBox(height: AppSpacing.sm),
                  _LogoutButton(
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(Routes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.neutralWhite,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.initials as String;
    final displayName = user.displayName as String;
    final email = user.email as String;

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary,
          backgroundImage: user.profilePhotoUrl != null
              ? NetworkImage(user.profilePhotoUrl as String)
              : null,
          child: user.profilePhotoUrl == null
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralWhite,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AsyncValue<dynamic> clientsAsync;

  const _StatsCard({required this.clientsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '활성 회원 수',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 2),
              clientsAsync.when(
                data: (clients) => Text(
                  '${(clients as List).length}명',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsRow(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg,
                endIndent: 0,
                color: AppColors.neutral200,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _SettingsRow extends StatelessWidget {
  final _SettingsItem item;

  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.neutral700, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.neutralBlack,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.logout, color: AppColors.error, size: 22),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
