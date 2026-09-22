import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/ads/ad_placement.dart';
import '../../../core/ads/ad_providers.dart';
import '../../../core/ads/ad_state.dart';

/// Displays a banner ad for the given [placement].
///
/// - Collapses to [SizedBox.shrink] when the ad is not ready or fails.
/// - Accepts [AdPlacement] only; never raw ad unit ID strings.
/// - Adds 16px horizontal padding to prevent accidental edge taps.
/// - Automatically loads the banner on first build if not already loaded.
class MohaBannerAdWidget extends ConsumerStatefulWidget {
  const MohaBannerAdWidget({
    super.key,
    required this.placement,
  });

  final AdPlacement placement;

  @override
  ConsumerState<MohaBannerAdWidget> createState() => _MohaBannerAdWidgetState();
}

class _MohaBannerAdWidgetState extends ConsumerState<MohaBannerAdWidget> {
  @override
  void initState() {
    super.initState();
    // Request banner load on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adServiceProvider).loadBanner(widget.placement);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(adServiceProvider);
    final state = service.getState(widget.placement);
    final banner = service.getBanner(widget.placement);

    // Only render when the ad is ready and the banner object is available.
    if (state != AdState.ready || banner == null) {
      return const SizedBox.shrink();
    }

    // Wrap in a safe container with minimum padding.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
