import 'dart:typed_data';

import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../domain/classifier/game_classifier.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/repositories/game_repository.dart';
import '../services/game_discovery_service.dart';

/// Implementation of [GameRepository] that discovers and classifies installed games.
class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({
    GameClassifier? classifier,
  }) : _classifier = classifier ?? const DefaultGameClassifier();

  final GameClassifier _classifier;
  List<GameEntity>? _cachedGames;

  @override
  Future<List<GameEntity>> getInstalledGames({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedGames != null) {
      return _cachedGames!;
    }

    final rawApps = await GameDiscoveryService.fetchInstalledApps(includeIcons: true);

    final games = <GameEntity>[];
    final seenPackages = <String>{};

    for (final raw in rawApps) {
      if (seenPackages.contains(raw.packageName)) continue;

      final classification = _classifier.classify(raw);
      if (classification.isGame) {
        seenPackages.add(raw.packageName);

        DateTime? installedDate;
        if (raw.firstInstallTime != null && raw.firstInstallTime! > 0) {
          installedDate = DateTime.fromMillisecondsSinceEpoch(raw.firstInstallTime!);
        }

        DateTime? updatedDate;
        if (raw.lastUpdateTime != null && raw.lastUpdateTime! > 0) {
          updatedDate = DateTime.fromMillisecondsSinceEpoch(raw.lastUpdateTime!);
        }

        final statusType = classification.confidence == GameConfidence.high
            ? MohaStatusType.safe
            : MohaStatusType.optimal;

        final statusLabel = classification.confidence == GameConfidence.high
            ? 'Optimized'
            : 'Ready';

        games.add(
          GameEntity(
            packageName: raw.packageName,
            appName: raw.appName,
            versionName: raw.versionName,
            versionCode: raw.versionCode,
            iconBytes: raw.iconBytes,
            isSystemApp: raw.isSystemApp,
            category: raw.category,
            installedAt: installedDate,
            lastUpdatedAt: updatedDate,
            confidence: classification.confidence,
            confidenceScore: classification.confidenceScore,
            classificationReasons: classification.signals,
            isInstalled: true,
            statusLabel: statusLabel,
            statusType: statusType,
          ),
        );
      }
    }

    // Default sort: alphabetical by title
    games.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    _cachedGames = games;
    return games;
  }

  @override
  Future<bool> launchGame(String packageName) async {
    return GameDiscoveryService.launchApp(packageName);
  }

  @override
  Future<Uint8List?> getGameIcon(String packageName) async {
    return GameDiscoveryService.fetchAppIcon(packageName);
  }
}
