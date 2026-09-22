import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../../features/games/presentation/screens/games_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/network/presentation/screens/network_diagnostics_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/optimization/presentation/screens/optimization_screen.dart';
import '../../features/performance/presentation/screens/performance_screen.dart';
import '../../features/settings/presentation/screens/data_management_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

/// Application router configuration using GoRouter with shell route for
/// persistent bottom navigation.
final appRouter = GoRouter(
  initialLocation: RouteNames.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: RouteNames.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => const MaterialPage(
        child: OnboardingScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.home,
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.games,
          name: 'games',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GamesScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.optimization,
          name: 'optimization',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OptimizationScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.performance,
          name: 'performance',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PerformanceScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.about,
          name: 'aboutRoot',
          pageBuilder: (context, state) => const MaterialPage(
            child: AboutScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.diagnostics,
          name: 'diagnostics',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiagnosticsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.network,
          name: 'network',
          pageBuilder: (context, state) => const MaterialPage(
            child: NetworkDiagnosticsScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'about',
              name: 'about',
              pageBuilder: (context, state) => const MaterialPage(
                child: AboutScreen(),
              ),
            ),
            GoRoute(
              path: 'data',
              name: 'dataManagement',
              pageBuilder: (context, state) => const MaterialPage(
                child: DataManagementScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
