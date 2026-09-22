import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

enum GlassButtonVariant {
  primary,
  glass,
  outline,
  danger,
}

/// A precision tactile glass button with haptic feedback and micro-interaction scale.
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  /// Factory for a text-labeled button.
  factory GlassButton.label({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    GlassButtonVariant variant = GlassButtonVariant.primary,
    IconData? icon,
    bool isLoading = false,
    double? width,
    double height = 48.0,
  }) {
    return GlassButton(
      key: key,
      onPressed: onPressed,
      variant: variant,
      icon: icon,
      isLoading: isLoading,
      width: width,
      height: height,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(14);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case GlassButtonVariant.primary:
        bg = isEnabled
            ? (isDark ? AppColors.primaryDark : AppColors.primary)
            : (isDark ? Colors.white10 : Colors.black12);
        fg = isDark ? Colors.black : Colors.white;
        if (isEnabled) {
          shadows = [
            BoxShadow(
              color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case GlassButtonVariant.glass:
        bg = isDark
            ? (isEnabled ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03))
            : (isEnabled ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.02));
        fg = isDark ? Colors.white : Colors.black87;
        border = Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          width: 1,
        );
        break;

      case GlassButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.primaryDark : AppColors.primary;
        border = Border.all(
          color: fg.withOpacity(0.4),
          width: 1.2,
        );
        break;

      case GlassButtonVariant.danger:
        bg = isDark ? AppColors.error.withOpacity(0.18) : AppColors.errorContainer;
        fg = isDark ? const Color(0xFFFF6B6B) : AppColors.error;
        border = Border.all(
          color: fg.withOpacity(0.3),
          width: 1,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
          )
        else if (widget.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(widget.icon, size: 18, color: fg),
          ),
        DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: widget.child,
        ),
      ],
    );

    Widget button = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: Center(child: content),
    );

    if (widget.variant == GlassButtonVariant.glass) {
      button = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: button,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: button,
      ),
    );
  }
}
