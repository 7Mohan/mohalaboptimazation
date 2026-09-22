import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// A minimal circular status dot indicator for live system or service states.
class MohaStatusIndicator extends StatelessWidget {
  const MohaStatusIndicator({
    super.key,
    required this.color,
    this.size = 8.0,
    this.semanticLabel,
  });

  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'Status indicator',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withAlpha(80),
            width: AppSpacing.xxxs,
          ),
          borderRadius: AppRadius.radiusFull,
        ),
      ),
    );
  }
}
