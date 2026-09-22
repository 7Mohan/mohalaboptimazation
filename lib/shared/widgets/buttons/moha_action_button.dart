import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Primary action button for Moha Lab Optimization.
///
/// Features:
/// - Guarantees minimum 48x48 dp touch target for accessibility
/// - Loading state with progress indicator
/// - Optional leading icon
/// - Clear semantic label
class MohaActionButton extends StatelessWidget {
  const MohaActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonChild = isLoading
        ? SizedBox(
            width: AppSizes.iconSm,
            height: AppSizes.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? theme.colorScheme.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foregroundColor ?? theme.colorScheme.onPrimary,
                ),
              ),
            ],
          );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        minimumSize: Size(
          isFullWidth ? double.infinity : AppSizes.minTouchTarget,
          AppSizes.buttonHeightMd,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      child: buttonChild,
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      child: button,
    );
  }
}
