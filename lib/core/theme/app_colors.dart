import 'package:flutter/material.dart';

/// Moha Lab brand colors & semantic design tokens.
///
/// Glass palette: a deep ink canvas lit by soft azure / violet / aqua
/// ambient light, with translucent surfaces layered on top. Accents stay
/// high-contrast (WCAG AA on both canvases) so glass never costs legibility.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Primary brand — Azure
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryContainer = Color(0xFFDCE6FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001A52);

  static const Color primaryDark = Color(0xFF7AA5FF);
  static const Color primaryContainerDark = Color(0xFF1B3C8F);
  static const Color onPrimaryDark = Color(0xFF00133D);
  static const Color onPrimaryContainerDark = Color(0xFFDCE6FF);

  // ---------------------------------------------------------------------------
  // Secondary — Violet (ambient light, secondary emphasis)
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF6D5BD0);
  static const Color secondaryContainer = Color(0xFFE9E5FF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF22175C);

  static const Color secondaryDark = Color(0xFFB4A8FF);
  static const Color secondaryContainerDark = Color(0xFF2E2566);
  static const Color onSecondaryDark = Color(0xFF1A1147);
  static const Color onSecondaryContainerDark = Color(0xFFE9E5FF);

  // ---------------------------------------------------------------------------
  // Tertiary — Aqua (active / "on" states)
  // ---------------------------------------------------------------------------
  static const Color tertiary = Color(0xFF00897B);
  static const Color tertiaryContainer = Color(0xFFC6F5EC);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF00201C);

  static const Color tertiaryDark = Color(0xFF4FE3C8);
  static const Color tertiaryContainerDark = Color(0xFF00473F);
  static const Color onTertiaryDark = Color(0xFF00382F);
  static const Color onTertiaryContainerDark = Color(0xFFC6F5EC);

  // ---------------------------------------------------------------------------
  // Canvas & surfaces — Light (frosted porcelain)
  // ---------------------------------------------------------------------------
  static const Color surfaceLight = Color(0xFFF1F4FB);
  static const Color surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE8ECF6);
  static const Color outlineLight = Color(0xFFC3CADB);
  static const Color outlineVariantLight = Color(0xFFDDE2EE);
  static const Color onSurfaceLight = Color(0xFF0E1526);
  static const Color onSurfaceVariantLight = Color(0xFF4A5570);

  // ---------------------------------------------------------------------------
  // Canvas & surfaces — Dark (deep ink)
  // ---------------------------------------------------------------------------
  static const Color surfaceDark = Color(0xFF070B16);
  static const Color surfaceContainerDark = Color(0xFF0F1526);
  static const Color surfaceVariantDark = Color(0xFF182038);
  static const Color outlineDark = Color(0xFF2A3452);
  static const Color outlineVariantDark = Color(0xFF1C2440);
  static const Color onSurfaceDark = Color(0xFFEFF3FF);
  static const Color onSurfaceVariantDark = Color(0xFF9AA6C4);

  // ---------------------------------------------------------------------------
  // Ambient light used by the glass canvas
  // ---------------------------------------------------------------------------
  static const Color glowAzure = Color(0xFF3D7BFF);
  static const Color glowViolet = Color(0xFF8B6CFF);
  static const Color glowAqua = Color(0xFF1FD1B5);

  // ---------------------------------------------------------------------------
  // Semantic status indicators
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF064E3B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF78350F);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color shizuku = Color(0xFF6366F1);
  static const Color shizukuContainer = Color(0xFFEEF2FF);
  static const Color onShizuku = Color(0xFFFFFFFF);
  static const Color onShizukuContainer = Color(0xFF312E81);

  static const Color rootRestricted = Color(0xFF8B5CF6);
  static const Color rootRestrictedContainer = Color(0xFFF5F3FF);

  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

  static const Color statusGood = success;
  static const Color statusWarn = warning;
  static const Color statusBad = error;
  static const Color statusUnknown = Color(0xFF64748B);

  static const Color comingSoon = Color(0xFF64748B);
  static const Color comingSoonContainer = Color(0xFFF1F5F9);
  static const Color comingSoonContainerDark = Color(0xFF1E293B);
}
