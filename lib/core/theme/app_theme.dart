import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_sizes.dart';

/// Produces [ThemeData] for the Moha Lab glass design language.
///
/// Scaffolds are transparent so the ambient [GlassBackground] canvas shows
/// through, and the `surfaceContainer*` roles are translucent white — every
/// Material component that uses them (cards, tiles, fields, chips) becomes a
/// glass layer automatically. Floating surfaces (dialogs, sheets, menus) use
/// explicit near-opaque tints so text on them stays legible.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(_lightColorScheme, Brightness.light);
  static ThemeData get dark => _buildTheme(_darkColorScheme, Brightness.dark);
  static ThemeData get amoled => _buildTheme(_amoledColorScheme, Brightness.dark);

  // ---------------------------------------------------------------------------
  // Color schemes
  // ---------------------------------------------------------------------------

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    surfaceContainerLowest: Color(0xB3FFFFFF),
    surfaceContainerLow: Color(0x99FFFFFF),
    surfaceContainer: Color(0x9EFFFFFF),
    surfaceContainerHigh: Color(0xB8FFFFFF),
    surfaceContainerHighest: Color(0xCCFFFFFF),
    onSurfaceVariant: AppColors.onSurfaceVariantLight,
    outline: AppColors.outlineLight,
    outlineVariant: Color(0x668C9AC0),
    shadow: Color(0xFF1B2440),
    scrim: Colors.black,
    inverseSurface: Color(0xFF151D33),
    onInverseSurface: Color(0xFFF1F4FB),
    inversePrimary: AppColors.primaryDark,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    onTertiaryContainer: AppColors.onTertiaryContainerDark,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFF4A1414),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLowest: Color(0x08FFFFFF),
    surfaceContainerLow: Color(0x0DFFFFFF),
    surfaceContainer: Color(0x12FFFFFF),
    surfaceContainerHigh: Color(0x17FFFFFF),
    surfaceContainerHighest: Color(0x1FFFFFFF),
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: Color(0x40FFFFFF),
    outlineVariant: Color(0x1AFFFFFF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFEFF3FF),
    onInverseSurface: Color(0xFF0E1428),
    inversePrimary: AppColors.primary,
  );

  static const ColorScheme _amoledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: Color(0xFF14306E),
    onPrimaryContainer: Color(0xFFDCE6FF),
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: Color(0xFF221B4D),
    onSecondaryContainer: Color(0xFFE9E5FF),
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: Color(0xFF00352F),
    onTertiaryContainer: Color(0xFFC6F5EC),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF000000),
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLowest: Color(0x05FFFFFF),
    surfaceContainerLow: Color(0x0AFFFFFF),
    surfaceContainer: Color(0x0FFFFFFF),
    surfaceContainerHigh: Color(0x14FFFFFF),
    surfaceContainerHighest: Color(0x1AFFFFFF),
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: Color(0x38FFFFFF),
    outlineVariant: Color(0x17FFFFFF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFEFF3FF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: AppColors.primary,
  );

  // ---------------------------------------------------------------------------
  // Theme factory
  // ---------------------------------------------------------------------------

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = AppTypography.textTheme;
    final isDark = brightness == Brightness.dark;
    final isAmoled = colorScheme.surface == Colors.black;

    // Near-opaque tint for floating surfaces (dialogs, sheets, menus).
    final floating = isDark
        ? (isAmoled ? const Color(0xF00A0A0F) : const Color(0xF0111934))
        : const Color(0xF5FBFCFF);
    final hairline = isDark ? const Color(0x1AFFFFFF) : const Color(0x388C9AC0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: floating,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GlassPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        elevation: AppElevation.level0,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSizes.appBarHeight,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: AppSizes.navigationBarHeight,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withOpacity(isDark ? 0.20 : 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: AppSizes.iconMd,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: AppSizes.iconMd),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: AppSizes.iconMd),
        indicatorColor: colorScheme.primary.withOpacity(isDark ? 0.20 : 0.14),
        indicatorShape: const StadiumBorder(),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: hairline, width: 1),
        ),
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const StadiumBorder(),
          backgroundColor: colorScheme.surfaceContainerLow,
          side: BorderSide(color: hairline, width: 1),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        ),
      ),

      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        iconColor: colorScheme.onSurfaceVariant,
        tileColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(space: 1, thickness: 1, color: hairline),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primary.withOpacity(isDark ? 0.24 : 0.16),
        side: BorderSide(color: hairline, width: 1),
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: hairline)),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme.primary.withOpacity(isDark ? 0.24 : 0.16)
                  : colorScheme.surfaceContainerLow),
        ),
      ),

      dialogTheme: DialogTheme(
        elevation: AppElevation.level3,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          side: BorderSide(color: hairline),
        ),
        backgroundColor: floating,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: floating,
        modalBackgroundColor: floating,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: floating,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(color: hairline),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurfaceVariant.withOpacity(0.4);
          }
          return states.contains(WidgetState.selected) ? Colors.white : colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? Colors.transparent : hairline;
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(color: hairline),
        ),
        backgroundColor: isDark ? const Color(0xF21A2342) : const Color(0xF2151D33),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFFEFF3FF)),
        actionTextColor: AppColors.primaryDark,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF21A2342) : const Color(0xF2151D33),
          borderRadius: AppRadius.radiusSm,
        ),
        textStyle: textTheme.labelSmall?.copyWith(color: const Color(0xFFEFF3FF)),
      ),

      splashFactory: InkRipple.splashFactory,
      splashColor: colorScheme.primary.withAlpha(28),
      highlightColor: colorScheme.primary.withAlpha(10),
    );
  }
}

/// Fade-through with a subtle rise: the outgoing page fades out while the
/// incoming one fades and settles in. Works with transparent scaffolds (no
/// opaque sliding slabs) and is cheap — opacity + translate only.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return GlassFadeThrough(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class GlassFadeThrough extends StatelessWidget {
  const GlassFadeThrough({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static final _inFade = CurveTween(curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic));
  static final _outFade = CurveTween(curve: const Interval(0.0, 0.45, curve: Curves.easeInCubic));
  static final _rise = Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
      .chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: ReverseAnimation(secondaryAnimation.drive(_outFade)),
      child: FadeTransition(
        opacity: animation.drive(_inFade),
        child: SlideTransition(position: animation.drive(_rise), child: child),
      ),
    );
  }
}
