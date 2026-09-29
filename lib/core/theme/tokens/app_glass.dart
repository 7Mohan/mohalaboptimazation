import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Visual depth levels for the Moha Lab glass system.
enum AppGlassLevel {
  /// Level 1: the canvas itself — no surface.
  level1,

  /// Level 2: standard glass panel (cards, list groups, metric tiles).
  level2,

  /// Level 3: raised / accented glass for interactive or active elements.
  level3,

  /// Level 4: floating chrome (nav bar, sheets, dialogs) — the only level
  /// that uses a real backdrop blur.
  level4,
}

/// Tokens and resolvers for the glass design system.
///
/// Performance rule: a live [BackdropFilter] re-renders everything beneath
/// it every frame. Panels sit over a smooth ambient gradient, where a blur is
/// visually indistinguishable from none — so only floating chrome (level 4)
/// blurs. Panels get their depth from translucency, a specular hairline and
/// soft shadow instead, which keeps scrolling at full refresh rate.
abstract final class AppGlass {
  static const double blurLevel1 = 0.0;
  static const double blurLevel2 = 0.0;
  static const double blurLevel3 = 0.0;
  static const double blurLevel4 = 24.0;

  static const double radiusLevel1 = 0.0;
  static const double radiusLevel2 = 20.0;
  static const double radiusLevel3 = 22.0;
  static const double radiusLevel4 = 28.0;

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static double blurFor(AppGlassLevel level) => switch (level) {
        AppGlassLevel.level1 => blurLevel1,
        AppGlassLevel.level2 => blurLevel2,
        AppGlassLevel.level3 => blurLevel3,
        AppGlassLevel.level4 => blurLevel4,
      };

  static double radiusFor(AppGlassLevel level) => switch (level) {
        AppGlassLevel.level1 => radiusLevel1,
        AppGlassLevel.level2 => radiusLevel2,
        AppGlassLevel.level3 => radiusLevel3,
        AppGlassLevel.level4 => radiusLevel4,
      };

  /// Translucent fill for a glass surface.
  static Color surfaceColor(BuildContext context, AppGlassLevel level) {
    final dark = _dark(context);
    return switch (level) {
      AppGlassLevel.level1 => Colors.transparent,
      AppGlassLevel.level2 => dark
          ? Colors.white.withOpacity(0.055)
          : Colors.white.withOpacity(0.62),
      AppGlassLevel.level3 => dark
          ? const Color(0xFF7AA5FF).withOpacity(0.10)
          : Colors.white.withOpacity(0.78),
      AppGlassLevel.level4 => dark
          ? const Color(0xFF0E1428).withOpacity(0.72)
          : Colors.white.withOpacity(0.74),
    };
  }

  /// Specular hairline: bright at the top-left light source, fading out.
  static Gradient? borderGradient(BuildContext context, AppGlassLevel level) {
    final dark = _dark(context);
    if (level == AppGlassLevel.level1) return null;
    final accent = level == AppGlassLevel.level3;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              (accent ? AppColors.primaryDark : Colors.white)
                  .withOpacity(accent ? 0.55 : 0.20),
              Colors.white.withOpacity(0.04),
              Colors.white.withOpacity(accent ? 0.14 : 0.08),
            ]
          : [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.45),
              (accent ? AppColors.primary : const Color(0xFF8C9AC0))
                  .withOpacity(accent ? 0.35 : 0.22),
            ],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  /// Plain hairline color, for widgets that cannot paint a gradient border.
  static Color hairline(BuildContext context) => _dark(context)
      ? Colors.white.withOpacity(0.09)
      : const Color(0xFF8C9AC0).withOpacity(0.22);

  static List<BoxShadow>? shadowsFor(BuildContext context, AppGlassLevel level) {
    final dark = _dark(context);
    return switch (level) {
      AppGlassLevel.level1 => null,
      AppGlassLevel.level2 => [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.28) : const Color(0xFF3A4A7A).withOpacity(0.07),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      AppGlassLevel.level3 => [
          BoxShadow(
            color: dark ? AppColors.glowAzure.withOpacity(0.16) : AppColors.primary.withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      AppGlassLevel.level4 => [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.45) : const Color(0xFF3A4A7A).withOpacity(0.14),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
    };
  }
}
