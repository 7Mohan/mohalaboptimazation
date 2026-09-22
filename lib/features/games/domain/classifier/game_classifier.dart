import 'dart:typed_data';

import '../entities/game_entity.dart';

/// Raw application metadata extracted directly from Android's PackageManager.
class RawAppMetadata {
  const RawAppMetadata({
    required this.packageName,
    required this.appName,
    this.versionName,
    this.versionCode,
    this.isSystemApp = false,
    this.category,
    this.isGameCategory = false,
    this.isGameFlag = false,
    this.hasGameIntent = false,
    this.hasLauncherIntent = false,
    this.firstInstallTime,
    this.lastUpdateTime,
    this.metaDataKeys = const [],
    this.iconBytes,
  });

  factory RawAppMetadata.fromMap(Map<String, dynamic> map) {
    return RawAppMetadata(
      packageName: map['packageName'] as String? ?? 'unknown.package',
      appName: map['appName'] as String? ?? 'Unknown Application',
      versionName: map['versionName'] as String?,
      versionCode: (map['versionCode'] as num?)?.toInt(),
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      category: (map['category'] as num?)?.toInt(),
      isGameCategory: map['isGameCategory'] as bool? ?? false,
      isGameFlag: map['isGameFlag'] as bool? ?? false,
      hasGameIntent: map['hasGameIntent'] as bool? ?? false,
      hasLauncherIntent: map['hasLauncherIntent'] as bool? ?? false,
      firstInstallTime: (map['firstInstallTime'] as num?)?.toInt(),
      lastUpdateTime: (map['lastUpdateTime'] as num?)?.toInt(),
      metaDataKeys: (map['metaDataKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      iconBytes: map['iconBytes'] as Uint8List?,
    );
  }

  final String packageName;
  final String appName;
  final String? versionName;
  final int? versionCode;
  final bool isSystemApp;
  final int? category;
  final bool isGameCategory;
  final bool isGameFlag;
  final bool hasGameIntent;
  final bool hasLauncherIntent;
  final int? firstInstallTime;
  final int? lastUpdateTime;
  final List<String> metaDataKeys;
  final Uint8List? iconBytes;
}

/// Result of game classification containing decision, confidence, and signals.
class GameClassificationResult {
  const GameClassificationResult({
    required this.isGame,
    required this.confidence,
    required this.confidenceScore,
    required this.signals,
  });

  final bool isGame;
  final GameConfidence confidence;
  final double confidenceScore;
  final List<String> signals;
}

/// Abstract contract for game classification engines.
abstract class GameClassifier {
  GameClassificationResult classify(RawAppMetadata metadata);
}

/// Multi-signal game classifier using standard Android platform metadata.
///
/// Signals evaluated:
/// 1. `ApplicationInfo.CATEGORY_GAME` (API 26+)
/// 2. `ApplicationInfo.FLAG_IS_GAME` (API 21+)
/// 3. `android.intent.category.GAME` intent resolution
/// 4. Game framework / engine manifest metadata (Unity, Unreal, Godot, Google Play Games SDK)
/// 5. Negative weighting for background system services without launch points
class DefaultGameClassifier implements GameClassifier {
  const DefaultGameClassifier({
    this.highThreshold = 0.60,
    this.mediumThreshold = 0.40,
    this.lowThreshold = 0.25,
  });

  final double highThreshold;
  final double mediumThreshold;
  final double lowThreshold;

  static const List<String> _gameEngineMetadataKeys = [
    'unity.build-id',
    'unity.player_activity',
    'com.google.android.gms.games.APP_ID',
    'unreal.build-id',
    'epicgames.build-id',
    'godot.version',
  ];

  @override
  GameClassificationResult classify(RawAppMetadata metadata) {
    double score = 0.0;
    final signals = <String>[];

    // Signal 1: Android Oreo+ CATEGORY_GAME attribute
    if (metadata.isGameCategory || metadata.category == 0) {
      score += 0.75;
      signals.add('Application category declared as CATEGORY_GAME (API 26+)');
    }

    // Signal 2: Legacy FLAG_IS_GAME attribute
    if (metadata.isGameFlag) {
      score += 0.70;
      signals.add('Application flag FLAG_IS_GAME set in manifest');
    }

    // Signal 3: Intent activity declares android.intent.category.GAME
    if (metadata.hasGameIntent) {
      score += 0.50;
      signals.add('Resolves android.intent.category.GAME activity intent');
    }

    // Signal 4: Known game runtime / engine metadata
    final matchingEngineKeys = metadata.metaDataKeys.where((key) {
      final lowerKey = key.toLowerCase();
      return _gameEngineMetadataKeys.any((marker) => lowerKey.contains(marker.toLowerCase()));
    }).toList();

    if (matchingEngineKeys.isNotEmpty) {
      score += 0.60;
      signals.add('Game engine / Play Games service metadata detected (${matchingEngineKeys.length} markers)');
    }

    // Negative heuristic: System packages with no game declarations
    if (metadata.isSystemApp && !metadata.isGameCategory && !metadata.isGameFlag && !metadata.hasGameIntent) {
      score -= 0.50;
    }

    // Negative heuristic: Packages with no launcher capability and no explicit game attributes
    if (!metadata.hasLauncherIntent && !metadata.isGameCategory && !metadata.isGameFlag) {
      score -= 0.40;
    }

    final finalScore = score.clamp(0.0, 1.0);

    if (finalScore >= highThreshold) {
      return GameClassificationResult(
        isGame: true,
        confidence: GameConfidence.high,
        confidenceScore: finalScore,
        signals: signals,
      );
    } else if (finalScore >= mediumThreshold) {
      return GameClassificationResult(
        isGame: true,
        confidence: GameConfidence.medium,
        confidenceScore: finalScore,
        signals: signals,
      );
    } else if (finalScore >= lowThreshold) {
      return GameClassificationResult(
        isGame: true,
        confidence: GameConfidence.low,
        confidenceScore: finalScore,
        signals: signals,
      );
    } else {
      return GameClassificationResult(
        isGame: false,
        confidence: GameConfidence.low,
        confidenceScore: finalScore,
        signals: signals,
      );
    }
  }
}
