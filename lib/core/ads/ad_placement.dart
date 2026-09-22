/// Named ad placements used throughout the app.
///
/// All ad unit IDs are resolved from [AdConfiguration] using these keys.
/// Widgets and screens only reference placements, never raw ad unit ID strings.
enum AdPlacement {
  /// Banner at the bottom of the Home screen.
  homeBanner,

  /// Banner at the bottom of the Games library screen.
  gameDetailBanner,

  /// Interstitial shown after an optimization workflow completes.
  /// Only displayed at the natural result screen, never mid-flow.
  postOptimizationInterstitial,

  /// Interstitial shown after a network diagnostics run completes.
  /// Only displayed after results are visible to the user.
  postDiagnosticsInterstitial,

  /// Rewarded ad that unlocks a one-time manual bandwidth speed test.
  /// Only shown when the user explicitly requests the bandwidth test.
  rewardedBandwidthTest,
}

/// Returns true if [placement] is a banner ad.
bool isBannerPlacement(AdPlacement placement) {
  return placement == AdPlacement.homeBanner ||
      placement == AdPlacement.gameDetailBanner;
}

/// Returns true if [placement] is an interstitial ad.
bool isInterstitialPlacement(AdPlacement placement) {
  return placement == AdPlacement.postOptimizationInterstitial ||
      placement == AdPlacement.postDiagnosticsInterstitial;
}

/// Returns true if [placement] is a rewarded ad.
bool isRewardedPlacement(AdPlacement placement) {
  return placement == AdPlacement.rewardedBandwidthTest;
}
