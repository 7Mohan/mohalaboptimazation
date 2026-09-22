import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_names.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';

/// Responsive, accessible app shell for Moha Lab Optimization.
///
/// Features:
/// - Bottom NavigationBar on compact devices (< 600dp)
/// - NavigationRail on tablet and desktop screens (>= 600dp)
/// - Strict 48x48 dp minimum touch targets
/// - Constrains content width to [AppSizes.maxContentWidth] on wide screens
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      route: RouteNames.home,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _TabItem(
      route: RouteNames.games,
      label: 'Games',
      icon: Icons.sports_esports_outlined,
      selectedIcon: Icons.sports_esports,
    ),
    _TabItem(
      route: RouteNames.optimization,
      label: 'Optimize',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    _TabItem(
      route: RouteNames.diagnostics,
      label: 'Diagnostics',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
    ),
    _TabItem(
      route: RouteNames.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == RouteNames.performance) {
      return 2; // Maps to Optimize tab
    }
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].route ||
          location.startsWith('${_tabs[i].route}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _selectedIndex(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSizes.breakpointCompact;

        if (isWide) {
          // NavigationRail layout for tablet/desktop
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    if (index != selectedIndex) {
                      context.go(_tabs[index].route);
                    }
                  },
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxxs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LAB',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  destinations: _tabs
                      .map(
                        (tab) => NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.selectedIcon),
                          label: Text(tab.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.maxContentWidth,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Standard Bottom Navigation for phones (< 600dp)
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              if (index != selectedIndex) {
                context.go(_tabs[index].route);
              }
            },
            destinations: _tabs
                .map(
                  (tab) => NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                    tooltip: tab.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
