import 'package:flutter/material.dart';

/// Elevation and shadow tokens for Moha Lab Optimization.
///
/// We prioritize crisp surfaces with subtle borders over heavy drop-shadows.
abstract final class AppElevation {
  /// Flat, flush surface
  static const double level0 = 0.0;

  /// Subtle elevation for resting utility cards with border outlines
  static const double level1 = 1.0;

  /// Raised interactive elements or active cards
  static const double level2 = 2.0;

  /// Modal dialogs and bottom sheets
  static const double level3 = 4.0;

  /// Floating menus and snackbars
  static const double level4 = 8.0;

  /// Restrained shadow for light mode elevated components
  static List<BoxShadow> subtleShadow(Color color) => [
        BoxShadow(
          color: color.withAlpha(12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Active card shadow
  static List<BoxShadow> activeShadow(Color color) => [
        BoxShadow(
          color: color.withAlpha(20),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
