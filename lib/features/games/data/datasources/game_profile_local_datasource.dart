import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/game_profile_entity.dart';

/// Local data source persisting game profiles in [SharedPreferences].
class GameProfileLocalDataSource {
  const GameProfileLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _indexKey = 'mohalab_profile_index';
  static const String _profilePrefix = 'mohalab_profile_';

  String _keyForPackage(String packageName) => '$_profilePrefix$packageName';

  /// Retrieves a saved profile for a package, or null if absent.
  Future<GameProfile?> getProfile(String packageName) async {
    final raw = _prefs.getString(_keyForPackage(packageName));
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GameProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves all saved game profiles.
  Future<List<GameProfile>> getAllProfiles() async {
    final index = _prefs.getStringList(_indexKey) ?? const [];
    final profiles = <GameProfile>[];

    for (final pkg in index) {
      final profile = await getProfile(pkg);
      if (profile != null) {
        profiles.add(profile);
      }
    }

    return profiles;
  }

  /// Persists a game profile and updates the index.
  Future<void> saveProfile(GameProfile profile) async {
    final key = _keyForPackage(profile.gamePackage);
    await _prefs.setString(key, profile.toJson());

    final index = (_prefs.getStringList(_indexKey) ?? <String>[]).toSet();
    if (!index.contains(profile.gamePackage)) {
      index.add(profile.gamePackage);
      await _prefs.setStringList(_indexKey, index.toList());
    }
  }

  /// Removes a profile and clears it from the index.
  Future<void> deleteProfile(String packageName) async {
    await _prefs.remove(_keyForPackage(packageName));

    final index = (_prefs.getStringList(_indexKey) ?? <String>[]).toSet();
    if (index.contains(packageName)) {
      index.remove(packageName);
      await _prefs.setStringList(_indexKey, index.toList());
    }
  }

  /// Clears all saved profiles.
  Future<void> clearAll() async {
    final index = _prefs.getStringList(_indexKey) ?? const [];
    for (final pkg in index) {
      await _prefs.remove(_keyForPackage(pkg));
    }
    await _prefs.remove(_indexKey);
  }
}
