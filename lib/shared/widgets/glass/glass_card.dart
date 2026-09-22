import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/tokens/app_glass.dart';

/// A premium glassmorphic card implementing the Moha Lab 4-level glass design system.
///
/// Features:
/// - Selectable [AppGlassLevel] (Level 1 Flat to Level 4 Floating)
/// - Backdrop blur filter with optimized bypass when blur is 0
/// - Specular highlight gradient borders
/// - Micro-interaction tactile scale feedback (0.98x) and haptic feedback on tap
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
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _pressController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(AppGlass.radiusFor(widget.level));
    final blur = AppGlass.blurFor(widget.level);
    final surfaceColor = widget.backgroundColor ?? AppGlass.surfaceColor(context, widget.level);
    final shadows = widget.shadows ?? AppGlass.shadowsFor(context, widget.level);
    final gradient = widget.borderGradient ?? AppGlass.borderGradient(context, widget.level);

    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: effectiveRadius,
      ),
      child: widget.child,
    );

    // Apply BackdropFilter only if blur > 0 for optimal rendering performance
    if (blur > 0) {
      cardContent = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: cardContent,
      );
    }

    Widget decoratedBox = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: widget.clipBehavior,
        child: Stack(
          children: [
            cardContent,
            // Specular gradient border overlay
            if (gradient != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: effectiveRadius,
                      border: Border.all(
                        color: Colors.transparent,
                        width: widget.borderWidth ?? 1.0,
                      ),
                      gradient: gradient,
                    ),
                  ),
                ),
              )
            else if (widget.borderColor != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: effectiveRadius,
                      border: Border.all(
                        color: widget.borderColor!,
                        width: widget.borderWidth ?? 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onLongPress: widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress?.call();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: decoratedBox,
        ),
      );
    }

    return decoratedBox;
  }
}
