import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Secondary / Outlined button for dismissive or auxiliary actions.
class MohaSecondaryButton extends StatelessWidget {
  const MohaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(
          isFullWidth ? double.infinity : AppSizes.minTouchTarget,
          AppSizes.buttonHeightMd,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: theme.colorScheme.onSurface),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: button,
    );
  }
}
