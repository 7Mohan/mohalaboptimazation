import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../buttons/moha_action_button.dart';

/// Error recovery screen component.
class MohaErrorState extends StatelessWidget {
  const MohaErrorState({
    super.key,
    required this.message,
    this.title = 'Unable to Load Data',
    this.onRetry,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: AppRadius.radiusLg,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: AppSizes.iconLg,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              MohaActionButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
