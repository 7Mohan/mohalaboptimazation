import 'package:flutter/material.dart';

/// Motion and duration tokens for Moha Lab Optimization.
///
/// Ensures restrained, responsive, and natural transitions without distracting animations.
abstract final class AppMotion {
  /// 150ms - Micro-interactions (toggle switches, button presses, icon transitions)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 250ms - Standard component transitions (dialog appearance, tab shifts, card expansion)
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// 350ms - Major surface transitions (page navigation, bottom sheet entrance)
  static const Duration durationSlow = Duration(milliseconds: 350);

  // Standard curves
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
  static const Curve curveSharp = Curves.easeInOut;
}
