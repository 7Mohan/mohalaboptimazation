import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/data/datasources/local/data_manager.dart';
import 'package:mohalab_optimization/data/datasources/local/settings_local_datasource.dart';
import 'package:mohalab_optimization/domain/entities/app_settings.dart';
import 'package:mohalab_optimization/domain/entities/theme_preference.dart';
import 'package:mohalab_optimization/features/games/data/datasources/game_profile_local_datasource.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_profile_entity.dart';
import 'package:mohalab_optimization/features/network/data/datasources/network_history_local_datasource.dart';
import 'package:mohalab_optimization/features/network/domain/entities/gaming_network_verdict.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_connection_type.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_diagnostic_session.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_metrics.dart';
import 'package:mohalab_optimization/features/settings/presentation/providers/theme_provider.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/data_management_screen.dart';
import 'package:mohalab_optimization/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<SharedPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  DataManager buildManager(SharedPreferences prefs) {
    final settingsDs = SettingsLocalDataSource(prefs);
    final profileDs = GameProfileLocalDataSource(prefs);
    final networkDs = NetworkHistoryLocalDataSource(prefs);
    return DataManager(
      prefs: prefs,
      settingsDs: settingsDs,
      profileDs: profileDs,
      networkDs: networkDs,
    );
  }

  // ── AppSettings serialization ───────────────────────────────────────────────

  group('AppSettings round-trip', () {
    test('toMap / fromMap preserves all fields', () {
      const settings = AppSettings(
        theme: ThemePreference.dark,
        language: LanguagePreference.english,
        notificationsEnabled: false,
        defaultOptimizationBehaviour: DefaultOptimizationBehaviour.skipToReview,
        performanceMonitoringMode: PerformanceMonitoringMode.detailed,
        networkTestAutoRun: NetworkTestAutoRun.onWifiOnly,
        crashReportingOptIn: false,
      );

      final map = settings.toMap();
      final revived = AppSettings.fromMap(map);

      expect(revived.theme, equals(ThemePreference.dark));
      expect(revived.language, equals(LanguagePreference.english));
      expect(revived.notificationsEnabled, isFalse);
      expect(revived.defaultOptimizationBehaviour,
          equals(DefaultOptimizationBehaviour.skipToReview));
      expect(revived.performanceMonitoringMode,
          equals(PerformanceMonitoringMode.detailed));
      expect(revived.networkTestAutoRun,
          equals(NetworkTestAutoRun.onWifiOnly));
      expect(revived.crashReportingOptIn, isFalse);
    });

    test('fromMap falls back to safe defaults for unknown enum values', () {
      final map = {
        'theme': 'INVALID_THEME',
        'language': 'klingon',
        'notificationsEnabled': 'not_a_bool', // wrong type
        'performanceMonitoringMode': null,
      };
      final settings = AppSettings.fromMap(map);

      expect(settings.theme, equals(ThemePreference.system));
      expect(settings.language, equals(LanguagePreference.systemDefault));
      expect(settings.notificationsEnabled, isTrue); // default
      expect(settings.performanceMonitoringMode,
          equals(PerformanceMonitoringMode.balanced)); // default
    });
  });

  // ── SettingsLocalDataSource ─────────────────────────────────────────────────

  group('SettingsLocalDataSource persistence', () {
    test('saves and reloads AppSettings correctly', () async {
      final prefs = await freshPrefs();
      final ds = SettingsLocalDataSource(prefs);

      const s = AppSettings(
        theme: ThemePreference.light,
        notificationsEnabled: false,
        crashReportingOptIn: false,
      );

      await ds.saveSettings(s);
      final loaded = await ds.getSettings();

      expect(loaded.theme, equals(ThemePreference.light));
      expect(loaded.notificationsEnabled, isFalse);
      expect(loaded.crashReportingOptIn, isFalse);
    });

    test('clearSettings resets to defaults on next read', () async {
      final prefs = await freshPrefs();
      final ds = SettingsLocalDataSource(prefs);

      await ds.saveSettings(const AppSettings(theme: ThemePreference.dark));
      await ds.clearSettings();
      final loaded = await ds.getSettings();

      expect(loaded.theme, equals(ThemePreference.system));
    });
  });

  // ── ImportValidator ─────────────────────────────────────────────────────────

  group('ImportValidator security and validation', () {
    const validator = ImportValidator();

    test('rejects oversized input', () {
      // 6 MB of data
      final huge = 'x' * (6 * 1024 * 1024);
      final result = validator.validate(huge);
      expect(result.isValid, isFalse);
      expect(result.error, contains('too large'));
    });

    test('rejects invalid JSON', () {
      final result = validator.validate('{not: valid json,,}');
      expect(result.isValid, isFalse);
      expect(result.error, contains('parse'));
    });

    test('rejects JSON array at root level', () {
      final result = validator.validate('[1, 2, 3]');
      expect(result.isValid, isFalse);
    });

    test('rejects wrong appId', () {
      const json =
          '{"appId":"com.malicious.app","schemaVersion":1,"exportedAt":"2024-01-01T00:00:00.000Z"}';
      final result = validator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('not exported from Moha Lab'));
    });

    test('rejects missing or invalid schemaVersion', () {
      const json =
          '{"appId":"com.mohalab.optimization","schemaVersion":"notanint"}';
      final result = validator.validate(json);
      expect(result.isValid, isFalse);
    });

    test('rejects profiles with missing required fields', () {
      const json =
          '{"appId":"com.mohalab.optimization","schemaVersion":1,"exportedAt":"2024-01-01T00:00:00.000Z",'
          '"profiles":[{"wrongKey":"value"}]}';
      final result = validator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('required fields'));
    });

    test('rejects too many profiles', () {
      final profiles = List.generate(
          501,
          (i) => '{"gamePackage":"pkg.$i","gameName":"Game $i"}');
      final json =
          '{"appId":"com.mohalab.optimization","schemaVersion":1,"exportedAt":"2024-01-01T00:00:00.000Z",'
          '"profiles":[${profiles.join(",")}]}';
      final result = validator.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('too many profiles'));
    });

    test('accepts a valid minimal export bundle', () {
      const json =
          '{"appId":"com.mohalab.optimization","schemaVersion":1,'
          '"exportedAt":"2024-01-01T00:00:00.000Z","settings":{},"profiles":[],"networkHistory":[]}';
      final result = validator.validate(json);
      expect(result.isValid, isTrue);
      expect(result.bundle, isNotNull);
    });
  });

  // ── DataManager operations ─────────────────────────────────────────────────

  group('DataManager clear operations', () {
    test('clearNetworkHistory removes all stored sessions', () async {
      final prefs = await freshPrefs();
      final networkDs = NetworkHistoryLocalDataSource(prefs);

      // Save a session
      await networkDs.saveSession(NetworkDiagnosticSession(
        id: 'clear_test_1',
        timestamp: DateTime.now(),
        metrics: NetworkMetrics(
          connectionType: NetworkConnectionType.wifi,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
        primaryVerdict: GamingNetworkVerdict.lowLatency,
        durationMs: 100,
      ));

      expect((await networkDs.getHistory()).length, equals(1));

      final manager = buildManager(prefs);
      final result = await manager.clearNetworkHistory();

      expect(result.success, isTrue);
      expect((await networkDs.getHistory()).length, equals(0));
    });

    test('clearGameProfiles removes all stored profiles', () async {
      final prefs = await freshPrefs();
      final profileDs = GameProfileLocalDataSource(prefs);

      await profileDs.saveProfile(
          GameProfile.defaultForGame('com.test.game', 'Test Game'));
      expect((await profileDs.getAllProfiles()).length, equals(1));

      final manager = buildManager(prefs);
      final result = await manager.clearGameProfiles();

      expect(result.success, isTrue);
      expect((await profileDs.getAllProfiles()).length, equals(0));
    });

    test('resetAllData wipes entire SharedPreferences', () async {
      final prefs = await freshPrefs();
      await prefs.setString('some_key', 'some_value');
      await prefs.setString('another_key', 'another_value');

      final manager = buildManager(prefs);
      final result = await manager.resetAllData();

      expect(result.success, isTrue);
      expect(prefs.getKeys(), isEmpty);
    });
  });

  group('DataManager export / import round-trip', () {
    test('exports and imports profiles + settings successfully', () async {
      final prefs = await freshPrefs();
      final profileDs = GameProfileLocalDataSource(prefs);
      final settingsDs = SettingsLocalDataSource(prefs);

      // Seed data
      await settingsDs
          .saveSettings(const AppSettings(theme: ThemePreference.dark));
      await profileDs.saveProfile(
          GameProfile.defaultForGame('com.round.trip', 'Round Trip Game'));

      final manager = buildManager(prefs);
      final json = await manager.exportAllData();

      // Reset prefs and re-import
      await prefs.clear();
      final freshManager = buildManager(prefs);
      final importResult = await freshManager.importData(json);

      expect(importResult.success, isTrue);
      expect(importResult.message, contains('profile'));

      // Settings should be restored (dark theme)
      final restoredSettings = await settingsDs.getSettings();
      expect(restoredSettings.theme, equals(ThemePreference.dark));

      // Profile should be restored
      final profiles = await profileDs.getAllProfiles();
      expect(profiles.any((p) => p.gamePackage == 'com.round.trip'), isTrue);
    });

    test('import never restores crashReportingOptIn = true silently', () async {
      final prefs = await freshPrefs();
      final settingsDs = SettingsLocalDataSource(prefs);

      // Export with crash reporting enabled
      await settingsDs.saveSettings(
          const AppSettings(crashReportingOptIn: true));
      final manager = buildManager(prefs);
      final json = await manager.exportAllData();

      // Reset with crash reporting disabled
      await prefs.clear();
      await settingsDs.saveSettings(
          const AppSettings(crashReportingOptIn: false));

      final freshManager = buildManager(prefs);
      await freshManager.importData(json);

      // Must remain false — never silently enabled
      final settings = await settingsDs.getSettings();
      expect(settings.crashReportingOptIn, isFalse);
    });

    test('import of corrupted JSON fails gracefully', () async {
      final prefs = await freshPrefs();
      final manager = buildManager(prefs);

      final result = await manager.importData('{corrupted json!!}');

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('import of wrong-app JSON fails with clear message', () async {
      final prefs = await freshPrefs();
      final manager = buildManager(prefs);

      const wrongApp = '{"appId":"com.other.app","schemaVersion":1,'
          '"exportedAt":"2024-01-01T00:00:00.000Z","profiles":[]}';
      final result = await manager.importData(wrongApp);

      expect(result.success, isFalse);
      expect(result.error, contains('Moha Lab'));
    });
  });

  // ── Widget: SettingsScreen ─────────────────────────────────────────────────

  group('SettingsScreen widget', () {
    Widget buildApp(SharedPreferences prefs) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('renders all setting sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await freshPrefs();
      await tester.pumpWidget(buildApp(prefs));
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Default Optimization Behaviour'), findsOneWidget);
      expect(find.text('Performance Monitoring'), findsOneWidget);
      expect(find.text('Network Diagnostics'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('privacy section has factual no-account statement',
        (tester) async {
      final prefs = await freshPrefs();
      await tester.pumpWidget(buildApp(prefs));
      await tester.pumpAndSettle();

      // Scroll to find the privacy text
      await tester.scrollUntilVisible(
          find.text('No account is required to use this app.'), 300.0,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('No account is required to use this app.'),
          findsOneWidget);
    });
  });

  // ── Widget: DataManagementScreen ───────────────────────────────────────────

  group('DataManagementScreen widget', () {
    Widget buildApp(SharedPreferences prefs) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DataManagementScreen(),
        ),
      );
    }

    testWidgets('renders all data management sections', (tester) async {
      final prefs = await freshPrefs();
      await tester.pumpWidget(buildApp(prefs));
      await tester.pumpAndSettle();

      expect(find.text('Stored Locally On Your Device'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);

      await tester.scrollUntilVisible(
          find.text('Import Data'), 300.0,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Import Data'), findsOneWidget);
    });

    testWidgets('import button opens dialog', (tester) async {
      final prefs = await freshPrefs();
      await tester.pumpWidget(buildApp(prefs));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
          find.byKey(const Key('import_data_button')), 300.0,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('import_data_button')));
      await tester.pumpAndSettle();

      expect(find.text('Import Data'), findsWidgets);
      expect(find.byKey(const Key('import_json_field')), findsOneWidget);
    });
  });
}
