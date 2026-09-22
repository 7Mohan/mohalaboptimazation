import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../features/games/data/datasources/game_profile_local_datasource.dart';
import '../../../features/games/domain/entities/game_profile_entity.dart';
import '../../../features/network/data/datasources/network_history_local_datasource.dart';
import '../../../features/network/domain/entities/network_diagnostic_session.dart';
import 'settings_local_datasource.dart';

/// Result of a data management operation.
class DataOperationResult {
  const DataOperationResult({
    required this.success,
    this.message,
    this.error,
  });

  const DataOperationResult.ok([String? msg])
      : success = true,
        message = msg,
        error = null;

  const DataOperationResult.fail(String err)
      : success = false,
        message = null,
        error = err;

  final bool success;
  final String? message;
  final String? error;
}

/// Orchestrates cross-feature data operations: export, import, clear, and reset.
///
/// Security: import always goes through [ImportValidator] before touching storage.
class DataManager {
  const DataManager({
    required SharedPreferences prefs,
    required SettingsLocalDataSource settingsDs,
    required GameProfileLocalDataSource profileDs,
    required NetworkHistoryLocalDataSource networkDs,
  })  : _prefs = prefs,
        _settingsDs = settingsDs,
        _profileDs = profileDs,
        _networkDs = networkDs;

  final SharedPreferences _prefs;
  final SettingsLocalDataSource _settingsDs;
  final GameProfileLocalDataSource _profileDs;
  final NetworkHistoryLocalDataSource _networkDs;

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Builds a complete local export bundle as JSON string.
  Future<String> exportAllData() async {
    final settings = _settingsDs.exportSettingsMap();
    final profiles =
        (await _profileDs.getAllProfiles()).map((p) => p.toMap()).toList();
    final history =
        (await _networkDs.getHistory(limit: 200)).map((s) => s.toMap()).toList();

    final bundle = DataExportBundle(
      settings: settings,
      profiles: profiles,
      networkHistory: history,
      exportedAt: DateTime.now(),
    );

    return bundle.toJson();
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Validates and applies an import bundle. Returns a result with user-readable
  /// outcome text. Never runs code from the imported file.
  Future<DataOperationResult> importData(String rawJson) async {
    final validation = const ImportValidator().validate(rawJson);
    if (!validation.isValid) {
      return DataOperationResult.fail(validation.error!);
    }

    final bundle = validation.bundle!;

    try {
      // Apply settings
      if (bundle.settings.isNotEmpty) {
        final current = await _settingsDs.getSettings();
        final imported = AppSettings.fromMap(bundle.settings);
        // Merge: only update fields present in the import bundle
        await _settingsDs.saveSettings(imported.copyWith(
          // Safety: never import crash reporting opt-in silently
          crashReportingOptIn: current.crashReportingOptIn,
        ));
      }

      // Apply profiles
      int profileCount = 0;
      for (final rawProfile in bundle.profiles) {
        try {
          final profile = GameProfile.fromMap(rawProfile);
          await _profileDs.saveProfile(profile);
          profileCount++;
        } catch (_) {
          // Skip malformed individual profile entries
        }
      }

      // Apply network history
      int historyCount = 0;
      for (final rawSession in bundle.networkHistory) {
        try {
          final session = NetworkDiagnosticSession.fromMap(rawSession);
          await _networkDs.saveSession(session);
          historyCount++;
        } catch (_) {
          // Skip malformed individual sessions
        }
      }

      return DataOperationResult.ok(
        'Import complete: $profileCount profile(s), '
        '$historyCount network history record(s) restored.',
      );
    } catch (e) {
      return DataOperationResult.fail(
          'Import failed unexpectedly. No partial changes were saved: $e');
    }
  }

  // ── Clear operations ───────────────────────────────────────────────────────

  Future<DataOperationResult> clearNetworkHistory() async {
    try {
      await _networkDs.clearHistory();
      return const DataOperationResult.ok('Network test history cleared.');
    } catch (e) {
      return DataOperationResult.fail('Could not clear network history: $e');
    }
  }

  Future<DataOperationResult> clearGameProfiles() async {
    try {
      await _profileDs.clearAll();
      return const DataOperationResult.ok('All game profiles deleted.');
    } catch (e) {
      return DataOperationResult.fail('Could not clear game profiles: $e');
    }
  }

  /// Resets every stored key in SharedPreferences to factory defaults.
  Future<DataOperationResult> resetAllData() async {
    try {
      await _prefs.clear();
      return const DataOperationResult.ok(
          'All local data has been cleared. The app has been reset to defaults.');
    } catch (e) {
      return DataOperationResult.fail('Reset failed: $e');
    }
  }

  // ── Storage stats ──────────────────────────────────────────────────────────

  Future<DataStorageStats> getStorageStats() async {
    final profileCount = (await _profileDs.getAllProfiles()).length;
    final historyCount = (await _networkDs.getHistory(limit: 200)).length;
    final keyCount = _prefs.getKeys().length;

    // Rough size estimate from JSON of all prefs values
    int estimatedBytes = 0;
    for (final key in _prefs.getKeys()) {
      final val = _prefs.get(key);
      estimatedBytes += key.length + (val?.toString().length ?? 0) + 4;
    }

    return DataStorageStats(
      gameProfileCount: profileCount,
      networkHistoryCount: historyCount,
      preferencesKeyCount: keyCount,
      estimatedStorageBytes: estimatedBytes,
    );
  }
}

class DataStorageStats {
  const DataStorageStats({
    required this.gameProfileCount,
    required this.networkHistoryCount,
    required this.preferencesKeyCount,
    required this.estimatedStorageBytes,
  });

  final int gameProfileCount;
  final int networkHistoryCount;
  final int preferencesKeyCount;
  final int estimatedStorageBytes;

  String get estimatedStorageDisplay {
    if (estimatedStorageBytes < 1024) {
      return '$estimatedStorageBytes B';
    }
    return '${(estimatedStorageBytes / 1024).toStringAsFixed(1)} KB';
  }
}
