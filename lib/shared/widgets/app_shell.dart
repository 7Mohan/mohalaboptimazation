import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_names.dart';
import '../../core/theme/tokens/app_glass.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../features/onboarding/presentation/tour/feature_tour.dart';
import 'glass/glass_background.dart';
import 'glass/glass_card.dart';

/// Responsive app shell.
///
/// - Phones: content scrolls beneath a floating, blurred glass tab bar.
/// - Tablets (>= 600dp): glass navigation rail.
/// - The ambient canvas is painted once here, behind every tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double _barHeight = 66;

  /// Bottom padding a scrollable tab screen needs so its last item clears
  /// the floating tab bar.
  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + AppSpacing.lg;

  static const _tabs = [
    _TabItem(
        route: RouteNames.home,
        label: 'Home',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard_rounded),
    _TabItem(
        route: RouteNames.games,
        label: 'Games',
        icon: Icons.sports_esports_outlined,
        selectedIcon: Icons.sports_esports_rounded),
    _TabItem(
        route: RouteNames.optimization,
        label: 'Tweaks',
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded),
    _TabItem(
        route: RouteNames.diagnostics,
        label: 'Device',
        icon: Icons.monitor_heart_outlined,
        selectedIcon: Icons.monitor_heart_rounded),
    _TabItem(
        route: RouteNames.settings,
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == RouteNames.network) return 3;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      final route = _tabs[i].route;
      if (location == route || (route != '/' && location.startsWith('$route/'))) {
        return i;
      }
    }
    return 0;
  }

  void _go(BuildContext context, int index, int current) {
    if (index == current) return;
    HapticFeedback.selectionClick();
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final location = GoRouterState.of(context).uri.path;

    return GlassBackground(
      child: Stack(
        children: [
          Positioned.fill(child: _buildLayout(context, selectedIndex)),
          Positioned.fill(child: FeatureTourOverlay(location: location)),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context, int selectedIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.breakpointCompact) {
          return Scaffold(
            body: SafeArea(
              right: false,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: GlassCard(
                      level: AppGlassLevel.level2,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: NavigationRail(
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (i) => _go(context, i, selectedIndex),
                        destinations: [
                          for (final tab in _tabs)
                            NavigationRailDestination(
                              icon: Icon(tab.icon),
                              selectedIcon: Icon(tab.selectedIcon),
                              label: Text(tab.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: _GlassTabBar(
            tabs: _tabs,
            selectedIndex: selectedIndex,
            height: _barHeight,
            onSelect: (i) => _go(context, i, selectedIndex),
          ),
        );
      },
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.height,
    required this.onSelect,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final double height;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(height / 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, bottom + AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppGlass.shadowsFor(context, AppGlassLevel.level4),
        ),
        child: CustomPaint(
          foregroundPainter: GlassBorderPainter(
            radius: radius,
            gradient: AppGlass.borderGradient(context, AppGlassLevel.level4),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AppGlass.blurLevel4, sigmaY: AppGlass.blurLevel4),
              child: ColoredBox(
                color: AppGlass.surfaceColor(context, AppGlassLevel.level4),
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        Expanded(
                          child: KeyedSubtree(
                            key: TourKeys.tabs[i],
                            child: _TabButton(
                              tab: tabs[i],
                              selected: i == selectedIndex,
                              onTap: () => onSelect(i),
                              theme: theme,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.circle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: selected ? 52 : 36,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? scheme.primary.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  key: ValueKey(selected),
                  size: 22,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall!.copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(tab.label, maxLines: 1),
            ),
          ],
        ),
      ),
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
