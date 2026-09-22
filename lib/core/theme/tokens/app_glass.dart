import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Defines the visual depth levels for the Moha Lab Glassmorphism System.
enum AppGlassLevel {
  /// Level 1: Flat Background / Canvas (OLED-black / deep slate, 0 blur, 60-120fps scrolling).
  level1,

  /// Level 2: Base Glass for standard cards, panels, system metric tiles (10-12px blur, 7% surface, 16px radius).
  level2,

  /// Level 3: Elevated Glass for interactive/active elements (18px blur, 12% surface with cobalt tint, 20px radius).
  level3,

  /// Level 4: Floating Glass for modal bottom sheets, dialogs, floating action bars (28px blur, 24px radius, specular highlight).
  level4,
}

/// Token constants and style resolvers for the 4-Level Glass Design System.
abstract final class AppGlass {
  // Blur values
  static const double blurLevel1 = 0.0;
  static const double blurLevel2 = 12.0;
  static const double blurLevel3 = 18.0;
  static const double blurLevel4 = 28.0;

  // Corner radii
  static const double radiusLevel1 = 0.0;
  static const double radiusLevel2 = 16.0;
  static const double radiusLevel3 = 20.0;
  static const double radiusLevel4 = 24.0;

  /// Returns blur sigma according to [level].
  static double blurFor(AppGlassLevel level) {
    switch (level) {
      case AppGlassLevel.level1:
        return blurLevel1;
      case AppGlassLevel.level2:
        return blurLevel2;
      case AppGlassLevel.level3:
        return blurLevel3;
      case AppGlassLevel.level4:
        return blurLevel4;
    }
  }

  /// Returns corner radius according to [level].
  static double radiusFor(AppGlassLevel level) {
    switch (level) {
      case AppGlassLevel.level1:
        return radiusLevel1;
      case AppGlassLevel.level2:
        return radiusLevel2;
      case AppGlassLevel.level3:
        return radiusLevel3;
      case AppGlassLevel.level4:
        return radiusLevel4;
    }
  }

  /// Resolves surface fill color based on brightness and [level].
  static Color surfaceColor(BuildContext context, AppGlassLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case AppGlassLevel.level1:
        return isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      case AppGlassLevel.level2:
        return isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04);
      case AppGlassLevel.level3:
        return isDark
            ? const Color(0xFF1E56DE).withOpacity(0.08)
            : AppColors.primary.withOpacity(0.05);
      case AppGlassLevel.level4:
        return isDark
            ? const Color(0xFF111724).withOpacity(0.90)
            : Colors.white.withOpacity(0.92);
    }
  }

  /// Resolves specular border gradient based on brightness and [level].
  static Gradient? borderGradient(BuildContext context, AppGlassLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case AppGlassLevel.level1:
        return null;
      case AppGlassLevel.level2:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.14),
                  Colors.white.withOpacity(0.04),
                ]
              : [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.02),
                ],
        );
      case AppGlassLevel.level3:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withOpacity(0.35),
                  Colors.white.withOpacity(0.08),
                ]
              : [
                  AppColors.primary.withOpacity(0.30),
                  Colors.black.withOpacity(0.04),
                ],
        );
      case AppGlassLevel.level4:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.06),
                ]
              : [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.04),
                ],
        );
    }
  }

  /// Resolves box shadow based on [level].
  static List<BoxShadow>? shadowsFor(BuildContext context, AppGlassLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case AppGlassLevel.level1:
        return null;
      case AppGlassLevel.level2:
        return isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ];
      case AppGlassLevel.level3:
        return [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.08),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ];
      case AppGlassLevel.level4:
        return [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.50) : Colors.black.withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ];
    }
  }
}
