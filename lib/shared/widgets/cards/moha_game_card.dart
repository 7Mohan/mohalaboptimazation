import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens/app_glass.dart';
import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../glass/glass_card.dart';
import '../indicators/moha_status_badge.dart';

/// Card representing a detected or manually added game in Moha Lab Optimization with glass styling.
class MohaGameCard extends StatelessWidget {
  const MohaGameCard({
    super.key,
    required this.title,
    required this.packageName,
    this.statusType = MohaStatusType.safe,
    this.statusLabel = 'Safe Profile',
    this.icon,
    this.onTap,
    this.onLaunch,
  });

  final String title;
  final String packageName;
  final MohaStatusType statusType;
  final String statusLabel;
  final Widget? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      level: AppGlassLevel.level2,
      onTap: onTap,
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          // Game icon container
          Container(
            width: 48,
            height: 48,
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
            child: icon ??
                Icon(
                  Icons.sports_esports,
                  color: theme.colorScheme.primary,
                  size: AppSizes.iconLg,
                ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title and package info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  packageName,
                  style: AppTypography.monoStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                MohaStatusBadge(
                  type: statusType,
                  customLabel: statusLabel,
                ),
              ],
            ),
          ),

          // Launch button
          if (onLaunch != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              onPressed: onLaunch,
              tooltip: 'Launch $title',
              icon: const Icon(Icons.play_arrow_rounded),
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  AppSizes.minTouchTarget,
                  AppSizes.minTouchTarget,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
