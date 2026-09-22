import 'package:flutter/material.dart';

/// Moha Lab brand colors & semantic design tokens.
///
/// Designed specifically for a high-precision Android utility:
/// - Strong visual contrast (WCAG AA compliant)
/// - Authentic utility feel: deep slates, cobalt precision, crisp status signals
/// - Zero purple-blue gradients, zero fake neon glows
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Primary brand — Precision Cobalt
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF1E56DE);
  static const Color primaryContainer = Color(0xFFDBE7FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001B52);

  // Dark variant primary
  static const Color primaryDark = Color(0xFF5B93FF);
  static const Color primaryContainerDark = Color(0xFF003B99);
  static const Color onPrimaryDark = Color(0xFF001F5C);
  static const Color onPrimaryContainerDark = Color(0xFFD6E4FF);

  // ---------------------------------------------------------------------------
  // Secondary — Tech Steel & Slate
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF2D3748);
  static const Color secondaryContainer = Color(0xFFE2E8F0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0F172A);

  static const Color secondaryDark = Color(0xFF94A3B8);
  static const Color secondaryContainerDark = Color(0xFF1E293B);
  static const Color onSecondaryDark = Color(0xFF0F172A);
  static const Color onSecondaryContainerDark = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // Tertiary — Precision Teal / Cyan Accent (Used Sparingly)
  // ---------------------------------------------------------------------------
  static const Color tertiary = Color(0xFF008394);
  static const Color tertiaryContainer = Color(0xFFC0F0FB);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF001F25);

  static const Color tertiaryDark = Color(0xFF4DD8EC);
  static const Color tertiaryContainerDark = Color(0xFF004E5A);
  static const Color onTertiaryDark = Color(0xFF00363E);
  static const Color onTertiaryContainerDark = Color(0xFFC0F0FB);

  // ---------------------------------------------------------------------------
  // Surfaces — Light Mode (Clean Slate White)
  // ---------------------------------------------------------------------------
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color outlineLight = Color(0xFFCBD5E1);
  static const Color outlineVariantLight = Color(0xFFE2E8F0);
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceVariantLight = Color(0xFF475569);

  // ---------------------------------------------------------------------------
  // Surfaces — Dark Mode (Deep OLED Precision Slate)
  // ---------------------------------------------------------------------------
  static const Color surfaceDark = Color(0xFF0B0F17);
  static const Color surfaceContainerDark = Color(0xFF111724);
  static const Color surfaceVariantDark = Color(0xFF172033);
  static const Color outlineDark = Color(0xFF243247);
  static const Color outlineVariantDark = Color(0xFF1A2436);
  static const Color onSurfaceDark = Color(0xFFF1F5F9);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------------
  // Semantic status indicators
  // ---------------------------------------------------------------------------
  // Safe / Optimal / Good
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF064E3B);

  // Warning / Moderate / Caution
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF78350F);

  // Critical / High / Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // Shizuku / Advanced capability permission
  static const Color shizuku = Color(0xFF6366F1);
  static const Color shizukuContainer = Color(0xFFEEF2FF);
  static const Color onShizuku = Color(0xFFFFFFFF);
  static const Color onShizukuContainer = Color(0xFF312E81);

  // Root only / Restricted
  static const Color rootRestricted = Color(0xFF8B5CF6);
  static const Color rootRestrictedContainer = Color(0xFFF5F3FF);

  // Informational
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Status indicators (compatibility alias)
  static const Color statusGood = success;
  static const Color statusWarn = warning;
  static const Color statusBad = error;
  static const Color statusUnknown = Color(0xFF64748B);

  // Badges & subtle states
  static const Color comingSoon = Color(0xFF64748B);
  static const Color comingSoonContainer = Color(0xFFF1F5F9);
  static const Color comingSoonContainerDark = Color(0xFF1E293B);
}
