import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography definitions for Moha Lab Optimization.
///
/// - Headlines: Outfit (geometric, technical feel)
/// - Body/Labels: Inter (highly readable, neutral)
///
/// Fully offline-first and test-safe: when runtime network fetching is disabled
/// (such as during tests or in strict offline environments), clean system font
/// fallbacks with identical scale, weight, and tracking are used.
abstract final class AppTypography {
  /// Base [TextTheme] using Outfit for display/headline and Inter for body.
  static TextTheme get textTheme {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return _fallbackTextTheme;
    }
    try {
      return _buildGoogleFontsTextTheme();
    } catch (_) {
      return _fallbackTextTheme;
    }
  }

  static TextTheme _buildGoogleFontsTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      // Body uses Inter
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static const TextTheme _fallbackTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFamilyFallback: ['Roboto', 'sans-serif'],
    ),
  );

  /// Monospace technical style for system specs, package names, and memory addresses
  static TextStyle monoStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Roboto Mono', 'Courier New', 'monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0,
      color: color,
    );
  }
}

