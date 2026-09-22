import 'package:flutter/material.dart';
import '../../../../core/theme/tokens/tailwind_tokens.dart';

/// A sleek, modern card styled after Tailwind UI / Shadcn / Bootstrap components.
///
/// Features:
/// - Crisp 1px hairline border (`border-zinc-800`)
/// - Solid dark surface (`bg-zinc-900`) avoiding cheesy glow overlays
/// - Optional Bootstrap-style header, subtitle, and footer
class TailwindCard extends StatelessWidget {
  const TailwindCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerAction,
    this.footer,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14.0,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBg = backgroundColor ??
        (isDark ? TailwindColors.zinc900 : Colors.white);
    final effectiveBorder = borderColor ??
        (isDark ? TailwindColors.zinc800 : TailwindColors.zinc200);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    // Optional header (Bootstrap card-header style)
    if (title != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              (padding as EdgeInsets).left,
              (padding as EdgeInsets).top,
              (padding as EdgeInsets).right,
              8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? TailwindColors.zinc100 : TailwindColors.zinc900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? TailwindColors.zinc400 : TailwindColors.zinc500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: effectiveBorder,
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      );
    }

    // Optional footer (Bootstrap card-footer style)
    if (footer != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Divider(
            height: 1,
            thickness: 1,
            color: effectiveBorder,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: footer!,
          ),
        ],
      );
    }

    final boxDecoration = BoxDecoration(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: effectiveBorder, width: 1.0),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: boxDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: boxDecoration,
      child: content,
    );
  }
}
