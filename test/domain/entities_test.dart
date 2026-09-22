import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/domain/entities/app_info.dart';
import 'package:mohalab_optimization/domain/entities/theme_preference.dart';

void main() {
  group('AppInfo entity', () {
    const appInfo = AppInfo(
      appName: 'Moha Lab Optimization',
      packageName: 'com.mohalab.optimization',
      version: '1.0.0',
      buildNumber: '1',
    );

    test('versionDisplay formats correctly', () {
      expect(appInfo.versionDisplay, 'v1.0.0 (1)');
    });

    test('equality works for identical instances', () {
      const other = AppInfo(
        appName: 'Moha Lab Optimization',
        packageName: 'com.mohalab.optimization',
        version: '1.0.0',
        buildNumber: '1',
      );
      expect(appInfo, equals(other));
    });

    test('inequality for different versions', () {
      const other = AppInfo(
        appName: 'Moha Lab Optimization',
        packageName: 'com.mohalab.optimization',
        version: '2.0.0',
        buildNumber: '2',
      );
      expect(appInfo, isNot(equals(other)));
    });
  });

  group('ThemePreference entity', () {
    test('system maps to ThemeMode.system', () {
      expect(ThemePreference.system.themeMode.name, 'system');
    });

    test('light maps to ThemeMode.light', () {
      expect(ThemePreference.light.themeMode.name, 'light');
    });

    test('dark maps to ThemeMode.dark', () {
      expect(ThemePreference.dark.themeMode.name, 'dark');
    });

    test('all preferences have non-empty labels', () {
      for (final pref in ThemePreference.values) {
        expect(pref.label, isNotEmpty);
      }
    });
  });
}
