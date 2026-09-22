import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// A hero container with a precision gradient, subtle glow border,
/// and high-contrast typography designed for the top of the dashboard.
class MohaGradientHero extends StatelessWidget {
  const MohaGradientHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.statusChip,
    this.metrics,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Widget? badge;
  final Widget? statusChip;
  final List<Widget>? metrics;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            const Color(0xFF14244A), // Deep cobalt midnight
            const Color(0xFF0F172A), // Slate base
          ]
        : [
            const Color(0xFFE0ECFF), // Soft cobalt wash
            const Color(0xFFF1F5F9), // Slate surface
          ];

    final borderColor = isDark
        ? const Color(0xFF2B4C8C).withOpacity(0.6)
        : const Color(0xFFBFDBFE);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusXl,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF1E56DE).withOpacity(0.12)
                : const Color(0xFF1E56DE).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXl,
        child: Stack(
          children: [
            // Ambient glow accent circle top right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD))
                      .withOpacity(0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Badges / Chips
                  if (statusChip != null || badge != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (statusChip != null) statusChip!,
                        const Spacer(),
                        if (badge != null) badge!,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Title & Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFDBEAFE),
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3B82F6).withOpacity(0.5)
                                : const Color(0xFF93C5FD),
                          ),
                        ),
                        child: Icon(
                          Icons.speed_rounded,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF1E40AF),
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Optional Metrics Row
                  if (metrics != null && metrics!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        for (int i = 0; i < metrics!.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: metrics![i]),
                        ],
                      ],
                    ),
                  ],

                  // Optional actions
                  if (actions != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    actions!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
