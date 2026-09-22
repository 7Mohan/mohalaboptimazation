import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_sizes.dart';

/// Produces production-grade [ThemeData] for Light and Dark modes in Moha Lab Optimization.
///
/// Principles:
/// - Explicit ColorSchemes (avoid tonal algorithmic drift)
/// - Authentic Android utility aesthetic (high contrast, clean slate surfaces, subtle borders)
/// - Bound to centralized tokens: AppColors, AppRadius, AppSpacing, AppSizes, AppElevation
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
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: AppColors.surfaceContainerLight,
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    onSurfaceVariant: AppColors.onSurfaceVariantLight,
    outline: AppColors.outlineLight,
    outlineVariant: AppColors.outlineVariantLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
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
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLowest: Color(0xFF070A0F),
    surfaceContainerLow: Color(0xFF0D131F),
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: Color(0xFF172033),
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: AppColors.primary,
  );

  static const ColorScheme _amoledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: Color(0xFF002870),
    onPrimaryContainer: Color(0xFFD6E4FF),
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: Color(0xFF141414),
    onSecondaryContainer: Color(0xFFE2E8F0),
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: Color(0xFF003842),
    onTertiaryContainer: Color(0xFFC0F0FB),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF000000),
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF060606),
    surfaceContainer: Color(0xFF0C0C0C),
    surfaceContainerHigh: Color(0xFF141414),
    surfaceContainerHighest: Color(0xFF1F1F1F),
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: Color(0xFF262626),
    outlineVariant: Color(0xFF181818),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: AppColors.primary,
  );

  // ---------------------------------------------------------------------------
  // Theme factory
  // ---------------------------------------------------------------------------

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = AppTypography.textTheme;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,
      scaffoldBackgroundColor: colorScheme.surface,

      // App Bar
      appBarTheme: AppBarTheme(
        elevation: AppElevation.level0,
        scrolledUnderElevation: AppElevation.level1,
        toolbarHeight: AppSizes.appBarHeight,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colorScheme.surface,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colorScheme.surface,
              ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Navigation Bar (Bottom)
      navigationBarTheme: NavigationBarThemeData(
        elevation: AppElevation.level0,
        height: AppSizes.navigationBarHeight,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer, size: AppSizes.iconMd);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: AppSizes.iconMd);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Navigation Rail (Tablets & Wide screens)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer, size: AppSizes.iconMd),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: AppSizes.iconMd),
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
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

      // Card Theme
      cardTheme: CardTheme(
        elevation: AppElevation.level0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          elevation: AppElevation.level0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          side: BorderSide(color: colorScheme.outline, width: 1),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.buttonHeightMd),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colorScheme.outlineVariant,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusSm,
        ),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        elevation: AppElevation.level3,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusXl,
        ),
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppElevation.level3,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTop,
        ),
        backgroundColor: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant;
        }),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        backgroundColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.onInverseSurface,
        ),
      ),

      // Splash & Ink
      splashColor: colorScheme.primary.withAlpha(25),
      highlightColor: colorScheme.primary.withAlpha(12),
    );
  }
}
