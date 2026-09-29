import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The ambient canvas that every glass surface floats on.
///
/// Painted once into its own layer (static, no animation) so it costs nothing
/// while content scrolls above it.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final amoled = dark && theme.colorScheme.surface == Colors.black;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AmbientPainter(
              base: theme.colorScheme.surface,
              dark: dark,
              intensity: amoled ? 0.55 : 1.0,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.base,
    required this.dark,
    required this.intensity,
  });

  final Color base;
  final bool dark;
  final double intensity;

  void _glow(Canvas canvas, Size size, Offset center, double radius, Color color, double opacity) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity * intensity),
          color.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final w = size.width;
    final h = size.height;
    final r = w * 0.95;
    if (dark) {
      _glow(canvas, size, Offset(w * 0.05, h * 0.02), r, AppColors.glowAzure, 0.30);
      _glow(canvas, size, Offset(w * 1.05, h * 0.38), r * 0.9, AppColors.glowViolet, 0.22);
      _glow(canvas, size, Offset(w * 0.15, h * 0.92), r * 0.85, AppColors.glowAqua, 0.13);
    } else {
      _glow(canvas, size, Offset(w * 0.0, h * 0.0), r, AppColors.glowAzure, 0.20);
      _glow(canvas, size, Offset(w * 1.0, h * 0.40), r * 0.9, AppColors.glowViolet, 0.16);
      _glow(canvas, size, Offset(w * 0.2, h * 0.95), r * 0.85, AppColors.glowAqua, 0.14);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.dark != dark || oldDelegate.intensity != intensity;
}
