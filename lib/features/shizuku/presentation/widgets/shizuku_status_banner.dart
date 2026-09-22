import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/shizuku_status.dart';
import '../providers/shizuku_provider.dart';
import 'shizuku_setup_sheet.dart';

/// Compact banner displayed at the top of the Optimization screen.
///
/// Shows the current Shizuku state with a clear label, a status indicator dot,
/// and a one-tap action button. Hidden when status is [ShizukuStatus.ready].
///
/// Tapping the banner itself opens [ShizukuSetupSheet] for full details.
class ShizukuStatusBanner extends ConsumerWidget {
  const ShizukuStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(shizukuStatusProvider);

    return statusAsync.when(
      loading: () => const _BannerShimmer(),
      error: (_, __) => const _BannerError(),
      data: (status) {
        // Banner is invisible when fully ready — no visual clutter
        if (status.isReady) return const SizedBox.shrink();
        return _BannerContent(status: status);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner content
// ─────────────────────────────────────────────────────────────────────────────

class _BannerContent extends ConsumerWidget {
  const _BannerContent({required this.status});

  final ShizukuStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (bannerColor, onBannerColor, dotColor) = _colorsForStatus(status, colorScheme);

    return Semantics(
      label: 'Shizuku status: ${status.displayTitle}',
      button: true,
      child: GestureDetector(
        onTap: () => _openSetupSheet(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onBannerColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.displayTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onBannerColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shizuku is required for advanced system controls.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onBannerColor.withOpacity(0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action chip
              if (status.isActionable)
                _ActionChip(
                  status: status,
                  onBannerColor: onBannerColor,
                  bannerColor: bannerColor,
                ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: onBannerColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _colorsForStatus(
    ShizukuStatus status,
    ColorScheme cs,
  ) =>
      switch (status) {
        ShizukuStatus.notInstalled => (
            cs.errorContainer,
            cs.onErrorContainer,
            cs.error,
          ),
        ShizukuStatus.notRunning => (
            cs.errorContainer,
            cs.onErrorContainer,
            cs.error,
          ),
        ShizukuStatus.binderConnected => (
            cs.tertiaryContainer,
            cs.onTertiaryContainer,
            cs.tertiary,
          ),
        ShizukuStatus.permissionDenied => (
            cs.secondaryContainer,
            cs.onSecondaryContainer,
            cs.secondary,
          ),
        ShizukuStatus.permissionGranted => (
            cs.primaryContainer,
            cs.onPrimaryContainer,
            cs.primary,
          ),
        ShizukuStatus.ready => (
            cs.primaryContainer,
            cs.onPrimaryContainer,
            cs.primary,
          ),
      };

  void _openSetupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShizukuSetupSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action chip
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends ConsumerWidget {
  const _ActionChip({
    required this.status,
    required this.onBannerColor,
    required this.bannerColor,
  });

  final ShizukuStatus status;
  final Color onBannerColor;
  final Color bannerColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (status) {
      ShizukuStatus.notInstalled => 'Install',
      ShizukuStatus.notRunning => 'How to Start',
      ShizukuStatus.binderConnected => 'Allow',
      ShizukuStatus.permissionDenied => 'Retry',
      _ => null,
    };

    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _handleAction(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: onBannerColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: onBannerColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref) async {
    if (status == ShizukuStatus.binderConnected ||
        status == ShizukuStatus.permissionDenied) {
      await ref.read(shizukuStatusProvider.notifier).requestPermission();
    } else {
      // For install / how-to-start — open the full setup sheet
      if (context.mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ShizukuSetupSheet(),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error fallback
// ─────────────────────────────────────────────────────────────────────────────

class _BannerError extends StatelessWidget {
  const _BannerError();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Text(
            'Unable to check Shizuku status',
            style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
