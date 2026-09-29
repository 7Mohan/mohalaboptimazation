import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/tokens/app_glass.dart';

/// A glass panel implementing the Moha Lab 4-level glass design system.
///
/// - Translucent fill + specular gradient hairline + soft shadow.
/// - Backdrop blur only for [AppGlassLevel.level4] (floating chrome), or when
///   [blur] is set explicitly — see [AppGlass] for why.
/// - Tactile 0.98x press scale and haptics when tappable.
class GlassCard extends StatefulWidget {
  final Widget child;
  final AppGlassLevel level;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Gradient? borderGradient;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  /// Overrides the level's blur sigma. Use sparingly.
  final double? blur;

  const GlassCard({
    super.key,
    required this.child,
    this.level = AppGlassLevel.level2,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderGradient,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
    this.blur,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  // Only tappable cards pay for an animation controller.
  AnimationController? _pressController;
  Animation<double>? _scale;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _ensureController() {
    if (!_interactive || _pressController != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _pressController = controller;
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  @override
  void didUpdateWidget(GlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureController();
  }

  @override
  void dispose() {
    _pressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppGlass.radiusFor(widget.level));
    final blur = widget.blur ?? AppGlass.blurFor(widget.level);
    final fill = widget.backgroundColor ?? AppGlass.surfaceColor(context, widget.level);
    final gradient = widget.borderColor != null
        ? null
        : (widget.borderGradient ?? AppGlass.borderGradient(context, widget.level));

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (blur > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.shadows ?? AppGlass.shadowsFor(context, widget.level),
      ),
      child: CustomPaint(
        foregroundPainter: GlassBorderPainter(
          radius: radius,
          gradient: gradient,
          color: widget.borderColor,
          width: widget.borderWidth ?? 1.0,
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: widget.clipBehavior,
          child: surface,
        ),
      ),
    );

    if (!_interactive) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _pressController?.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _pressController?.reverse(),
      onTapCancel: () => _pressController?.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: ScaleTransition(scale: _scale!, child: card),
    );
  }
}

/// Paints a hairline border (gradient or solid) exactly on the rounded edge,
/// without filling the interior.
class GlassBorderPainter extends CustomPainter {
  const GlassBorderPainter({
    required this.radius,
    this.gradient,
    this.color,
    this.width = 1.0,
  });

  final BorderRadius radius;
  final Gradient? gradient;
  final Color? color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (gradient == null && color == null) return;
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color!;
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(GlassBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.gradient != gradient ||
      oldDelegate.color != color ||
      oldDelegate.width != width;
}

/// Frosted surface for bottom sheets: the one place besides the tab bar
/// where a live blur is worth its cost (it only exists while open).
class GlassSheetSurface extends StatelessWidget {
  const GlassSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(28));
    return CustomPaint(
      foregroundPainter: GlassBorderPainter(
        radius: radius,
        gradient: AppGlass.borderGradient(context, AppGlassLevel.level4),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppGlass.blurLevel4, sigmaY: AppGlass.blurLevel4),
          child: ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0E1428).withOpacity(0.86)
                : Colors.white.withOpacity(0.86),
            child: child,
          ),
        ),
      ),
    );
  }
}
