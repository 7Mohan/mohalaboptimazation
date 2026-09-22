import 'package:flutter/material.dart';
import '../../../../core/theme/tokens/tailwind_tokens.dart';

enum TailwindBadgeVariant {
  success,
  info,
  warning,
  danger,
  neutral,
  indigo,
}

/// A modern pill badge styled after Tailwind UI `inline-flex items-center rounded-md px-2 py-1 text-xs ring-1 ring-inset`.
class TailwindBadge extends StatelessWidget {
  const TailwindBadge({
    super.key,
    required this.label,
    this.variant = TailwindBadgeVariant.neutral,
    this.icon,
    this.showDot = false,
  });

  final String label;
  final TailwindBadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final (bg, border, text, dotColor) = switch (variant) {
      TailwindBadgeVariant.success => (
          TailwindColors.emerald950.withOpacity(0.5),
          TailwindColors.emerald500.withOpacity(0.3),
          TailwindColors.emerald400,
          TailwindColors.emerald500,
        ),
      TailwindBadgeVariant.info => (
          TailwindColors.blue950.withOpacity(0.5),
          TailwindColors.blue500.withOpacity(0.3),
          TailwindColors.blue400,
          TailwindColors.blue500,
        ),
      TailwindBadgeVariant.warning => (
          TailwindColors.amber950.withOpacity(0.5),
          TailwindColors.amber500.withOpacity(0.3),
          TailwindColors.amber400,
          TailwindColors.amber500,
        ),
      TailwindBadgeVariant.danger => (
          TailwindColors.rose950.withOpacity(0.5),
          TailwindColors.rose500.withOpacity(0.3),
          TailwindColors.rose400,
          TailwindColors.rose500,
        ),
      TailwindBadgeVariant.neutral => (
          TailwindColors.zinc800.withOpacity(0.6),
          TailwindColors.zinc700,
          TailwindColors.zinc300,
          TailwindColors.zinc400,
        ),
      TailwindBadgeVariant.indigo => (
          TailwindColors.indigo950.withOpacity(0.5),
          TailwindColors.indigo500.withOpacity(0.3),
          TailwindColors.indigo400,
          TailwindColors.indigo500,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
