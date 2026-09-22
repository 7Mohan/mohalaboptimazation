import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../buttons/moha_action_button.dart';
import '../buttons/moha_secondary_button.dart';

/// Confirmation dialog for critical or destructive actions.
class MohaConfirmationDialog extends StatelessWidget {
  const MohaConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MohaConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      icon: icon != null
          ? Icon(
              icon,
              size: AppSizes.iconLg,
              color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        MohaSecondaryButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        MohaActionButton(
          label: confirmLabel,
          backgroundColor: isDestructive ? theme.colorScheme.error : null,
          foregroundColor: isDestructive ? theme.colorScheme.onError : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Simple informative dialog.
class MohaInfoDialog extends StatelessWidget {
  const MohaInfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'Got It',
    this.icon,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData? icon;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'Got It',
    IconData? icon,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => MohaInfoDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      icon: icon != null
          ? Icon(
              icon,
              size: AppSizes.iconLg,
              color: theme.colorScheme.primary,
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        MohaActionButton(
          label: buttonLabel,
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
