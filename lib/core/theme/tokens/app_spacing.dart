import 'package:flutter/material.dart';

/// Centralized 4pt/8pt grid spacing tokens for Moha Lab Optimization.
///
/// Avoid hardcoding numeric margins or paddings anywhere in UI code.
abstract final class AppSpacing {
  /// 2 dp - Micro spacing for fine alignment
  static const double xxxs = 2.0;

  /// 4 dp - Minimum spacing between tightly bound elements
  static const double xxs = 4.0;

  /// 8 dp - Compact spacing between related elements
  static const double xs = 8.0;

  /// 12 dp - Moderate spacing inside cards and controls
  static const double sm = 12.0;

  /// 16 dp - Standard default content padding & screen margin
  static const double md = 16.0;

  /// 20 dp - Intermediate section padding
  static const double lg = 20.0;

  /// 24 dp - Major spacing between layout sections
  static const double xl = 24.0;

  /// 32 dp - Large structural spacing
  static const double xxl = 32.0;

  /// 48 dp - Hero & header breathing room
  static const double huge = 48.0;

  // Convenient EdgeInsets presets
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets paddingXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Screen horizontal padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenContentPadding = EdgeInsets.fromLTRB(md, md, md, xl);

  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(sm);
}
