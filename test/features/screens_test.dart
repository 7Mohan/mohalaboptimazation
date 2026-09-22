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
import 'package:mohalab_optimization/features/optimization/presentation/screens/optimization_screen.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/settings_screen.dart';

Widget _buildTestApp(Widget child) {
  return ProviderScope(
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
      expect(find.text('Quick Actions'), findsOneWidget);
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
      await tester.pumpWidget(_buildTestApp(const OptimizationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Optimization'), findsOneWidget);
      expect(find.text('Safe Optimization Tools'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Memory Management'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Memory Management'), findsOneWidget);
      expect(find.text('Thermal Control'), findsOneWidget);
      expect(find.text('Battery Optimization'), findsOneWidget);
      expect(find.text('Safe (No Root)'), findsWidgets);
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
