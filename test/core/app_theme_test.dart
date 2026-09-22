import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme', () {
    test('light theme has correct brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('dark theme has correct brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('light theme uses Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('light theme primary color matches brand', () {
      // Primary should be close to #1A6BFF
      final primary = AppTheme.light.colorScheme.primary;
      expect(primary.blue, greaterThan(200));
    });

    test('light and dark themes are distinct', () {
      expect(AppTheme.light.brightness, isNot(AppTheme.dark.brightness));
    });
  });
}
