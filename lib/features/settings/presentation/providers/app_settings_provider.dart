import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/datasources/local/data_manager.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../games/data/datasources/game_profile_local_datasource.dart';
import '../../../network/data/datasources/network_history_local_datasource.dart';
import '../providers/theme_provider.dart'; // re-exports sharedPreferencesProvider

// ── Infrastructure ────────────────────────────────────────────────────────────

final gameProfileLocalDsProvider = Provider<GameProfileLocalDataSource>((ref) {
  return GameProfileLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final networkHistoryLocalDsProvider =
    Provider<NetworkHistoryLocalDataSource>((ref) {
  return NetworkHistoryLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final dataManagerProvider = Provider<DataManager>((ref) {
  return DataManager(
    prefs: ref.watch(sharedPreferencesProvider),
    settingsDs: ref.watch(settingsLocalDataSourceProvider),
    profileDs: ref.watch(gameProfileLocalDsProvider),
    networkDs: ref.watch(networkHistoryLocalDsProvider),
  );
});

// ── App Settings State ─────────────────────────────────────────────────────────

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final ds = ref.watch(settingsLocalDataSourceProvider);
    return ds.getSettings();
  }

  @override
  Future<AppSettings> update(
    FutureOr<AppSettings> Function(AppSettings) cb, {
    FutureOr<AppSettings> Function(Object err, StackTrace stackTrace)? onError,
  }) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = await cb(current);
    final ds = ref.read(settingsLocalDataSourceProvider);
    await ds.saveSettings(updated);
    state = AsyncValue.data(updated);

    // Keep the existing ThemeNotifier in sync
    ref.read(themeNotifierProvider.notifier).setTheme(updated.theme);
    return updated;
  }

  Future<AppSettings> reload() async {
    final ds = ref.read(settingsLocalDataSourceProvider);
    final loaded = await ds.getSettings();
    state = AsyncValue.data(loaded);
    ref.read(themeNotifierProvider.notifier).setTheme(loaded.theme);
    return loaded;
  }

  Future<void> reset() async {
    final ds = ref.read(settingsLocalDataSourceProvider);
    await ds.clearSettings();
    const defaults = AppSettings();
    state = const AsyncValue.data(defaults);
    ref.read(themeNotifierProvider.notifier).setTheme(defaults.theme);
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

// ── Data Management State ──────────────────────────────────────────────────────

enum DataOpStatus { idle, loading, success, error }

class DataManagementState {
  const DataManagementState({
    this.status = DataOpStatus.idle,
    this.message,
    this.exportedJson,
    this.storageStats,
  });

  final DataOpStatus status;
  final String? message;
  final String? exportedJson;
  final DataStorageStats? storageStats;

  DataManagementState copyWith({
    DataOpStatus? status,
    String? message,
    String? exportedJson,
    DataStorageStats? storageStats,
  }) =>
      DataManagementState(
        status: status ?? this.status,
        message: message ?? this.message,
        exportedJson: exportedJson ?? this.exportedJson,
        storageStats: storageStats ?? this.storageStats,
      );
}

class DataManagementNotifier extends StateNotifier<DataManagementState> {
  DataManagementNotifier(this._ref) : super(const DataManagementState()) {
    loadStats();
  }

  final Ref _ref;
  DataManager get _manager => _ref.read(dataManagerProvider);

  Future<void> loadStats() async {
    final stats = await _manager.getStorageStats();
    state = state.copyWith(storageStats: stats);
  }

  Future<void> exportData() async {
    state = state.copyWith(status: DataOpStatus.loading);
    try {
      final json = await _manager.exportAllData();
      state = state.copyWith(
        status: DataOpStatus.success,
        exportedJson: json,
        message: 'Data exported successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        status: DataOpStatus.error,
        message: 'Export failed: $e',
      );
    }
  }

  Future<void> importData(String rawJson) async {
    state = state.copyWith(status: DataOpStatus.loading);
    final result = await _manager.importData(rawJson);
    if (result.success) {
      // Reload settings from storage after import
      await _ref.read(appSettingsProvider.notifier).reload();
      state = state.copyWith(
        status: DataOpStatus.success,
        message: result.message,
      );
      await loadStats();
    } else {
      state = state.copyWith(
        status: DataOpStatus.error,
        message: result.error,
      );
    }
  }

  Future<void> clearNetworkHistory() async {
    state = state.copyWith(status: DataOpStatus.loading);
    final result = await _manager.clearNetworkHistory();
    state = state.copyWith(
      status: result.success ? DataOpStatus.success : DataOpStatus.error,
      message: result.success ? result.message : result.error,
    );
    await loadStats();
  }

  Future<void> clearGameProfiles() async {
    state = state.copyWith(status: DataOpStatus.loading);
    final result = await _manager.clearGameProfiles();
    state = state.copyWith(
      status: result.success ? DataOpStatus.success : DataOpStatus.error,
      message: result.success ? result.message : result.error,
    );
    await loadStats();
  }

  Future<void> resetAllData() async {
    state = state.copyWith(status: DataOpStatus.loading);
    final result = await _manager.resetAllData();
    if (result.success) {
      // Reload settings to defaults
      await _ref.read(appSettingsProvider.notifier).reset();
    }
    state = state.copyWith(
      status: result.success ? DataOpStatus.success : DataOpStatus.error,
      message: result.success ? result.message : result.error,
    );
    await loadStats();
  }

  void clearStatus() {
    state = state.copyWith(status: DataOpStatus.idle, message: null);
  }
}

final dataManagementProvider =
    StateNotifierProvider<DataManagementNotifier, DataManagementState>((ref) {
  return DataManagementNotifier(ref);
});
