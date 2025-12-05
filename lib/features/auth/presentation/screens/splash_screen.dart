import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/models/user_role.dart';
import '../providers/auth_provider.dart';

/// Splash screen shown on app startup
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Small delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          if (user.role == UserRole.trainer) {
            context.go(Routes.trainerHome);
          } else {
            context.go(Routes.clientHome);
          }
        } else {
          context.go(Routes.login);
        }
      },
      loading: () {
        // Wait for auth state to resolve
      },
      error: (_, __) {
        context.go(Routes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            if (user.role == UserRole.trainer) {
              context.go(Routes.trainerHome);
            } else {
              context.go(Routes.clientHome);
            }
          } else {
            context.go(Routes.login);
          }
        },
        loading: () {},
        error: (_, __) {
          context.go(Routes.login);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.neutralWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // App name
            Text(
              'FitLog Pro',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Tagline
            Text(
              'AI-Powered Personal Training',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.neutralWhite.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutralWhite),
            ),
          ],
        ),
      ),
    );
  }
}
