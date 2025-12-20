import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/client_management/presentation/screens/add_client_screen.dart';
import '../features/client_management/presentation/screens/client_detail_screen.dart';
import '../features/client_management/presentation/screens/clients_list_screen.dart';
import '../features/client_management/presentation/screens/connect_client_screen.dart';
import '../features/client_management/presentation/screens/create_invite_screen.dart';
import '../features/trainer_home/presentation/screens/trainer_home_screen.dart';
import '../features/active_session/presentation/screens/active_session_screen.dart';
import '../features/active_session/presentation/screens/session_summary_screen.dart';
import '../features/ai_workout/presentation/screens/generate_program_screen.dart';
import '../features/ai_workout/presentation/screens/program_review_screen.dart';
import '../features/ai_report/presentation/screens/report_view_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_home_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_record_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_stats_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_profile_screen.dart';
import '../features/lifestyle_log/presentation/screens/accept_invite_screen.dart';
import '../shared/models/user_role.dart';
import 'routes.dart';

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.splash;

      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return Routes.login;
      }

      // If logged in and on auth route, redirect to appropriate home
      if (isLoggedIn && isAuthRoute) {
        final user = authState.valueOrNull;
        if (user?.role == UserRole.trainer) {
          return Routes.trainerHome;
        } else {
          return Routes.clientHome;
        }
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Trainer routes (shell for bottom navigation)
      ShellRoute(
        builder: (context, state, child) {
          return TrainerShell(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.trainerHome,
            name: RouteNames.trainerHome,
            builder: (context, state) => const TrainerHomeScreen(),
          ),
          GoRoute(
            path: Routes.trainerClients,
            name: RouteNames.trainerClients,
            builder: (context, state) => const ClientsListScreen(),
          ),
          GoRoute(
            path: Routes.trainerAcademy,
            name: RouteNames.trainerAcademy,
            builder: (context, state) => const TrainerAcademyPlaceholder(),
          ),
          GoRoute(
            path: Routes.trainerProfile,
            name: RouteNames.trainerProfile,
            builder: (context, state) => const TrainerProfilePlaceholder(),
          ),
        ],
      ),

      // Trainer client management routes (full page, no bottom nav)
      GoRoute(
        path: Routes.trainerClientAdd,
        name: RouteNames.trainerClientAdd,
        builder: (context, state) => const AddClientScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientConnect,
        name: RouteNames.trainerClientConnect,
        builder: (context, state) => const ConnectClientScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientInvite,
        name: RouteNames.trainerClientInvite,
        builder: (context, state) => const CreateInviteScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientDetail,
        name: RouteNames.trainerClientDetail,
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          return ClientDetailScreen(clientId: clientId);
        },
      ),

      // Active session route
      GoRoute(
        path: Routes.trainerSession,
        name: RouteNames.trainerSession,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          return ActiveSessionScreen(
            clientId: clientId,
            clientName: clientName,
          );
        },
      ),

      // Session summary route
      GoRoute(
        path: Routes.trainerSessionSummary,
        name: RouteNames.trainerSessionSummary,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return SessionSummaryScreen(sessionId: sessionId);
        },
      ),

      // AI Program generation route
      GoRoute(
        path: Routes.trainerProgramGenerate,
        name: RouteNames.trainerProgramGenerate,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final trainerId = state.uri.queryParameters['trainerId'] ?? '';
          return GenerateProgramScreen(
            clientId: clientId,
            trainerId: trainerId,
            clientName: clientName,
          );
        },
      ),

      // AI Program review route
      GoRoute(
        path: Routes.trainerProgramReview,
        name: RouteNames.trainerProgramReview,
        builder: (context, state) {
          final programId = state.pathParameters['programId']!;
          final clientId = state.uri.queryParameters['clientId'] ?? '';
          return ProgramReviewScreen(
            programId: programId,
            clientId: clientId,
          );
        },
      ),

      // AI Report view route
      GoRoute(
        path: Routes.trainerReport,
        name: RouteNames.trainerReport,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ReportViewScreen(sessionId: sessionId);
        },
      ),

      // Client routes (shell for bottom navigation)
      ShellRoute(
        builder: (context, state, child) {
          return ClientShell(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.clientHome,
            name: RouteNames.clientHome,
            builder: (context, state) => const _ClientHomeWrapper(),
          ),
          GoRoute(
            path: Routes.clientRecord,
            name: RouteNames.clientRecord,
            builder: (context, state) => const _ClientRecordWrapper(),
          ),
          GoRoute(
            path: Routes.clientStats,
            name: RouteNames.clientStats,
            builder: (context, state) => const _ClientStatsWrapper(),
          ),
          GoRoute(
            path: Routes.clientProfile,
            name: RouteNames.clientProfile,
            builder: (context, state) => const _ClientProfileWrapper(),
          ),
        ],
      ),

      // Client invite acceptance routes (outside shell)
      GoRoute(
        path: Routes.clientAcceptInvite,
        name: RouteNames.clientAcceptInvite,
        builder: (context, state) => const AcceptInviteScreen(),
      ),
      GoRoute(
        path: Routes.clientAcceptInviteWithCode,
        name: RouteNames.clientAcceptInviteWithCode,
        builder: (context, state) {
          final code = state.pathParameters['code'];
          return AcceptInviteScreen(code: code);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

// Placeholder shells - will be replaced with actual implementations
class TrainerShell extends StatelessWidget {
  final Widget child;

  const TrainerShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Clients'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Academy'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(Routes.trainerHome);
              break;
            case 1:
              context.go(Routes.trainerClients);
              break;
            case 2:
              context.go(Routes.trainerAcademy);
              break;
            case 3:
              context.go(Routes.trainerProfile);
              break;
          }
        },
      ),
    );
  }
}

class ClientShell extends StatelessWidget {
  final Widget child;

  const ClientShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Record'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(Routes.clientHome);
              break;
            case 1:
              context.go(Routes.clientRecord);
              break;
            case 2:
              context.go(Routes.clientStats);
              break;
            case 3:
              context.go(Routes.clientProfile);
              break;
          }
        },
      ),
    );
  }
}

// Trainer placeholder screens - will be replaced with actual implementations
class TrainerAcademyPlaceholder extends StatelessWidget {
  const TrainerAcademyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Trainer Academy'));
}

class TrainerProfilePlaceholder extends ConsumerWidget {
  const TrainerProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Trainer Profile', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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
                context.go(Routes.login);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// Client screen wrappers - inject clientId from auth state
class _ClientHomeWrapper extends ConsumerWidget {
  const _ClientHomeWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClientHomeScreen(clientId: user.id);
  }
}

class _ClientRecordWrapper extends ConsumerWidget {
  const _ClientRecordWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClientRecordScreen(clientId: user.id);
  }
}

class _ClientStatsWrapper extends ConsumerWidget {
  const _ClientStatsWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClientStatsScreen(clientId: user.id);
  }
}

class _ClientProfileWrapper extends ConsumerWidget {
  const _ClientProfileWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClientProfileScreen(clientId: user.id);
  }
}
