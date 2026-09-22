/// Application-wide constants for Moha Lab Optimization.
library;

class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'Moha Lab Optimization';
  static const String brandName = 'MOHA LAB';
  static const String packageName = 'com.mohalab.optimization';
  static const String supportEmail = 'support@mohalab.dev';
  static const String websiteUrl = 'https://mohalab.dev';
  static const String telegramUrl = 'https://t.me/Mohagaminglab';
  static const String tiktokUrl = 'https://www.tiktok.com/@professor0011110?_r=1&_t=ZS-99v0tA6CxRS';

  // Navigation
  static const int homeTabIndex = 0;
  static const int gamesTabIndex = 1;
  static const int optimizationTabIndex = 2;
  static const int diagnosticsTabIndex = 3;
  static const int settingsTabIndex = 4;

  // Shared preferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboardingComplete = 'onboarding_complete';

  // Spacing scale (4pt grid)
  static const double spaceXxs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;
  static const double spaceHuge = 48.0;

  // Border radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  // Minimum Android API required for advanced features
  static const int minAdvancedApiLevel = 29;
}
