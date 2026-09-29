import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_glass.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import 'glass_card.dart';

/// A small uppercase label that introduces a glass section.
class GlassSectionLabel extends StatelessWidget {
  const GlassSectionLabel(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md + 4, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A glass panel whose children are separated by hairlines — the grouped
/// list style used for settings and tweak rows.
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.children, this.margin});

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final line = AppGlass.hairline(context);
    return GlassCard(
      margin: margin ?? AppSpacing.screenPadding,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 60, color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon — the leading visual for rows.
class GlassIconTile extends StatelessWidget {
  const GlassIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 36,
    this.active = false,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withOpacity(active ? 0.38 : 0.20), c.withOpacity(active ? 0.18 : 0.08)],
        ),
        border: Border.all(color: c.withOpacity(active ? 0.55 : 0.22), width: 1),
      ),
      child: Icon(icon, size: size * 0.52, color: c),
    );
  }
}

/// Human-readable byte size (e.g. "412 MB").
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(bytes >= 100 * mb ? 0 : 1)} MB';
  return '${(bytes / kb).toStringAsFixed(0)} KB';
}
