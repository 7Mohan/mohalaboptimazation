import 'package:flutter/material.dart';

/// Represents a user's theme preference.
enum ThemePreference {
  system,
  light,
  dark,
  amoled;

  ThemeMode get themeMode => switch (this) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.amoled => ThemeMode.dark, // AMOLED uses dark mode base
      };

  String get label => switch (this) {
        ThemePreference.system => 'Follow system',
        ThemePreference.light => 'Light',
        ThemePreference.dark => 'Dark',
        ThemePreference.amoled => 'AMOLED Black',
      };

  String get description => switch (this) {
        ThemePreference.system => 'Matches your system setting',
        ThemePreference.light => 'Light background',
        ThemePreference.dark => 'Dark surface colors',
        ThemePreference.amoled => 'Pure black — saves battery on OLED screens',
      };
}

