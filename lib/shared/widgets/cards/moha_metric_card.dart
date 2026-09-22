import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_glass.dart';
import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../glass/glass_card.dart';
import '../indicators/moha_status_badge.dart';

/// Production metric card displaying real-time or diagnostic hardware telemetry with glass styling.
class MohaMetricCard extends StatelessWidget {
  const MohaMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.detail,
    this.icon,
    this.statusType,
    this.statusLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;
  final String? detail;
  final IconData? icon;
  final MohaStatusType? statusType;
  final String? statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = GlassCard(
      level: AppGlassLevel.level2,
      onTap: onTap,
      padding: AppSpacing.cardPaddingCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Icon & Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.iconSm,
                    color: theme.colorScheme.primary,
                  ),
                ),
              if (statusType != null)
                MohaStatusBadge(
                  type: statusType!,
                  customLabel: statusLabel,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Label
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Value & Unit
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Secondary detail
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: '$label: $value ${unit ?? ""}, ${detail ?? ""}',
      button: onTap != null,
      child: card,
    );
  }
}
