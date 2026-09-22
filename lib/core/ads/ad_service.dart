import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_configuration.dart';
import 'ad_placement.dart';
import 'ad_state.dart';

// ---------------------------------------------------------------------------
// Abstract interface -- allows FakeAdService in tests.
// ---------------------------------------------------------------------------

/// Callback type for rewarded ad reward delivery.
typedef OnRewardCallback = void Function(AdWithoutView ad, RewardItem reward);

/// Abstract contract for the ad service layer.
abstract class AdServiceBase {
  /// Initialize the underlying ad SDK. Must be called once before any
  /// load/show methods.
  Future<void> initialize();

  /// Returns the loaded [BannerAd] for [placement], or null if not ready.
  BannerAd? getBanner(AdPlacement placement);

  /// Returns the [AdState] for [placement].
  AdState getState(AdPlacement placement);

  /// Attempt to load a banner ad for [placement].
  /// Silently ignored if already loading, ready, or ads are disabled.
  Future<void> loadBanner(AdPlacement placement);

  /// Show an interstitial ad for [placement] if [canShow] is true
  /// and the ad is in [AdState.ready].
  Future<void> showInterstitial(
    AdPlacement placement, {
    required bool canShow,
  });

  /// Show a rewarded ad for [placement], calling [onRewarded] when the
  /// user earns the reward.
  Future<void> showRewarded(
    AdPlacement placement, {
    required bool canShow,
    required OnRewardCallback onRewarded,
  });

  /// Pre-load the next interstitial for [placement] so it is ready
  /// for the following trigger. Called automatically after a show.
  Future<void> preloadInterstitial(AdPlacement placement);

  /// Dispose all loaded ads and release resources.
  void dispose();
}

// ---------------------------------------------------------------------------
// Real implementation -- uses Google Mobile Ads SDK.
// ---------------------------------------------------------------------------

/// Production [AdServiceBase] backed by the Google Mobile Ads SDK.
class AdService implements AdServiceBase {
  AdService({required AdConfiguration configuration})
      : _config = configuration;

