import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/presentation/providers/theme_provider.dart';

/// Performance statistics and session history for a specific game.
class GamePlayStats {
  const GamePlayStats({
    required this.packageName,
    this.launchCount = 0,
    this.lastLaunchedAt,
    this.customFpsTarget,
    this.customResolutionScale,
  });

  final String packageName;
  final int launchCount;
  final DateTime? lastLaunchedAt;
  final int? customFpsTarget;
  final double? customResolutionScale;

  Map<String, dynamic> toMap() => {
        'packageName': packageName,
        'launchCount': launchCount,
        'lastLaunchedAt': lastLaunchedAt?.toIso8601String(),
        'customFpsTarget': customFpsTarget,
        'customResolutionScale': customResolutionScale,
      };

  factory GamePlayStats.fromMap(Map<String, dynamic> map) => GamePlayStats(
        packageName: map['packageName'] as String,
        launchCount: (map['launchCount'] as num?)?.toInt() ?? 0,
        lastLaunchedAt: map['lastLaunchedAt'] != null
            ? DateTime.tryParse(map['lastLaunchedAt'] as String)
            : null,
        customFpsTarget: (map['customFpsTarget'] as num?)?.toInt(),
        customResolutionScale:
            (map['customResolutionScale'] as num?)?.toDouble(),
      );

  GamePlayStats copyWith({
    int? launchCount,
    DateTime? lastLaunchedAt,
    int? customFpsTarget,
    double? customResolutionScale,
  }) {
    return GamePlayStats(
      packageName: packageName,
      launchCount: launchCount ?? this.launchCount,
      lastLaunchedAt: lastLaunchedAt ?? this.lastLaunchedAt,
      customFpsTarget: customFpsTarget ?? this.customFpsTarget,
      customResolutionScale:
          customResolutionScale ?? this.customResolutionScale,
    );
  }
}

/// Service to persist per-game stats in SharedPreferences.
class GameStatsService {
  const GameStatsService(this._prefs);

  final SharedPreferences? _prefs;
  static const String _kPrefix = 'game_stats_';

  GamePlayStats getStats(String packageName) {
    final raw = _prefs?.getString('$_kPrefix$packageName');
    if (raw == null) return GamePlayStats(packageName: packageName);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GamePlayStats.fromMap(map);
    } catch (_) {
      return GamePlayStats(packageName: packageName);
    }
  }

  Future<void> recordLaunch(String packageName) async {
    final current = getStats(packageName);
    final updated = current.copyWith(
      launchCount: current.launchCount + 1,
      lastLaunchedAt: DateTime.now(),
    );
    await _prefs?.setString(
        '$_kPrefix$packageName', jsonEncode(updated.toMap()));
  }

  Future<void> updatePreset({
    required String packageName,
    int? customFpsTarget,
    double? customResolutionScale,
  }) async {
    final current = getStats(packageName);
    final updated = current.copyWith(
      customFpsTarget: customFpsTarget,
      customResolutionScale: customResolutionScale,
    );
    await _prefs?.setString(
        '$_kPrefix$packageName', jsonEncode(updated.toMap()));
  }
}

final gameStatsServiceProvider = Provider<GameStatsService>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return GameStatsService(prefs);
});

