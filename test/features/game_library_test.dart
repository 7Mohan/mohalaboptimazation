import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/games/data/repositories/game_profile_repository_impl.dart';
import 'package:mohalab_optimization/features/games/domain/classifier/game_classifier.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_entity.dart';
import 'package:mohalab_optimization/features/games/domain/repositories/game_repository.dart';
import 'package:mohalab_optimization/features/games/presentation/providers/game_library_provider.dart';
import 'package:mohalab_optimization/features/games/presentation/providers/game_profile_provider.dart';
import 'package:mohalab_optimization/features/games/presentation/screens/games_screen.dart';
import 'package:mohalab_optimization/shared/widgets/indicators/moha_status_badge.dart';

/// Fake repository for predictable widget & state testing.
class FakeGameRepository implements GameRepository {
  FakeGameRepository(this.games);

  final List<GameEntity> games;
  bool launchCalled = false;
  String? lastLaunchedPackage;

  @override
  Future<List<GameEntity>> getInstalledGames({bool forceRefresh = false}) async {
    return List<GameEntity>.from(games);
  }

  @override
  Future<bool> launchGame(String packageName) async {
    launchCalled = true;
    lastLaunchedPackage = packageName;
    return true;
  }

  @override
  Future<Uint8List?> getGameIcon(String packageName) async {
    return null;
  }
}

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

  group('GameClassifier Multi-Signal Tests', () {
    const classifier = DefaultGameClassifier();

    test('Classifies app as Game with high confidence via CATEGORY_GAME', () {
      const raw = RawAppMetadata(
        packageName: 'com.example.actiongame',
        appName: 'Action Game 3D',
        isGameCategory: true,
        hasLauncherIntent: true,
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isTrue);
      expect(result.confidence, equals(GameConfidence.high));
      expect(result.confidenceScore, greaterThanOrEqualTo(0.60));
      expect(
        result.signals.any((s) => s.contains('CATEGORY_GAME')),
        isTrue,
      );
    });

    test('Classifies app as Game with high confidence via FLAG_IS_GAME', () {
      const raw = RawAppMetadata(
        packageName: 'com.example.classicgame',
        appName: 'Classic Arcade',
        isGameFlag: true,
        hasLauncherIntent: true,
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isTrue);
      expect(result.confidence, equals(GameConfidence.high));
      expect(
        result.signals.any((s) => s.contains('FLAG_IS_GAME')),
        isTrue,
      );
    });

    test('Classifies app as Game via GAME launcher intent', () {
      const raw = RawAppMetadata(
        packageName: 'com.example.retro',
        appName: 'Retro Racer',
        hasGameIntent: true,
        hasLauncherIntent: true,
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isTrue);
      expect(result.confidence, equals(GameConfidence.medium));
      expect(
        result.signals.any((s) => s.contains('android.intent.category.GAME')),
        isTrue,
      );
    });

    test('Classifies app as Game via Engine metadata markers', () {
      const raw = RawAppMetadata(
        packageName: 'com.example.unityproject',
        appName: 'Space Odyssey',
        hasLauncherIntent: true,
        metaDataKeys: ['unity.build-id', 'unity.player_activity'],
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isTrue);
      expect(result.confidence, equals(GameConfidence.high));
      expect(
        result.signals.any((s) => s.contains('engine / Play Games')),
        isTrue,
      );
    });

    test('Rejects non-game system app with no gaming signals', () {
      const raw = RawAppMetadata(
        packageName: 'com.android.settings',
        appName: 'Settings',
        isSystemApp: true,
        hasLauncherIntent: true,
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isFalse);
    });

    test('Rejects regular user utility app without gaming metadata', () {
      const raw = RawAppMetadata(
        packageName: 'com.example.notes',
        appName: 'Notes App',
        isSystemApp: false,
        hasLauncherIntent: true,
      );

      final result = classifier.classify(raw);
      expect(result.isGame, isFalse);
    });
  });

  group('GameEntity Unit Tests', () {
    test('versionDisplay formats correctly with versionName', () {
      const game = GameEntity(
        packageName: 'com.game.test',
        appName: 'Test Game',
        versionName: '2.1.0',
      );
      expect(game.versionDisplay, equals('v2.1.0'));
    });

    test('versionDisplay formats correctly with versionCode fallback', () {
      const game = GameEntity(
        packageName: 'com.game.test',
        appName: 'Test Game',
        versionCode: 1045,
      );
      expect(game.versionDisplay, equals('Build 1045'));
    });

    test('versionDisplay handles unavailable version gracefully', () {
      const game = GameEntity(
        packageName: 'com.game.test',
        appName: 'Test Game',
      );
      expect(game.versionDisplay, equals('Version Unavailable'));
    });

    test('installedDisplay formats timestamp correctly', () {
      final game = GameEntity(
        packageName: 'com.game.test',
        appName: 'Test Game',
        installedAt: DateTime(2026, 3, 15),
      );
      expect(game.installedDisplay, equals('2026-03-15'));
    });

    test('installedDisplay handles missing install date gracefully', () {
      const game = GameEntity(
        packageName: 'com.game.test',
        appName: 'Test Game',
      );
      expect(game.installedDisplay, equals('Install date unavailable'));
    });
  });

  group('GamesScreen Widget Tests', () {
    testWidgets('Renders empty state when zero games detected', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const GamesScreen(),
          overrides: [
            gameRepositoryProvider.overrideWithValue(FakeGameRepository(const [])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('No games detected yet'), findsOneWidget);
      expect(find.text('How Detection Works'), findsOneWidget);
    });

    testWidgets('Renders detected games list with cards and badges', (tester) async {
      final fakeGames = [
        const GameEntity(
          packageName: 'com.studio.spacewar',
          appName: 'Space War Pro',
          versionName: '1.4.2',
          confidence: GameConfidence.high,
          confidenceScore: 0.95,
          statusLabel: 'Optimized',
          statusType: MohaStatusType.safe,
        ),
        const GameEntity(
          packageName: 'com.studio.speedracer',
          appName: 'Speed Racer',
          versionName: '3.0.0',
          confidence: GameConfidence.medium,
          confidenceScore: 0.55,
          statusLabel: 'Ready',
          statusType: MohaStatusType.optimal,
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          const GamesScreen(),
          overrides: [
            gameRepositoryProvider.overrideWithValue(FakeGameRepository(fakeGames)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Space War Pro'), findsOneWidget);
      expect(find.text('Speed Racer'), findsOneWidget);
      expect(find.textContaining('com.studio.spacewar'), findsOneWidget);
      expect(find.text('DETECTED GAMES (2)'), findsOneWidget);
    });

    testWidgets('Filters games using search bar', (tester) async {
      final fakeGames = [
        const GameEntity(
          packageName: 'com.studio.spacewar',
          appName: 'Space War Pro',
          versionName: '1.4.2',
        ),
        const GameEntity(
          packageName: 'com.studio.speedracer',
          appName: 'Speed Racer',
          versionName: '3.0.0',
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          const GamesScreen(),
          overrides: [
            gameRepositoryProvider.overrideWithValue(FakeGameRepository(fakeGames)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open search bar
      await tester.tap(find.byTooltip('Search Games'));
      await tester.pumpAndSettle();

      // Enter search term matching only Speed Racer
      await tester.enterText(find.byType(TextField), 'speed');
      await tester.pumpAndSettle();

      expect(find.text('Speed Racer'), findsOneWidget);
      expect(find.text('Space War Pro'), findsNothing);

      // Search term matching nothing
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No matching games found'), findsOneWidget);
    });

    testWidgets('Tapping game card opens GameDetailSheet with profile hierarchy', (tester) async {
      final fakeGames = [
        const GameEntity(
          packageName: 'com.studio.spacewar',
          appName: 'Space War Pro',
          versionName: '1.4.2',
          confidence: GameConfidence.high,
          confidenceScore: 0.95,
          classificationReasons: ['Declared CATEGORY_GAME in manifest'],
        ),
      ];

      final inMemoryProfileRepo = InMemoryGameProfileRepository();

      await tester.pumpWidget(
        _buildTestApp(
          const GamesScreen(),
          overrides: [
            gameRepositoryProvider.overrideWithValue(FakeGameRepository(fakeGames)),
            gameProfileRepositoryProvider.overrideWithValue(inMemoryProfileRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the card
      await tester.tap(find.text('Space War Pro'));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible showing the new profile hierarchy
      expect(find.text('PROFILE STATUS'), findsOneWidget);
      expect(find.text('AVAILABLE CATEGORIES'), findsOneWidget);
      expect(find.text('CURRENT CONFIGURATION'), findsOneWidget);
      // The game name should appear in the sheet header
      expect(find.text('Space War Pro'), findsWidgets);
    });
  });
}