  final AdConfiguration _config;
  final Map<AdPlacement, BannerAd?> _banners = {};
  final Map<AdPlacement, InterstitialAd?> _interstitials = {};
  final Map<AdPlacement, RewardedAd?> _rewardedAds = {};
  final Map<AdPlacement, AdState> _states = {};

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb || _config.isPro) {
      for (final p in AdPlacement.values) {
        _states[p] = AdState.disabled;
      }
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[AdService] Initialized -- testMode=${_config.isTestMode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] Initialization error: $e');
    }
  }

  @override
  BannerAd? getBanner(AdPlacement placement) => _banners[placement];

  @override
  AdState getState(AdPlacement placement) =>
      _states[placement] ?? AdState.idle;

  @override
  Future<void> loadBanner(AdPlacement placement) async {
    if (_config.isPro) return;
    if (!_initialized) return;

    final currentState = getState(placement);
    if (currentState == AdState.loading ||
        currentState == AdState.ready ||
        currentState == AdState.disabled) {
      return;
    }

    final unitId = _config.adUnitId(placement);
    if (unitId == null) return;

    _states[placement] = AdState.loading;

    try {
      final banner = BannerAd(
        adUnitId: unitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _banners[placement] = ad as BannerAd;
            _states[placement] = AdState.ready;
            if (kDebugMode) {
              debugPrint('[AdService] Banner loaded: $placement');
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _banners[placement] = null;
            _states[placement] = AdState.failed;
            if (kDebugMode) {
              debugPrint('[AdService] Banner failed: $placement -- $error');
            }
          },
        ),
      );
      await banner.load();
    } catch (e) {
      _states[placement] = AdState.failed;
      if (kDebugMode) debugPrint('[AdService] Banner load exception: $e');
    }
  }

  @override
  Future<void> showInterstitial(
    AdPlacement placement, {
    required bool canShow,
  }) async {
    if (_config.isPro || !canShow || !_initialized) return;

    if (getState(placement) != AdState.ready) {
      unawaited(_loadInterstitial(placement));
      return;
    }

    final ad = _interstitials[placement];
    if (ad == null) return;

    _states[placement] = AdState.showing;
    try {
      await ad.show();
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] Interstitial show error: $e');
      _states[placement] = AdState.failed;
    } finally {
      _interstitials[placement] = null;
      unawaited(preloadInterstitial(placement));
    }
  }

  @override
  Future<void> showRewarded(
    AdPlacement placement, {
    required bool canShow,
    required OnRewardCallback onRewarded,
  }) async {
    if (_config.isPro || !canShow || !_initialized) return;

    if (getState(placement) != AdState.ready) {
      unawaited(_loadRewarded(placement));
      return;
    }

    final ad = _rewardedAds[placement];
    if (ad == null) return;

    _states[placement] = AdState.showing;
    try {
      await ad.show(onUserEarnedReward: onRewarded);
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] Rewarded show error: $e');
      _states[placement] = AdState.failed;
    } finally {
      _rewardedAds[placement] = null;
      _states[placement] = AdState.idle;
      unawaited(_loadRewarded(placement));
    }
  }

  @override
  Future<void> preloadInterstitial(AdPlacement placement) =>
      _loadInterstitial(placement);

  Future<void> _loadInterstitial(AdPlacement placement) async {
    if (_config.isPro || !_initialized) return;
    if (getState(placement) == AdState.loading ||
        getState(placement) == AdState.ready) {
      return;
    }

    final unitId = _config.adUnitId(placement);
    if (unitId == null) return;

    _states[placement] = AdState.loading;
    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitials[placement] = ad;
            _states[placement] = AdState.ready;
            if (kDebugMode) {
              debugPrint('[AdService] Interstitial ready: $placement');
            }
          },
          onAdFailedToLoad: (error) {
            _interstitials[placement] = null;
            _states[placement] = AdState.failed;
            if (kDebugMode) {
              debugPrint('[AdService] Interstitial failed: $placement -- $error');
            }
          },
        ),
      );
    } catch (e) {
      _states[placement] = AdState.failed;
      if (kDebugMode) debugPrint('[AdService] Interstitial load exception: $e');
    }
  }

  Future<void> _loadRewarded(AdPlacement placement) async {
    if (_config.isPro || !_initialized) return;
    if (getState(placement) == AdState.loading ||
        getState(placement) == AdState.ready) {
      return;
    }

    final unitId = _config.adUnitId(placement);
    if (unitId == null) return;

    _states[placement] = AdState.loading;
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAds[placement] = ad;
            _states[placement] = AdState.ready;
            if (kDebugMode) {
              debugPrint('[AdService] Rewarded ready: $placement');
            }
          },
          onAdFailedToLoad: (error) {
            _rewardedAds[placement] = null;
            _states[placement] = AdState.failed;
            if (kDebugMode) {
              debugPrint('[AdService] Rewarded failed: $placement -- $error');
            }
          },
        ),
      );
    } catch (e) {
      _states[placement] = AdState.failed;
      if (kDebugMode) debugPrint('[AdService] Rewarded load exception: $e');
    }
  }

  @override
  void dispose() {
    for (final banner in _banners.values) {
      banner?.dispose();
    }
    for (final interstitial in _interstitials.values) {
      interstitial?.dispose();
    }
    for (final rewarded in _rewardedAds.values) {
      rewarded?.dispose();
    }
    _banners.clear();
    _interstitials.clear();
    _rewardedAds.clear();
    _states.clear();
    _initialized = false;
  }
}

// ---------------------------------------------------------------------------
// Fake implementation -- used in unit and widget tests.
// ---------------------------------------------------------------------------

/// Test double for [AdServiceBase].
class FakeAdService implements AdServiceBase {
  final Map<AdPlacement, AdState> _states = {};
  bool initialized = false;
  int showInterstitialCallCount = 0;
  int showRewardedCallCount = 0;
  bool lastCanShow = false;

  void simulateAdReady(AdPlacement placement) {
    _states[placement] = AdState.ready;
  }

  void simulateAdFailed(AdPlacement placement) {
    _states[placement] = AdState.failed;
  }

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  BannerAd? getBanner(AdPlacement placement) => null;

  @override
  AdState getState(AdPlacement placement) =>
      _states[placement] ?? AdState.idle;

  @override
  Future<void> loadBanner(AdPlacement placement) async {
    _states[placement] = AdState.idle;
  }

  @override
  Future<void> showInterstitial(
    AdPlacement placement, {
    required bool canShow,
  }) async {
    lastCanShow = canShow;
    if (!canShow) return;
    if (getState(placement) != AdState.ready) return;
    showInterstitialCallCount++;
    _states[placement] = AdState.idle;
  }

  @override
  Future<void> showRewarded(
    AdPlacement placement, {
    required bool canShow,
    required OnRewardCallback onRewarded,
  }) async {
    lastCanShow = canShow;
    if (!canShow) return;
    if (getState(placement) != AdState.ready) return;
    showRewardedCallCount++;
    onRewarded(
      FakeAdWithoutView(),
      RewardItem(1, 'bandwidth_test'),
    );
    _states[placement] = AdState.idle;
  }

  @override
  Future<void> preloadInterstitial(AdPlacement placement) async {}

  @override
  void dispose() {
    _states.clear();
    initialized = false;
  }
}

/// Minimal [AdWithoutView] stub for [FakeAdService] reward callbacks.
class FakeAdWithoutView implements AdWithoutView {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
