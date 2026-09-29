import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/about/presentation/screens/about_screen.dart';
import 'package:mohalab_optimization/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:mohalab_optimization/features/games/presentation/screens/games_screen.dart';
import 'package:mohalab_optimization/features/home/presentation/screens/home_screen.dart';
import 'package:mohalab_optimization/features/optimization/domain/device_advisor.dart';
import 'package:mohalab_optimization/features/optimization/presentation/providers/device_advice_provider.dart';
import 'package:mohalab_optimization/features/optimization/presentation/screens/optimization_screen.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/settings_screen.dart';

Widget _buildTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Moha Lab Optimization - Screen Widget Tests', () {
    testWidgets('HomeScreen renders with branding and sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MOHA LAB'), findsOneWidget);
      expect(find.text('Optimization'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('Boost'), findsOneWidget);
    });

    testWidgets('GamesScreen renders with header and empty state', (tester) async {
      await tester.pumpWidget(_buildTestApp(const GamesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('No games detected yet'), findsOneWidget);
      expect(
        find.textContaining('Moha Lab automatically scans installed packages'),
        findsOneWidget,
      );
    });

    testWidgets('OptimizationScreen renders categories and safe banners', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const OptimizationScreen(),
        overrides: [
          deviceAdviceProvider.overrideWith(
              (ref) async => DeviceAdvisor.analyze(const DeviceSignals(maxRefreshHz: 120))),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tweaks'), findsOneWidget);
      expect(find.text('Recommended for your device'), findsOneWidget);
      expect(find.text('Lock Max Refresh Rate'), findsWidgets);
      await tester.scrollUntilVisible(find.text('PRESETS'), 200);
      expect(find.text('PRESETS'), findsOneWidget);
      expect(find.text('Competitive'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('RAM Boost'), 200);
      expect(find.text('RAM Boost'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lock Max Refresh Rate'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Lock Max Refresh Rate'), findsOneWidget);
      // Removed placebo tweaks must never come back.
      expect(find.textContaining('TCP'), findsNothing);
      expect(find.textContaining('Zero Touch'), findsNothing);
    });

    testWidgets('DiagnosticsScreen renders system information sections', (tester) async {
      await tester.pumpWidget(_buildTestApp(const DiagnosticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Diagnostics'), findsOneWidget);
      expect(find.text('DEVICE'), findsOneWidget);
      expect(find.text('Advanced Diagnostics'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders appearance and application preferences', (tester) async {
      await tester.pumpWidget(_buildTestApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Application'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Application'), findsOneWidget);
    });

    testWidgets('AboutScreen renders brand info and acknowledgements', (tester) async {
      await tester.pumpWidget(_buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('MOHA LAB'), findsOneWidget);
      expect(find.text('Optimization'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('ACKNOWLEDGEMENTS'), 300);
      await tester.pumpAndSettle();
      expect(find.text('ACKNOWLEDGEMENTS'), findsOneWidget);
    });
  });
}
