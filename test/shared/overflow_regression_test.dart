// Renders every screen and sheet at real phone sizes (393x860 and 360x740)
// with normal and large text, and fails on any "overflowed by N pixels".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/about/presentation/screens/about_screen.dart';
import 'package:mohalab_optimization/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_entity.dart';
import 'package:mohalab_optimization/features/games/presentation/screens/games_screen.dart';
import 'package:mohalab_optimization/features/games/presentation/widgets/game_detail_sheet.dart';
import 'package:mohalab_optimization/features/home/presentation/screens/home_screen.dart';
import 'package:mohalab_optimization/features/network/presentation/screens/network_diagnostics_screen.dart';
import 'package:mohalab_optimization/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mohalab_optimization/features/optimization/domain/device_advisor.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak_catalog.dart';
import 'package:mohalab_optimization/features/optimization/presentation/providers/device_advice_provider.dart';
import 'package:mohalab_optimization/features/optimization/presentation/screens/optimization_screen.dart';
import 'package:mohalab_optimization/features/optimization/presentation/widgets/long_task_sheet.dart';
import 'package:mohalab_optimization/features/settings/presentation/providers/theme_provider.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/data_management_screen.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final screens = <String, Widget Function()>{
  'home': () => const HomeScreen(),
  'games': () => const GamesScreen(),
  'tweaks': () => const OptimizationScreen(),
  'diagnostics': () => const DiagnosticsScreen(),
  'settings': () => const SettingsScreen(),
  'about': () => const AboutScreen(),
  'network': () => const NetworkDiagnosticsScreen(),
  'data': () => const DataManagementScreen(),
  'onboarding': () => const OnboardingScreen(),
  'compileSheet': () => const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: LongTaskSheet(action: TweakCatalog.compileApps))),
  'dexoptSheet': () => const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: LongTaskSheet(action: TweakCatalog.compileAll))),
  'gameSheet': () => Scaffold(body: GameDetailSheet(game: const GameEntity(packageName: 'com.tencent.ig', appName: 'PUBG MOBILE with a very long title'), onLaunch: () {})),
};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final size in const [Size(393, 860), Size(360, 740)]) {
    for (final scale in const [1.0, 1.3]) {
      for (final e in screens.entries) {
        testWidgets('${e.key} @ ${size.width.toInt()}x${size.height.toInt()} text x$scale', (tester) async {
          SharedPreferences.setMockInitialValues({'has_seen_community_modal_v2': true});
          final prefs = await SharedPreferences.getInstance();
          await tester.binding.setSurfaceSize(size);
          final errors = <String>[];
          final old = FlutterError.onError;
          FlutterError.onError = (d) {
            final s = d.toString();
            if (s.contains('overflowed')) {
              final m = RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(s);
              final src = RegExp(r'file:///\S*/lib/(\S+?):(\d+)').firstMatch(s);
              errors.add('${m?.group(0)} at ${src?.group(1)}:${src?.group(2)}');
            }
          };
          await tester.pumpWidget(ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              deviceAdviceProvider.overrideWith((ref) async => DeviceAdvisor.analyze(const DeviceSignals(sdkInt: 36, maxRefreshHz: 120, onWifi: true, batteryTempC: 44, thermalStatus: 2))),
            ],
            child: MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 32, bottom: 24)),
              child: MaterialApp(theme: AppTheme.dark, home: e.value()),
            ),
          ));
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          // Scroll through long lists to lay out everything.
          final scrollables = find.byType(Scrollable);
          for (var s = 0; s < 12 && scrollables.evaluate().isNotEmpty; s++) {
            await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 200));
          }
          FlutterError.onError = old;
          await tester.binding.setSurfaceSize(null);
          expect(errors.toSet(), isEmpty, reason: 'layout overflow');
        });
      }
    }
  }
}
