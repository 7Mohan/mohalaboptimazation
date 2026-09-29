import 'package:flutter/foundation.dart';

import 'ad_placement.dart';

// ---------------------------------------------------------------------------
// Google Official Test Ad Unit IDs
// These are safe to commit and will never show real ads.
// https://developers.google.com/admob/android/test-ads
// ---------------------------------------------------------------------------
const _kTestAppId = 'ca-app-pub-3940256099942544~3347511713';
const _kTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
const _kTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
const _kTestRewardedId = 'ca-app-pub-3940256099942544/5224354917';

// ---------------------------------------------------------------------------
// Production AdMob IDs (account pub-9857418204934084)
// ---------------------------------------------------------------------------
const _kProductionAppId = 'ca-app-pub-9857418204934084~7368098906';
const _kProductionHomeBannerId = 'ca-app-pub-9857418204934084/1230065960';
// Reuses the Home banner unit (AdMob allows one unit in several places).
const _kProductionGamesBannerId = 'ca-app-pub-9857418204934084/1230065960';
const _kProductionOptimizationInterstitialId = 'ca-app-pub-9857418204934084/9207350648';
// Reuses the post-tweaks interstitial unit.
const _kProductionDiagnosticsInterstitialId = 'ca-app-pub-9857418204934084/9207350648';
const _kProductionRewardedId = 'ca-app-pub-9857418204934084/4066529590';

/// Holds all AdMob application and ad unit configuration.
class AdConfiguration {
  const AdConfiguration._({
    required this.appId,
    required this.isTestMode,
    required this.isPro,
    required this.adUnitIds,
  });

  /// Creates the configuration appropriate for the current build mode.
  factory AdConfiguration.forCurrentBuild({bool isPro = false}) {
    return kDebugMode
        ? AdConfiguration.test(isPro: isPro)
        : AdConfiguration.production(isPro: isPro);
  }

  /// Test configuration -- uses Google official test ad IDs.
  factory AdConfiguration.test({bool isPro = false}) {
    return AdConfiguration._(
      appId: _kTestAppId,
      isTestMode: true,
      isPro: isPro,
      adUnitIds: const {
        AdPlacement.homeBanner: _kTestBannerId,
        AdPlacement.gameDetailBanner: _kTestBannerId,
        AdPlacement.postOptimizationInterstitial: _kTestInterstitialId,
        AdPlacement.postDiagnosticsInterstitial: _kTestInterstitialId,
        AdPlacement.rewardedBandwidthTest: _kTestRewardedId,
      },
    );
  }

  /// Production configuration -- uses real AdMob ad unit IDs.
  factory AdConfiguration.production({bool isPro = false}) {
    return AdConfiguration._(
      appId: _kProductionAppId,
      isTestMode: false,
      isPro: isPro,
      adUnitIds: const {
        AdPlacement.homeBanner: _kProductionHomeBannerId,
        AdPlacement.gameDetailBanner: _kProductionGamesBannerId,
        AdPlacement.postOptimizationInterstitial:
            _kProductionOptimizationInterstitialId,
        AdPlacement.postDiagnosticsInterstitial:
            _kProductionDiagnosticsInterstitialId,
        AdPlacement.rewardedBandwidthTest: _kProductionRewardedId,
      },
    );
  }

  final String appId;
  final bool isTestMode;
  final bool isPro;
  final Map<AdPlacement, String> adUnitIds;

  /// Unit ID for [placement], or null while it is still a TODO placeholder
  /// (unconfigured placements simply never request an ad).
  String? adUnitId(AdPlacement placement) {
    final id = adUnitIds[placement];
    return id == null || id.startsWith('TODO') ? null : id;
  }

  bool isProductionReady(AdPlacement placement) {
    if (isTestMode) return true;
    final id = adUnitIds[placement];
    return id != null && !id.startsWith('TODO');
  }
}
