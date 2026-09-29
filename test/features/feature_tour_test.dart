import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mohalab_optimization/core/routing/app_router.dart';
import 'package:mohalab_optimization/core/routing/route_names.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/onboarding/presentation/tour/feature_tour.dart';
import 'package:mohalab_optimization/features/settings/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester tester) async {
  // The hand animation loops forever, so pump fixed frames instead of settling.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<(ProviderContainer, SharedPreferences)> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'has_seen_community_modal_v2': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    appRouter.go(RouteNames.home);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: appRouter),
      ),
    );
    await _settle(tester);
    return (container, prefs);
  }

  testWidgets('first launch starts the tour; later launches do not', (tester) async {
    final (container, prefs) = await pumpApp(tester);
    final tour = container.read(featureTourProvider.notifier);

    tour.startIfFirstLaunch();
    expect(container.read(featureTourProvider), 0);

    tour.finish();
    expect(prefs.getBool('feature_tour_done_v1'), isTrue);

    tour.startIfFirstLaunch();
    expect(container.read(featureTourProvider), isNull);
  });

  testWidgets('walks through steps, navigates tabs, and skip ends it', (tester) async {
    final (container, prefs) = await pumpApp(tester);
    container.read(featureTourProvider.notifier).start();
    await _settle(tester);

    expect(find.text('Welcome to Moha Lab'), findsOneWidget);
    expect(find.text('STEP 1 OF ${featureTourSteps.length}'), findsOneWidget);

    await tester.tap(find.text('Start tour'));
    await _settle(tester);
    expect(find.text('Your device at a glance'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);

    // Jump to the per-game step: the tour must open the Games tab itself.
    final gamesStep = featureTourSteps.indexWhere((s) => s.route == RouteNames.games);
    while (container.read(featureTourProvider)! < gamesStep) {
      await tester.tap(find.text('Next'));
      await _settle(tester);
    }
    expect(find.text('Per-game tuning'), findsOneWidget);
    final location = GoRouter.of(tester.element(find.text('Per-game tuning')))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    expect(location, RouteNames.games);

    await tester.tap(find.text('Back'));
    await _settle(tester);
    expect(find.text('Games tab'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(container.read(featureTourProvider), isNull);
    expect(find.text('Games tab'), findsNothing);
    expect(prefs.getBool('feature_tour_done_v1'), isTrue);
  });
}
