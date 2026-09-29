import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../../features/games/presentation/screens/games_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/network/presentation/screens/network_diagnostics_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/optimization/presentation/screens/optimization_screen.dart';
import '../../features/settings/presentation/screens/data_management_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/glass/glass_background.dart';
import '../theme/app_theme.dart';
import 'route_names.dart';

/// Page with the glass fade-through transition. Tab switches use a shorter
/// duration so the bottom bar feels instant; pushed pages get a touch more.
Page<void> _glassPage(GoRouterState state, Widget child, {bool tab = false}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration(milliseconds: tab ? 220 : 300),
    reverseTransitionDuration: Duration(milliseconds: tab ? 180 : 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        GlassFadeThrough(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    ),
  );
}

/// Application router with a shell route for persistent glass navigation.
final appRouter = GoRouter(
  initialLocation: RouteNames.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: RouteNames.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) =>
          _glassPage(state, const GlassBackground(child: OnboardingScreen())),
    ),
    // Legacy deep link: the Performance screen merged into Tweaks.
    GoRoute(
      path: RouteNames.performance,
      redirect: (context, state) => RouteNames.optimization,
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.home,
          name: 'home',
          pageBuilder: (context, state) => _glassPage(state, const HomeScreen(), tab: true),
        ),
        GoRoute(
          path: RouteNames.games,
          name: 'games',
          pageBuilder: (context, state) => _glassPage(state, const GamesScreen(), tab: true),
        ),
        GoRoute(
          path: RouteNames.optimization,
          name: 'optimization',
          pageBuilder: (context, state) => _glassPage(state, const OptimizationScreen(), tab: true),
        ),
        GoRoute(
          path: RouteNames.about,
          name: 'aboutRoot',
          pageBuilder: (context, state) => _glassPage(state, const AboutScreen()),
        ),
        GoRoute(
          path: RouteNames.diagnostics,
          name: 'diagnostics',
          pageBuilder: (context, state) => _glassPage(state, const DiagnosticsScreen(), tab: true),
        ),
        GoRoute(
          path: RouteNames.network,
          name: 'network',
          pageBuilder: (context, state) => _glassPage(state, const NetworkDiagnosticsScreen()),
        ),
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          pageBuilder: (context, state) => _glassPage(state, const SettingsScreen(), tab: true),
          routes: [
            GoRoute(
              path: 'about',
              name: 'about',
              pageBuilder: (context, state) => _glassPage(state, const AboutScreen()),
            ),
            GoRoute(
              path: 'data',
              name: 'dataManagement',
              pageBuilder: (context, state) => _glassPage(state, const DataManagementScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
