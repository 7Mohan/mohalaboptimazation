import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/theme_preference.dart';

/// Extended local data source that persists every [AppSettings] field.
/// Backwards-compatible: theme key matches the existing `prefThemeMode` key.
class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  // ── Key constants ──────────────────────────────────────────────────────────
  static const _kTheme = 'theme_mode'; // existing key — keep unchanged
  static const _kLanguage = 'pref_language';
  static const _kNotifications = 'pref_notifications_enabled';
  static const _kDefaultOptBehaviour = 'pref_default_opt_behaviour';
  static const _kPerfMonMode = 'pref_perf_mon_mode';
  static const _kNetAutoRun = 'pref_net_auto_run';
  static const _kCrashReporting = 'pref_crash_reporting_opt_in';

  // ── Full settings read/write ───────────────────────────────────────────────

  AppSettings getSettingsSync() {
    return AppSettings(
      theme: _enumFrom(ThemePreference.values,
          _prefs.getString(_kTheme), ThemePreference.system),
      language: _enumFrom(LanguagePreference.values,
          _prefs.getString(_kLanguage), LanguagePreference.systemDefault),
      notificationsEnabled: _prefs.getBool(_kNotifications) ?? true,
      defaultOptimizationBehaviour: _enumFrom(
          DefaultOptimizationBehaviour.values,
          _prefs.getString(_kDefaultOptBehaviour),
          DefaultOptimizationBehaviour.askEveryTime),
      performanceMonitoringMode: _enumFrom(
          PerformanceMonitoringMode.values,
          _prefs.getString(_kPerfMonMode),
          PerformanceMonitoringMode.balanced),
      networkTestAutoRun: _enumFrom(NetworkTestAutoRun.values,
          _prefs.getString(_kNetAutoRun), NetworkTestAutoRun.never),
      crashReportingOptIn: _prefs.getBool(_kCrashReporting) ?? false,
    );
  }

  Future<AppSettings> getSettings() async => getSettingsSync();

  Future<void> saveSettings(AppSettings s) async {
    await _prefs.setString(_kTheme, s.theme.name);
    await _prefs.setString(_kLanguage, s.language.name);
    await _prefs.setBool(_kNotifications, s.notificationsEnabled);
    await _prefs.setString(
        _kDefaultOptBehaviour, s.defaultOptimizationBehaviour.name);
    await _prefs.setString(_kPerfMonMode, s.performanceMonitoringMode.name);
    await _prefs.setString(_kNetAutoRun, s.networkTestAutoRun.name);
    await _prefs.setBool(_kCrashReporting, s.crashReportingOptIn);
  }

  // ── Single-field legacy helpers (kept for ThemeNotifier compatibility) ─────

  Future<ThemePreference> getThemePreference() async {
    return _enumFrom(ThemePreference.values,
        _prefs.getString(_kTheme), ThemePreference.system);
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    await _prefs.setString(_kTheme, preference.name);
  }

  // ── Export / Import ────────────────────────────────────────────────────────

  /// Serialises only the settings map (not profile or history data).
  Map<String, dynamic> exportSettingsMap() => getSettingsSync().toMap();

  static const _settingsKeys = {
    _kTheme, _kLanguage, _kNotifications,
    _kDefaultOptBehaviour, _kPerfMonMode, _kNetAutoRun, _kCrashReporting,
  };

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> clearSettings() async {
    for (final key in _settingsKeys) {
      await _prefs.remove(key);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static T _enumFrom<T extends Enum>(
      List<T> values, String? raw, T fallback) {
    if (raw == null) return fallback;
    return values.firstWhere((e) => e.name == raw, orElse: () => fallback);
  }
}

/// Result of a data export operation.
class DataExportBundle {
  const DataExportBundle({
    required this.settings,
    required this.profiles,
    required this.networkHistory,
    required this.exportedAt,
    this.schemaVersion = 1,
  });

  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> profiles;
  final List<Map<String, dynamic>> networkHistory;
  final DateTime exportedAt;
  final int schemaVersion;

  Map<String, dynamic> toMap() => {
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'appId': 'com.mohalab.optimization',
        'settings': settings,
        'profiles': profiles,
        'networkHistory': networkHistory,
      };

  String toJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}

/// Validation result from an import attempt.
class ImportValidationResult {
  const ImportValidationResult({
    required this.isValid,
    this.error,
    this.bundle,
  });

  const ImportValidationResult.ok(DataExportBundle b)
      : isValid = true,
        error = null,
        bundle = b;

  const ImportValidationResult.fail(String e)
      : isValid = false,
        error = e,
        bundle = null;

  final bool isValid;
  final String? error;
  final DataExportBundle? bundle;
}

/// Validates and parses a raw JSON string produced by [DataExportBundle.toJson].
///
/// Security: never evaluates code; only parses known JSON keys.
class ImportValidator {
  const ImportValidator();

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB hard cap
  static const int _maxProfiles = 500;
  static const int _maxNetworkHistory = 1000;

  ImportValidationResult validate(String rawJson) {
    // Size guard
    if (rawJson.length > _maxFileSizeBytes) {
      return const ImportValidationResult.fail(
          'File is too large to import (max 5 MB). '
          'This is not a valid Moha Lab export file.');
    }

    // JSON parse guard
    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const ImportValidationResult.fail(
            'Import file is not a valid JSON object.');
      }
      map = decoded;
    } catch (_) {
      return const ImportValidationResult.fail(
          'Could not parse the file. It may be corrupted or not a '
          'Moha Lab export.');
    }

    // App identity guard
    final appId = map['appId'];
    if (appId != 'com.mohalab.optimization') {
      return const ImportValidationResult.fail(
          'This file was not exported from Moha Lab Optimization. '
          'Import cancelled for safety.');
    }

    // Schema version guard
    final schemaVersion = map['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1 || schemaVersion > 10) {
      return const ImportValidationResult.fail(
          'Unrecognised file version. Please export again from a '
          'current version of the app.');
    }

    // Settings field type validation
    final settings = map['settings'];
    if (settings != null && settings is! Map) {
      return const ImportValidationResult.fail(
          'Settings block has an invalid format.');
    }

    // Profiles list validation
    final profiles = map['profiles'];
    if (profiles != null) {
      if (profiles is! List) {
        return const ImportValidationResult.fail(
            'Profiles block has an invalid format.');
      }
      if (profiles.length > _maxProfiles) {
        return const ImportValidationResult.fail(
            'Import contains too many profiles (max $_maxProfiles). '
            'File may be malformed.');
      }
      for (final p in profiles) {
        if (p is! Map) {
          return const ImportValidationResult.fail(
              'One or more profile entries are malformed.');
        }
        if (p['gamePackage'] is! String || p['gameName'] is! String) {
          return const ImportValidationResult.fail(
              'A profile entry is missing required fields '
              '(gamePackage, gameName).');
        }
      }
    }

    // Network history list validation
    final history = map['networkHistory'];
    if (history != null) {
      if (history is! List) {
        return const ImportValidationResult.fail(
            'Network history block has an invalid format.');
      }
      if (history.length > _maxNetworkHistory) {
        return const ImportValidationResult.fail(
            'Import contains too many history entries (max $_maxNetworkHistory).');
      }
    }

    // Parse timestamp
    DateTime? exportedAt;
    final rawDate = map['exportedAt'];
    if (rawDate is String) exportedAt = DateTime.tryParse(rawDate);

    final bundle = DataExportBundle(
      settings:
          (settings as Map?)?.cast<String, dynamic>() ?? const {},
      profiles: (profiles as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          [],
      networkHistory: (history as List?)
              ?.whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList() ??
          [],
      exportedAt: exportedAt ?? DateTime.now(),
      schemaVersion: schemaVersion,
    );

    return ImportValidationResult.ok(bundle);
  }
}
