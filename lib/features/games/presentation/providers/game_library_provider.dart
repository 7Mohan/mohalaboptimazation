import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/presentation/providers/theme_provider.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/services/game_stats_service.dart';
import '../../domain/classifier/game_classifier.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/repositories/game_repository.dart';

/// Key for storing manually added games
const _kManualGamesKey = 'user_manual_games_v1';
/// Key for storing package names removed/hidden by the user
const _kHiddenGamesKey = 'user_hidden_games_v1';

/// Provides the active [GameClassifier] instance.
final gameClassifierProvider = Provider<GameClassifier>((ref) {
  return const DefaultGameClassifier();
});

/// Provides the [GameRepository] instance.
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final classifier = ref.watch(gameClassifierProvider);
  return GameRepositoryImpl(classifier: classifier);
});

/// Async controller managing game discovery lifecycle.
class GameLibraryController extends AsyncNotifier<List<GameEntity>> {
  @override
  Future<List<GameEntity>> build() async {
    return _fetchGames(forceRefresh: false);
  }

  Future<List<GameEntity>> _fetchGames({required bool forceRefresh}) async {
    final repo = ref.read(gameRepositoryProvider);
    final detected = await repo.getInstalledGames(forceRefresh: forceRefresh);
    
    SharedPreferences? prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } catch (_) {}

    if (prefs == null) {
      return detected;
    }

    // Read hidden packages
    final hiddenList = prefs.getStringList(_kHiddenGamesKey) ?? [];
    final hiddenSet = hiddenList.toSet();

    // Read manual games
    final manualRaw = prefs.getStringList(_kManualGamesKey) ?? [];
    final manualGames = <GameEntity>[];
    for (final raw in manualRaw) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        manualGames.add(GameEntity(
          packageName: map['packageName'] as String,
          appName: map['appName'] as String,
          statusLabel: 'Manual Add',
        ));
      } catch (_) {}
    }

    final combined = <String, GameEntity>{};
    for (final g in detected) {
      if (!hiddenSet.contains(g.packageName)) {
        combined[g.packageName] = g;
      }
    }
    for (final m in manualGames) {
      if (!hiddenSet.contains(m.packageName) && !combined.containsKey(m.packageName)) {
        combined[m.packageName] = m;
      }
    }

    return combined.values.toList();
  }

  /// Forces a fresh scan of installed packages on the device.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGames(forceRefresh: true));
  }

  /// Adds a game manually by package name and display title.
  Future<void> addManualGame({
    required String packageName,
    required String appName,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } catch (_) {}

    if (prefs != null) {
      final manualRaw = prefs.getStringList(_kManualGamesKey) ?? [];
      
      // Remove if previously hidden
      final hiddenList = prefs.getStringList(_kHiddenGamesKey) ?? [];
      if (hiddenList.contains(packageName)) {
        hiddenList.remove(packageName);
        await prefs.setStringList(_kHiddenGamesKey, hiddenList);
      }

      // Append to manual
      final exists = manualRaw.any((r) => r.contains(packageName));
      if (!exists) {
        final jsonStr = jsonEncode({'packageName': packageName, 'appName': appName});
        manualRaw.add(jsonStr);
        await prefs.setStringList(_kManualGamesKey, manualRaw);
      }
    }

    await refresh();
  }

  /// Removes or hides a game from the active library.
  Future<void> removeGame(String packageName) async {
    SharedPreferences? prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } catch (_) {}

    if (prefs != null) {
      // Remove from manual if present
      final manualRaw = prefs.getStringList(_kManualGamesKey) ?? [];
      manualRaw.removeWhere((r) => r.contains(packageName));
      await prefs.setStringList(_kManualGamesKey, manualRaw);

      // Add to hidden set so detected list also hides it
      final hiddenList = prefs.getStringList(_kHiddenGamesKey) ?? [];
      if (!hiddenList.contains(packageName)) {
        hiddenList.add(packageName);
        await prefs.setStringList(_kHiddenGamesKey, hiddenList);
      }
    }

    await refresh();
  }

  /// Launches a game by package name and tracks stats.
  Future<bool> launchGame(String packageName) async {
    final repo = ref.read(gameRepositoryProvider);
    final statsService = ref.read(gameStatsServiceProvider);
    await statsService.recordLaunch(packageName);
    return repo.launchGame(packageName);
  }
}

/// Controller provider for the game library list.
final gameLibraryControllerProvider =
    AsyncNotifierProvider<GameLibraryController, List<GameEntity>>(
  GameLibraryController.new,
);

/// State provider for real-time game search query.
final gameSearchQueryProvider = StateProvider<String>((ref) => '');

/// State provider for game sorting order.
final gameSortOrderProvider =
    StateProvider<GameSortOrder>((ref) => GameSortOrder.nameAsc);

/// Filtered and sorted list of games derived from library state, query, and sort order.
final filteredGamesProvider = Provider<AsyncValue<List<GameEntity>>>((ref) {
  final gamesAsync = ref.watch(gameLibraryControllerProvider);
  final query = ref.watch(gameSearchQueryProvider).trim().toLowerCase();
  final sortOrder = ref.watch(gameSortOrderProvider);

  return gamesAsync.whenData((games) {
    var list = List<GameEntity>.from(games);

    if (query.isNotEmpty) {
      list = list.where((game) {
        final matchesName = game.appName.toLowerCase().contains(query);
        final matchesPackage = game.packageName.toLowerCase().contains(query);
        return matchesName || matchesPackage;
      }).toList();
    }

    switch (sortOrder) {
      case GameSortOrder.nameAsc:
        list.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
        break;
      case GameSortOrder.nameDesc:
        list.sort((a, b) => b.appName.toLowerCase().compareTo(a.appName.toLowerCase()));
        break;
      case GameSortOrder.installDate:
        list.sort((a, b) {
          final dateA = a.installedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.installedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });
        break;
      case GameSortOrder.confidence:
        list.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
        break;
    }

    return list;
  });
});
