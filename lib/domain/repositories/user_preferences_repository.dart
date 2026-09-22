import '../entities/theme_preference.dart';

/// Abstract contract for persisting user preferences.
abstract interface class UserPreferencesRepository {
  Future<ThemePreference> getThemePreference();
  Future<void> setThemePreference(ThemePreference preference);
}
