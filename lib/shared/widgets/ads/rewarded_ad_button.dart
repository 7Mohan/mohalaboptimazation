import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ad_placement.dart';
import '../../../core/ads/ad_providers.dart';
import '../../../core/ads/ad_state.dart';

/// A button that triggers a rewarded ad to unlock a benefit.
///
/// - Hidden (returns [SizedBox.shrink]) when ads are disabled.
/// - Disabled with a loading indicator while the ad is loading.
/// - Only active when the rewarded ad is in [AdState.ready].
/// - Calls [onRewarded] when the user earns the reward.
///
/// Intended use: placed near the bandwidth speed test section in network
/// diagnostics, giving the user an explicit opt-in to watch an ad.
class RewardedAdButton extends ConsumerStatefulWidget {
  const RewardedAdButton({
    super.key,
    this.placement = AdPlacement.rewardedBandwidthTest,
    required this.label,
    required this.onRewarded,
  });

  final AdPlacement placement;
  final String label;
  final VoidCallback onRewarded;

  @override
  ConsumerState<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends ConsumerState<RewardedAdButton> {
  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(adServiceProvider);
    final state = service.getState(widget.placement);

    // Hide entirely when disabled (Pro mode or SDK unavailable).
    if (state == AdState.disabled) {
      return const SizedBox.shrink();
    }

    final isLoading = state == AdState.loading || _requesting;
    final isReady = state == AdState.ready;
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: isReady && !_requesting ? _onTap : null,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : const Icon(Icons.card_giftcard_outlined, size: 18),
      label: Text(widget.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isReady
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _onTap() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await ref.read(adServiceProvider).showRewarded(
        widget.placement,
        canShow: true,
        onRewarded: (ad, reward) {
          // Deliver reward to parent after the ad closes.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onRewarded();
          });
        },
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}
