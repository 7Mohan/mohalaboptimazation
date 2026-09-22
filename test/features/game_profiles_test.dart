import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/errors/exceptions.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/games/data/datasources/game_profile_local_datasource.dart';
import 'package:mohalab_optimization/features/games/data/repositories/game_profile_repository_impl.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_entity.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_profile_entity.dart';
import 'package:mohalab_optimization/features/games/domain/validators/profile_validator.dart';
import 'package:mohalab_optimization/features/games/presentation/providers/game_profile_provider.dart';
import 'package:mohalab_optimization/features/games/presentation/widgets/game_detail_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ProfileValidator Security & Injection Tests', () {
    test('Valid profile passes validation', () {
      final profile = GameProfile.defaultForGame(
        'com.studio.actiongame',
        'Action Game',
      );
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Rejects package name containing semicolon command injection', () {
      final profile = GameProfile.defaultForGame(
        'com.studio.action;rm -rf /;',
        'Malicious Game',
      );
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('forbidden shell') || e.contains('Invalid package name')),
        isTrue,
      );
    });

    test('Rejects package name containing shell substitution \$(reboot)', () {
      final profile = GameProfile.defaultForGame(
        'com.studio.\$(reboot)',
        'Malicious Game',
      );
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isFalse);
    });

    test('Rejects package name with pipeline (|) and ampersand (&)', () {
      final profile1 = GameProfile.defaultForGame('com.studio|cat /etc/passwd', 'Test');
      final profile2 = GameProfile.defaultForGame('com.studio&&reboot', 'Test');

      expect(ProfileValidator.validate(profile1).isValid, isFalse);
      expect(ProfileValidator.validate(profile2).isValid, isFalse);
    });

    test('Rejects empty or blank package name', () {
      final profile = GameProfile.defaultForGame('', 'Test Game');
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isFalse);
    });

    test('Rejects non-whitelisted arbitrary keys in userSettings', () {
      const profile = GameProfile(
        gamePackage: 'com.studio.safe',
        gameName: 'Safe Game',
        userSettings: {
          'evilCommandToExecute': 'rm -rf /',
        },
      );
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Disallowed custom setting key')), isTrue);
    });

    test('Rejects non-boolean setting values in userSettings', () {
      const profile = GameProfile(
        gamePackage: 'com.studio.safe',
        gameName: 'Safe Game',
        userSettings: {
          SafeUserSettingsKeys.preventNotificationPopups: 'arbitrary_string',
        },
      );
      final result = ProfileValidator.validate(profile);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('must be a boolean')), isTrue);
    });

    test('validateRawJson rejects non-JSON input', () {
      final result = ProfileValidator.validateRawJson('not a json string');
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Malformed JSON'));
    });

    test('validateRawJson rejects invalid enum preferences', () {
      const evilJson = '''
      {
        "gamePackage": "com.studio.game",
        "gameName": "My Game",
        "performance": "OVERCLOCK_UNSAFE_9999MHZ"
      }
      ''';
      final result = ProfileValidator.validateRawJson(evilJson);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Invalid performance preference')), isTrue);
    });
  });

  group('Game Profile Local Persistence Tests', () {
    late SharedPreferences prefs;
    late GameProfileLocalDataSource dataSource;
    late GameProfileRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = GameProfileLocalDataSource(prefs);
      repository = GameProfileRepositoryImpl(dataSource);
    });

    test('Creates, saves, and retrieves profile surviving datasource reload', () async {
      final initial = GameProfile.defaultForGame(
        'com.company.racer',
        'Racer 3D',
      ).copyWith(
        performance: PerformancePreference.highPerformance,
        display: DisplayPreference.fps120,
        isCustomized: true,
      );

      await repository.saveProfile(initial);

      // Simulate app restart by creating a brand-new datasource instance with the same prefs
      final reloadedDataSource = GameProfileLocalDataSource(prefs);
      final reloadedRepo = GameProfileRepositoryImpl(reloadedDataSource);

      final retrieved = await reloadedRepo.getProfile('com.company.racer');
      expect(retrieved, isNotNull);
      expect(retrieved!.gamePackage, equals('com.company.racer'));
      expect(retrieved.gameName, equals('Racer 3D'));
      expect(retrieved.performance, equals(PerformancePreference.highPerformance));
      expect(retrieved.display, equals(DisplayPreference.fps120));
      expect(retrieved.isCustomized, isTrue);
    });

    test('Updates profile categories and preferences', () async {
      final profile = GameProfile.defaultForGame(
        'com.company.racer',
        'Racer 3D',
      );
      await repository.saveProfile(profile);

      final updated = profile.copyWith(
        enabledCategories: {OptimizationCategory.touch, OptimizationCategory.battery},
        touch: TouchPreference.ultraResponsive,
        battery: BatteryPreference.batterySaver,
      );
      await repository.saveProfile(updated);

      final fetched = await repository.getProfile('com.company.racer');
      expect(fetched!.enabledCategories, contains(OptimizationCategory.touch));
      expect(fetched.enabledCategories, contains(OptimizationCategory.battery));
      expect(fetched.touch, equals(TouchPreference.ultraResponsive));
      expect(fetched.battery, equals(BatteryPreference.batterySaver));
    });

    test('Deletes profile correctly and cleans index', () async {
      final profile = GameProfile.defaultForGame('com.company.racer', 'Racer 3D');
      await repository.saveProfile(profile);

      var all = await repository.getAllProfiles();
      expect(all.length, equals(1));

      await repository.deleteProfile('com.company.racer');

      all = await repository.getAllProfiles();
      expect(all, isEmpty);

      final fetched = await repository.getProfile('com.company.racer');
      expect(fetched, isNull);
    });

    test('Reset profile restores default balanced parameters', () async {
      final custom = GameProfile.defaultForGame(
        'com.company.racer',
        'Racer 3D',
      ).copyWith(
        performance: PerformancePreference.highPerformance,
        display: DisplayPreference.fps120,
      );
      await repository.saveProfile(custom);

      final reset = await repository.resetProfile('com.company.racer', 'Racer 3D');
      expect(reset.performance, equals(PerformancePreference.balanced));
      expect(reset.display, equals(DisplayPreference.auto));
      expect(reset.isCustomized, isFalse);

      final fetched = await repository.getProfile('com.company.racer');
      expect(fetched!.performance, equals(PerformancePreference.balanced));
    });

    test('Duplicate profile copies configuration to target package', () async {
      final source = GameProfile.defaultForGame(
        'com.company.source',
        'Source Game',
      ).copyWith(
        performance: PerformancePreference.highPerformance,
        touch: TouchPreference.highSensitivity,
      );
      await repository.saveProfile(source);

      final duplicated = await repository.duplicateProfile(
        sourcePackage: 'com.company.source',
        targetPackage: 'com.company.target',
        targetGameName: 'Target Game',
      );

      expect(duplicated.gamePackage, equals('com.company.target'));
      expect(duplicated.gameName, equals('Target Game'));
      expect(duplicated.performance, equals(PerformancePreference.highPerformance));
      expect(duplicated.touch, equals(TouchPreference.highSensitivity));

      final all = await repository.getAllProfiles();
      expect(all.length, equals(2));
    });

    test('Exports profile to valid JSON and imports successfully', () async {
      final original = GameProfile.defaultForGame(
        'com.company.exporttest',
        'Export Game',
      ).copyWith(
        performance: PerformancePreference.highPerformance,
        battery: BatteryPreference.batterySaver,
        touch: TouchPreference.ultraResponsive,
      );

      final jsonString = repository.exportProfile(original);
      expect(jsonString, contains('"com.company.exporttest"'));
      expect(jsonString, contains('"highPerformance"'));

      final imported = await repository.importProfile(jsonString);
      expect(imported.gamePackage, equals('com.company.exporttest'));
      expect(imported.performance, equals(PerformancePreference.highPerformance));
      expect(imported.battery, equals(BatteryPreference.batterySaver));
      expect(imported.touch, equals(TouchPreference.ultraResponsive));
    });

    test('Import rejects malicious injection payload with ValidationException', () async {
      const maliciousJson = '''
      {
        "gamePackage": "com.game.test; reboot;",
        "gameName": "Exploit Game",
        "performance": "balanced"
      }
      ''';

      expect(
        () => repository.importProfile(maliciousJson),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('GameDetailSheet UX Hierarchy Widget Tests', () {
    const testGame = GameEntity(
      packageName: 'com.studio.actiongame',
      appName: 'Action Game Extreme',
      versionName: '2.0.1',
    );

    testWidgets('Renders complete UX hierarchy: Info -> Status -> Categories -> Config -> Actions',
        (tester) async {
      final inMemoryRepo = InMemoryGameProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(
          GameDetailSheet(
            game: testGame,
            onLaunch: () {},
          ),
          overrides: [
            gameProfileRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 1. Game Information
      expect(find.text('Action Game Extreme'), findsOneWidget);
      expect(find.text('com.studio.actiongame'), findsOneWidget);
      expect(find.text('v2.0.1'), findsOneWidget);

      // 2. Profile Status
      expect(find.text('PROFILE STATUS'), findsOneWidget);
      expect(find.textContaining('Factory Default Profile'), findsOneWidget);

      // 3. Available Categories
      expect(find.text('AVAILABLE CATEGORIES'), findsOneWidget);
      expect(find.text('Performance'), findsWidgets);
      expect(find.text('Battery & Thermals'), findsOneWidget);
      expect(find.text('Network Latency'), findsOneWidget);
      expect(find.text('Touch & Input'), findsOneWidget);
      expect(find.text('Display & Refresh'), findsOneWidget);

      // 4. Current Configuration
      expect(find.text('CURRENT CONFIGURATION'), findsOneWidget);
      expect(find.text('Performance Target'), findsOneWidget);
      expect(find.text('Display & Refresh Rate'), findsOneWidget);
      expect(find.text('GAMING ENVIRONMENT TOGGLES'), findsOneWidget);
      expect(find.text('Prevent Notification Popups'), findsOneWidget);

      // 5. Save / Reset
      expect(find.text('Reset to Default'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('Tapping Save Profile saves configuration', (tester) async {
      final inMemoryRepo = InMemoryGameProfileRepository();

      // Use a taller surface so the full sheet is visible in the test viewport
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          GameDetailSheet(
            game: testGame,
            onLaunch: () {},
          ),
          overrides: [
            gameProfileRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Scroll the sheet to make Save Profile visible then tap
      await tester.ensureVisible(find.text('Save Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Profile'));
      await tester.pumpAndSettle();

      // Profile should now be customized in repo
      final saved = await inMemoryRepo.getProfile('com.studio.actiongame');
      expect(saved, isNotNull);
      expect(saved!.isCustomized, isTrue);
      expect(find.textContaining('Saved optimization profile'), findsOneWidget);
    });
  });
}
