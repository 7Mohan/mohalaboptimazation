import 'package:flutter/material.dart';

/// Displays an intentional empty state with an icon, message, and optional
/// call-to-action.
///
/// Used wherever functionality is not yet implemented. The label should always
/// be honest: e.g., "Coming in a future update" rather than pretending
/// something exists.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  /// When true, uses smaller spacing (for use inside cards or lists).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vPad = compact ? 24.0 : 48.0;
    final iconSize = compact ? 36.0 : 56.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: vPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? 16 : 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
