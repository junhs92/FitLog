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
import '../features/client_management/presentation/screens/clients_master_detail_screen.dart';
import '../features/client_management/presentation/screens/connect_client_screen.dart';
import '../features/client_management/presentation/screens/create_invite_screen.dart';
import '../features/trainer_home/presentation/screens/trainer_home_screen.dart';
import '../features/active_session/presentation/screens/active_session_screen.dart';
import '../features/active_session/presentation/screens/previous_session_review_screen.dart';
import '../features/active_session/presentation/screens/session_summary_screen.dart';
import '../features/active_session/domain/entities/session_entity.dart';
import '../features/ai_workout/presentation/screens/generate_program_screen.dart';
import '../features/ai_workout/presentation/screens/program_review_screen.dart';
import '../features/ai_workout/presentation/screens/ai_exercise_review_screen.dart';
import '../features/ai_workout/domain/entities/workout_program.dart';
import '../features/ai_report/presentation/screens/report_view_screen.dart';
import '../features/workout_templates/presentation/screens/my_templates_screen.dart';
import '../features/workout_templates/presentation/screens/template_editor_screen.dart';
import '../features/workout_templates/presentation/screens/template_review_screen.dart';
import '../features/workout_templates/domain/entities/workout_template_entity.dart';
import '../features/lifestyle_log/presentation/screens/client_home_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_stats_screen.dart';
import '../features/lifestyle_log/presentation/screens/client_profile_screen.dart';
import '../features/lifestyle_log/presentation/screens/accept_invite_screen.dart';
import '../features/client_sessions/presentation/screens/client_sessions_screen.dart';
import '../features/client_sessions/presentation/screens/client_report_detail_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
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
            path: Routes.trainerCalendar,
            name: RouteNames.trainerCalendar,
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: Routes.trainerClients,
            name: RouteNames.trainerClients,
            builder: (context, state) {
              // Use master-detail layout on tablets, simple list on mobile
              final isTablet = MediaQuery.sizeOf(context).width >= 600;
              if (isTablet) {
                return const ClientsMasterDetailScreen();
              }
              return const ClientsListScreen();
            },
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

      // Previous session review route (must be before trainerSession to match first)
      GoRoute(
        path: Routes.trainerSessionReview,
        name: RouteNames.trainerSessionReview,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final previousSession = state.extra as SessionEntity;
          return PreviousSessionReviewScreen(
            clientId: clientId,
            clientName: clientName,
            previousSession: previousSession,
          );
        },
      ),

      // Active session route
      GoRoute(
        path: Routes.trainerSession,
        name: RouteNames.trainerSession,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final programId = state.uri.queryParameters['programId'];
          return ActiveSessionScreen(
            clientId: clientId,
            clientName: clientName,
            programId: programId,
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

      // AI Program edit route (edit existing program direction)
      GoRoute(
        path: Routes.trainerProgramEdit,
        name: RouteNames.trainerProgramEdit,
        builder: (context, state) {
          final programId = state.pathParameters['programId']!;
          final clientId = state.uri.queryParameters['clientId'] ?? '';
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final trainerId = state.uri.queryParameters['trainerId'] ?? '';
          return GenerateProgramScreen(
            clientId: clientId,
            trainerId: trainerId,
            clientName: clientName,
            programId: programId, // Edit mode: pass existing program ID
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

      // AI Exercise review route (for reviewing AI-generated exercises before session)
      GoRoute(
        path: Routes.trainerAIExerciseReview,
        name: RouteNames.trainerAIExerciseReview,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final programId = state.uri.queryParameters['programId'];
          final sessionId = state.uri.queryParameters['sessionId'];
          final sessionData = state.extra as GeneratedSessionData;
          return AIExerciseReviewScreen(
            clientId: clientId,
            clientName: clientName,
            programId: programId,
            sessionId: sessionId ?? sessionData.sessionId,
            exercises: sessionData.exercises,
            sessionDescription: sessionData.sessionDescriptionKo,
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

      // Workout templates routes
      GoRoute(
        path: Routes.trainerTemplates,
        name: RouteNames.trainerTemplates,
        builder: (context, state) => const MyTemplatesScreen(),
      ),
      GoRoute(
        path: Routes.trainerTemplateCreate,
        name: RouteNames.trainerTemplateCreate,
        builder: (context, state) => const TemplateEditorScreen(),
      ),
      GoRoute(
        path: Routes.trainerTemplateEdit,
        name: RouteNames.trainerTemplateEdit,
        builder: (context, state) {
          final templateId = state.pathParameters['templateId']!;
          return TemplateEditorScreen(templateId: templateId);
        },
      ),
      GoRoute(
        path: Routes.trainerTemplateReview,
        name: RouteNames.trainerTemplateReview,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final clientName = state.uri.queryParameters['name'] ?? 'Client';
          final template = state.extra as WorkoutTemplateEntity;
          return TemplateReviewScreen(
            clientId: clientId,
            clientName: clientName,
            template: template,
          );
        },
      ),

      // Trainer viewing client stats
      GoRoute(
        path: Routes.trainerClientStats,
        name: RouteNames.trainerClientStats,
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          final tab = state.uri.queryParameters['tab'];
          return ClientStatsScreen(
            clientId: clientId,
            initialTab: tab,
          );
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
            path: Routes.clientSessions,
            name: RouteNames.clientSessions,
            builder: (context, state) => const _ClientSessionsWrapper(),
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

      // Client report detail route (full screen, outside shell)
      GoRoute(
        path: Routes.clientReportDetail,
        name: RouteNames.clientReportDetail,
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return ClientReportDetailScreen(reportId: reportId);
        },
      ),

      // Client session report route - loads report by session ID
      GoRoute(
        path: Routes.clientSessionReport,
        name: RouteNames.clientSessionReport,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ClientReportDetailScreen(sessionId: sessionId);
        },
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

// Adaptive trainer shell with smooth Apple-style transitions
class TrainerShell extends StatefulWidget {
  final Widget child;

  const TrainerShell({required this.child, super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _railSlideAnimation;
  late Animation<Offset> _bottomNavSlideAnimation;
  late Animation<double> _fadeAnimation;
  bool _wasTablet = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _railSlideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _bottomNavSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    if (isTablet != _wasTablet) {
      if (isTablet) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      _wasTablet = isTablet;
    }
  }

  int _getCurrentIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    // Check more specific routes first (they all start with /trainer)
    if (location.startsWith(Routes.trainerCalendar)) return 1;
    if (location.startsWith(Routes.trainerClients)) return 2;
    if (location.startsWith(Routes.trainerAcademy)) return 3;
    if (location.startsWith(Routes.trainerProfile)) return 4;
    // trainerHome ('/trainer') checked last as it's a prefix of all others
    return 0;
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go(Routes.trainerHome);
        break;
      case 1:
        context.go(Routes.trainerCalendar);
        break;
      case 2:
        context.go(Routes.trainerClients);
        break;
      case 3:
        context.go(Routes.trainerAcademy);
        break;
      case 4:
        context.go(Routes.trainerProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final currentIndex = _getCurrentIndex();
    final showExtended = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail for tablet/desktop (animated slide in)
          if (isTablet)
            SlideTransition(
              position: _railSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  extended: showExtended,
                  minExtendedWidth: 180,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  leading: showExtended
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Text(
                            'FitLog Pro',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox(height: 32),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Calendar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Clients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Academy'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
              ),
            ),

          // Vertical divider for tablet
          if (isTablet)
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),

          // Main content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              child: widget.child,
            ),
          ),
        ],
      ),

      // Bottom navigation for mobile (animated slide out)
      bottomNavigationBar: isTablet
          ? null
          : SlideTransition(
              position: _bottomNavSlideAnimation,
              child: NavigationBar(
                selectedIndex: currentIndex,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Clients',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school),
                    label: 'Academy',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                onDestinationSelected: _onDestinationSelected,
              ),
            ),
    );
  }
}

class ClientShell extends StatelessWidget {
  final Widget child;

  const ClientShell({required this.child, super.key});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Check more specific routes first (they all start with /client)
    if (location.startsWith(Routes.clientSessions)) return 1;
    if (location.startsWith(Routes.clientStats)) return 2;
    if (location.startsWith(Routes.clientProfile)) return 3;
    // clientHome ('/client') checked last as it's a prefix of all others
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(Routes.clientHome);
              break;
            case 1:
              context.go(Routes.clientSessions);
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

class _ClientSessionsWrapper extends ConsumerWidget {
  const _ClientSessionsWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClientSessionsScreen(clientId: user.id);
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
