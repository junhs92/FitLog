import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../navigation/routes.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 계정 섹션
            _SectionLabel(label: '계정'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              items: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  label: '프로필 편집',
                  onTap: () => _showComingSoonToast(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 알림 섹션
            _SectionLabel(label: '알림'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              items: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: '알림 설정',
                  onTap: () => context.push(Routes.notifications),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 앱 정보 섹션
            _SectionLabel(label: '앱 정보'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              items: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  label: '앱 버전',
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral500,
                    ),
                  ),
                  onTap: null,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: '개인정보처리방침',
                  onTap: () => _showComingSoonToast(context),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  label: '이용약관',
                  onTap: () => _showComingSoonToast(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 계정 관리 섹션
            _SectionLabel(label: '계정 관리'),
            const SizedBox(height: AppSpacing.sm),
            _LogoutTile(
              onTap: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showComingSoonToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('준비 중입니다'),
        duration: Duration(seconds: 2),
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

class _SettingsTile {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTile> items;

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
            _SettingsRow(tile: items[i]),
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

class _SettingsRow extends StatelessWidget {
  final _SettingsTile tile;

  const _SettingsRow({required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(tile.icon, color: AppColors.neutral700, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                tile.label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.neutralBlack,
                ),
              ),
            ),
            if (tile.trailing != null)
              tile.trailing!
            else if (tile.onTap != null)
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

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

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
