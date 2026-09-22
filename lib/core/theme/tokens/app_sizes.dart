import 'package:flutter/material.dart';

/// Centralized component dimensions and accessibility sizes for Moha Lab Optimization.
///
/// Strictly adheres to Android Accessibility Guidelines (min 48x48 dp touch targets).
abstract final class AppSizes {
  // Accessibility minimum touch target
  static const double minTouchTarget = 48.0;
  static const Size minTouchTargetSize = Size(minTouchTarget, minTouchTarget);

  // Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // Icon sizes
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
  static const double iconXl = 36.0;
  static const double iconHuge = 48.0;

  // Structural heights
  static const double appBarHeight = 64.0;
  static const double navigationBarHeight = 72.0;
  static const double navigationRailWidth = 80.0;
  static const double bottomSheetHandleWidth = 36.0;
  static const double bottomSheetHandleHeight = 4.0;

  // Responsive breakpoints
  static const double breakpointCompact = 600.0;
  static const double breakpointMedium = 840.0;
  static const double maxContentWidth = 840.0;
}
