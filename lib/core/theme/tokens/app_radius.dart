import 'package:flutter/material.dart';

/// Controlled corner radius tokens for Moha Lab Optimization.
///
/// Follows disciplined Android utility guidelines:
/// - Avoids excessive or cartoonish rounding
/// - Ensures predictable, unified visual rhythm across all components
abstract final class AppRadius {
  /// 4 dp - Minimal radius for micro tags or inner elements
  static const double xs = 4.0;

  /// 8 dp - Subtle radius for chips, badges, and segmented toggles
  static const double sm = 8.0;

  /// 12 dp - Standard radius for buttons, text fields, and list tiles
  static const double md = 12.0;

  /// 16 dp - Standard radius for cards and container panels
  static const double lg = 16.0;

  /// 20 dp - Controlled radius for bottom sheets and floating dialogs
  static const double xl = 20.0;

  /// Circular / fully rounded when functionally required (e.g. status dots)
  static const double full = 999.0;

  // BorderRadius presets
  static const BorderRadius zero = BorderRadius.zero;
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));

  // Top-only radius for bottom sheets
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
