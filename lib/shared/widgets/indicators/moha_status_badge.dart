import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_spacing.dart';

enum MohaStatusType {
  safe,
  shizuku,
  root,
  active,
  optimal,
  warning,
  critical,
  unavailable,
  comingSoon,
}

/// A compact, high-precision status badge indicating optimization tier or hardware state.
///
/// Ensures clear visual hierarchy without distracting glows or neon cliches.
class MohaStatusBadge extends StatelessWidget {
  const MohaStatusBadge({
    super.key,
    required this.type,
    this.customLabel,
    this.showIcon = true,
  });

  final MohaStatusType type;
  final String? customLabel;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (color, bgColor, icon, label) = _badgeProps(isDark);
    final displayLabel = customLabel ?? label;

    return Semantics(
      label: 'Status: $displayLabel',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxxs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.radiusSm,
          border: Border.all(
            color: color.withAlpha(isDark ? 80 : 50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              displayLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData, String) _badgeProps(bool isDark) {
    return switch (type) {
      MohaStatusType.safe => (
          isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
          isDark ? const Color(0xFF064E3B).withAlpha(120) : const Color(0xFFECFDF5),
          Icons.verified_user_outlined,
          'Safe',
        ),
      MohaStatusType.shizuku => (
          isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
          isDark ? const Color(0xFF312E81).withAlpha(120) : const Color(0xFFEEF2FF),
          Icons.terminal_outlined,
          'Shizuku',
        ),
      MohaStatusType.root => (
          isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          isDark ? const Color(0xFF4C1D95).withAlpha(120) : const Color(0xFFF5F3FF),
          Icons.security_outlined,
          'Root Only',
        ),
      MohaStatusType.active => (
          isDark ? const Color(0xFF60A5FA) : AppColors.primary,
          isDark ? const Color(0xFF1E3A8A).withAlpha(120) : const Color(0xFFEFF6FF),
          Icons.bolt,
          'Active',
        ),
      MohaStatusType.optimal => (
          isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
          isDark ? const Color(0xFF064E3B).withAlpha(120) : const Color(0xFFECFDF5),
          Icons.check_circle_outline,
          'Optimal',
        ),
      MohaStatusType.warning => (
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          isDark ? const Color(0xFF78350F).withAlpha(120) : const Color(0xFFFFFBEB),
          Icons.warning_amber_rounded,
          'Caution',
        ),
      MohaStatusType.critical => (
          isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          isDark ? const Color(0xFF7F1D1D).withAlpha(120) : const Color(0xFFFEF2F2),
          Icons.error_outline,
          'Critical',
        ),
      MohaStatusType.unavailable => (
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          Icons.block_outlined,
          'Unavailable',
        ),
      MohaStatusType.comingSoon => (
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          Icons.hourglass_empty_rounded,
          'Coming Soon',
        ),
    };
  }
}
