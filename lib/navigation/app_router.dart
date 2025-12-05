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
            builder: (context, state) => const TrainerHomePlaceholder(),
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
        path: Routes.trainerClientDetail,
        name: RouteNames.trainerClientDetail,
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          return ClientDetailScreen(clientId: clientId);
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
            builder: (context, state) => const ClientHomePlaceholder(),
          ),
          GoRoute(
            path: Routes.clientRecord,
            name: RouteNames.clientRecord,
            builder: (context, state) => const ClientRecordPlaceholder(),
          ),
          GoRoute(
            path: Routes.clientStats,
            name: RouteNames.clientStats,
            builder: (context, state) => const ClientStatsPlaceholder(),
          ),
          GoRoute(
            path: Routes.clientProfile,
            name: RouteNames.clientProfile,
            builder: (context, state) => const ClientProfilePlaceholder(),
          ),
        ],
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

// Placeholder screens - will be replaced with actual implementations
class TrainerHomePlaceholder extends StatelessWidget {
  const TrainerHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Trainer Home'));
}

class TrainerAcademyPlaceholder extends StatelessWidget {
  const TrainerAcademyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Trainer Academy'));
}

class TrainerProfilePlaceholder extends StatelessWidget {
  const TrainerProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Trainer Profile'));
}

class ClientHomePlaceholder extends StatelessWidget {
  const ClientHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Client Today'));
}

class ClientRecordPlaceholder extends StatelessWidget {
  const ClientRecordPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Client Record'));
}

class ClientStatsPlaceholder extends StatelessWidget {
  const ClientStatsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Client Stats'));
}

class ClientProfilePlaceholder extends StatelessWidget {
  const ClientProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('Client Profile'));
}
