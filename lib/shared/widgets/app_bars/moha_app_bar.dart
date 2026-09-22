import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Standardized top application bar for Moha Lab Optimization.
///
/// Communicates technical precision with the signature "MOHA LAB" brand tag
/// and consistent typography hierarchy.
class MohaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MohaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBrand = true,
    this.leading,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final bool showBrand;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        AppSizes.appBarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: leading != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizes.minTouchTarget,
                minHeight: AppSizes.minTouchTarget,
              ),
              child: leading,
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBrand)
            Text(
              AppConstants.brandName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                fontSize: 10,
              ),
            ),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      actions: actions != null
          ? [
              ...actions!.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: action,
                ),
              ),
            ]
          : null,
      bottom: bottom,
    );
  }
}
