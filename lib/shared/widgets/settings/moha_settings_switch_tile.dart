import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Settings switch row with full semantic labeling and accessible tap target.
class MohaSettingsSwitchTile extends StatelessWidget {
  const MohaSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leadingIcon,
    this.statusBadge,
    this.showDivider = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? statusBadge;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          toggled: value,
          label: title,
          hint: subtitle,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: AppRadius.radiusMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        leadingIcon,
                        size: AppSizes.iconMd,
                        color: value
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (statusBadge != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              statusBadge!,
                            ],
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxxs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            indent: leadingIcon != null ? 70 : AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
      ],
    );
  }
}
