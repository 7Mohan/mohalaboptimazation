import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/datasources/local/settings_local_datasource.dart';
import '../../../../data/repositories/user_preferences_repository_impl.dart';
import '../../../../domain/entities/theme_preference.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Provides the SharedPreferences instance.
/// Must be overridden with the real instance at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialised'),
  name: 'sharedPreferencesProvider',
);

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(ref.watch(sharedPreferencesProvider)),
  name: 'settingsLocalDataSourceProvider',
);

final userPreferencesRepositoryProvider = Provider<UserPreferencesRepositoryImpl>(
  (ref) => UserPreferencesRepositoryImpl(
    ref.watch(settingsLocalDataSourceProvider),
  ),
  name: 'userPreferencesRepositoryProvider',
);

// ---------------------------------------------------------------------------
// Theme state
// ---------------------------------------------------------------------------

/// Notifier that reads and persists the user's theme preference.
class ThemeNotifier extends AsyncNotifier<ThemePreference> {
  @override
  Future<ThemePreference> build() async {
    final repo = ref.watch(userPreferencesRepositoryProvider);
    return repo.getThemePreference();
  }

  Future<void> setTheme(ThemePreference preference) async {
    final repo = ref.read(userPreferencesRepositoryProvider);
    await repo.setThemePreference(preference);
    state = AsyncValue.data(preference);
  }
}

final themeNotifierProvider =
    AsyncNotifierProvider<ThemeNotifier, ThemePreference>(
  ThemeNotifier.new,
  name: 'themeNotifierProvider',
);

/// Convenience provider that resolves [ThemeMode] from the current preference.
final themeModeProvider = Provider<ThemeMode>(
  (ref) {
    final themeAsync = ref.watch(themeNotifierProvider);
    return themeAsync.when(
      data: (pref) => pref.themeMode,
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );
  },
  name: 'themeModeProvider',
);
