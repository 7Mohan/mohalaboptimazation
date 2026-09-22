import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// Loading indicator state with optional label.
class MohaLoadingState extends StatelessWidget {
  const MohaLoadingState({
    super.key,
    this.message = 'Loading telemetry…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSizes.iconLg,
            height: AppSizes.iconLg,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A subtle skeleton placeholder for content loading.
class MohaSkeleton extends StatefulWidget {
  const MohaSkeleton({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius = AppRadius.radiusSm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<MohaSkeleton> createState() => _MohaSkeletonState();
}

class _MohaSkeletonState extends State<MohaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withAlpha((_animation.value * 255).round()),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
