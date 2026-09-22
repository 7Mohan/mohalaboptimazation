import 'package:flutter/material.dart';

/// A chip-shaped badge displaying "Coming soon" or a custom label.
///
/// Used to honestly label features that are not yet implemented.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key, this.label = 'Coming soon'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
