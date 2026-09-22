import 'package:mohalab_optimization/core/errors/exceptions.dart';
import 'package:mohalab_optimization/core/utils/logger.dart';
import 'package:mohalab_optimization/data/datasources/local/settings_local_datasource.dart';
import 'package:mohalab_optimization/domain/entities/app_settings.dart';
import 'package:mohalab_optimization/domain/entities/theme_preference.dart';
import 'package:mohalab_optimization/domain/repositories/user_preferences_repository.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  const UserPreferencesRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  Future<ThemePreference> getThemePreference() async {
    try {
      return await _dataSource.getThemePreference();
    } on LocalStorageException catch (e) {
      AppLogger.warning('Could not read theme preference, using default',
          error: e);
      return ThemePreference.system;
    }
  }

  @override
  Future<void> setThemePreference(ThemePreference preference) async {
    try {
      await _dataSource.setThemePreference(preference);
    } on LocalStorageException catch (e) {
      AppLogger.error('Could not save theme preference', error: e);
    }
  }

  Future<AppSettings> getSettings() => _dataSource.getSettings();

  Future<void> saveSettings(AppSettings settings) =>
      _dataSource.saveSettings(settings);
}
