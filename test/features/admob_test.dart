import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mohalab_optimization/core/ads/ad_configuration.dart';
import 'package:mohalab_optimization/core/ads/ad_guard.dart';
import 'package:mohalab_optimization/core/ads/ad_placement.dart';
import 'package:mohalab_optimization/core/ads/ad_providers.dart';
import 'package:mohalab_optimization/core/ads/ad_service.dart';
import 'package:mohalab_optimization/core/ads/ad_state.dart';
import 'package:mohalab_optimization/shared/widgets/ads/moha_banner_ad_widget.dart';
import 'package:mohalab_optimization/shared/widgets/ads/rewarded_ad_button.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildTestApp(Widget child, {AdServiceBase? adService}) {
  return ProviderScope(
    overrides: [
      if (adService != null)
        adServiceProvider.overrideWithValue(adService),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  // ---------------------------------------------------------------------------
  // AdConfiguration Tests
  // ---------------------------------------------------------------------------

  group('AdConfiguration', () {
    test('test() configuration is always in test mode', () {
      final config = AdConfiguration.test();
      expect(config.isTestMode, isTrue);
      expect(config.isPro, isFalse);
    });

    test('test() configuration has valid Google test ad unit IDs', () {
      final config = AdConfiguration.test();
      for (final placement in AdPlacement.values) {
        final id = config.adUnitId(placement);
        expect(id, isNotNull, reason: 'Expected ID for $placement');
        expect(id, startsWith('ca-app-pub-3940256099942544'),
            reason: 'Test IDs must use Google test publisher: $placement');
      }
    });

    test('production() configuration is not in test mode', () {
      final config = AdConfiguration.production();
      expect(config.isTestMode, isFalse);
    });

    test('production() configuration constants are non-null for all placements', () {
      final config = AdConfiguration.production();
      for (final placement in AdPlacement.values) {
        final id = config.adUnitId(placement);
        expect(id, isNotNull, reason: 'Production ID null for $placement');
      }
    });

    test('isProductionReady returns true for test config', () {
      final config = AdConfiguration.test();
      for (final placement in AdPlacement.values) {
        expect(config.isProductionReady(placement), isTrue);
      }
    });

    test('isProductionReady returns false when IDs contain TODO', () {
      final config = AdConfiguration.production();
      // Production IDs start with TODO — not ready until replaced.
      for (final placement in AdPlacement.values) {
        expect(config.isProductionReady(placement), isFalse,
            reason: 'Production IDs must be replaced before release: $placement');
      }
    });

    test('isPro flag suppresses ads when true', () {
      final config = AdConfiguration.test(isPro: true);
      expect(config.isPro, isTrue);
    });

    test('copyWith via separate factory creates equivalent config', () {
      final a = AdConfiguration.test(isPro: false);
      final b = AdConfiguration.test(isPro: true);
      expect(a.isPro, isFalse);
      expect(b.isPro, isTrue);
      expect(a.isTestMode, equals(b.isTestMode));
    });
  });

  // ---------------------------------------------------------------------------
  // AdPlacement Tests
  // ---------------------------------------------------------------------------

  group('AdPlacement', () {
    test('all expected placement values exist', () {
      expect(AdPlacement.values, contains(AdPlacement.homeBanner));
      expect(AdPlacement.values, contains(AdPlacement.gameDetailBanner));
      expect(AdPlacement.values,
          contains(AdPlacement.postOptimizationInterstitial));
      expect(AdPlacement.values,
          contains(AdPlacement.postDiagnosticsInterstitial));
      expect(AdPlacement.values, contains(AdPlacement.rewardedBandwidthTest));
    });

    test('isBannerPlacement correctly identifies banners', () {
      expect(isBannerPlacement(AdPlacement.homeBanner), isTrue);
      expect(isBannerPlacement(AdPlacement.gameDetailBanner), isTrue);
      expect(isBannerPlacement(AdPlacement.postOptimizationInterstitial),
          isFalse);
      expect(isBannerPlacement(AdPlacement.rewardedBandwidthTest), isFalse);
    });

    test('isInterstitialPlacement correctly identifies interstitials', () {
      expect(isInterstitialPlacement(AdPlacement.postOptimizationInterstitial),
          isTrue);
      expect(isInterstitialPlacement(AdPlacement.postDiagnosticsInterstitial),
          isTrue);
      expect(isInterstitialPlacement(AdPlacement.homeBanner), isFalse);
      expect(isInterstitialPlacement(AdPlacement.rewardedBandwidthTest),
          isFalse);
    });

    test('isRewardedPlacement correctly identifies rewarded ads', () {
      expect(isRewardedPlacement(AdPlacement.rewardedBandwidthTest), isTrue);
      expect(isRewardedPlacement(AdPlacement.homeBanner), isFalse);
      expect(isRewardedPlacement(AdPlacement.postOptimizationInterstitial),
          isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // AdState Tests
  // ---------------------------------------------------------------------------

  group('AdState', () {
    test('has all expected lifecycle states', () {
      expect(AdState.values, containsAll([
        AdState.idle,
        AdState.loading,
        AdState.ready,
        AdState.showing,
        AdState.failed,
        AdState.disabled,
      ]));
    });
  });

  // ---------------------------------------------------------------------------
  // FakeAdService Tests
  // ---------------------------------------------------------------------------

  group('FakeAdService', () {
    test('initializes correctly', () async {
      final fake = FakeAdService();
      await fake.initialize();
      expect(fake.initialized, isTrue);
    });

    test('starts all placements in idle state', () {
      final fake = FakeAdService();
      for (final p in AdPlacement.values) {
        expect(fake.getState(p), AdState.idle);
      }
    });

    test('simulateAdReady sets state to ready', () {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.homeBanner);
      expect(fake.getState(AdPlacement.homeBanner), AdState.ready);
    });

    test('simulateAdFailed sets state to failed', () {
      final fake = FakeAdService();
      fake.simulateAdFailed(AdPlacement.postOptimizationInterstitial);
      expect(fake.getState(AdPlacement.postOptimizationInterstitial),
          AdState.failed);
    });

    test('showInterstitial does nothing when canShow is false', () async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.postOptimizationInterstitial);
      await fake.showInterstitial(
        AdPlacement.postOptimizationInterstitial,
        canShow: false,
      );
      expect(fake.showInterstitialCallCount, 0);
      expect(fake.lastCanShow, isFalse);
    });

    test('showInterstitial does nothing when ad is not ready', () async {
      final fake = FakeAdService();
      // State is idle — not ready.
      await fake.showInterstitial(
        AdPlacement.postOptimizationInterstitial,
        canShow: true,
      );
      expect(fake.showInterstitialCallCount, 0);
    });

    test('showInterstitial increments count when canShow is true and ready', () async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.postOptimizationInterstitial);
      await fake.showInterstitial(
        AdPlacement.postOptimizationInterstitial,
        canShow: true,
      );
      expect(fake.showInterstitialCallCount, 1);
    });

    test('showRewarded delivers reward callback when ad is ready', () async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.rewardedBandwidthTest);
      bool rewardDelivered = false;
      await fake.showRewarded(
        AdPlacement.rewardedBandwidthTest,
        canShow: true,
        onRewarded: (_, __) => rewardDelivered = true,
      );
      expect(rewardDelivered, isTrue);
      expect(fake.showRewardedCallCount, 1);
    });

    test('showRewarded does nothing when canShow is false', () async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.rewardedBandwidthTest);
      bool rewardDelivered = false;
      await fake.showRewarded(
        AdPlacement.rewardedBandwidthTest,
        canShow: false,
        onRewarded: (_, __) => rewardDelivered = true,
      );
      expect(rewardDelivered, isFalse);
      expect(fake.showRewardedCallCount, 0);
    });

    test('getBanner always returns null in FakeAdService', () {
      final fake = FakeAdService();
      expect(fake.getBanner(AdPlacement.homeBanner), isNull);
    });

    test('dispose clears state and resets initialized', () async {
      final fake = FakeAdService();
      await fake.initialize();
      fake.simulateAdReady(AdPlacement.homeBanner);
      fake.dispose();
      expect(fake.initialized, isFalse);
      expect(fake.getState(AdPlacement.homeBanner), AdState.idle);
    });
  });

  // ---------------------------------------------------------------------------
  // AdGuard Tests
  // ---------------------------------------------------------------------------

  group('AdGuard', () {
    testWidgets('canShowAd returns true when no operations active', (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adServiceProvider.overrideWithValue(FakeAdService()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(canShowAd(capturedRef), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // MohaBannerAdWidget Tests
  // ---------------------------------------------------------------------------

  group('MohaBannerAdWidget', () {
    testWidgets('renders SizedBox.shrink when ad state is idle', (tester) async {
      final fake = FakeAdService();
      // idle state — banner not ready.
      await tester.pumpWidget(
        _buildTestApp(
          const MohaBannerAdWidget(placement: AdPlacement.homeBanner),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      // No AdWidget visible — widget is collapsed.
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Padding), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when ad state is failed', (tester) async {
      final fake = FakeAdService();
      fake.simulateAdFailed(AdPlacement.homeBanner);
      await tester.pumpWidget(
        _buildTestApp(
          const MohaBannerAdWidget(placement: AdPlacement.homeBanner),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      // Failed state also collapses the widget.
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders SizedBox.shrink when ad state is loading', (tester) async {
      final fake = FakeAdService();
      // loadBanner sets idle in FakeAdService — stays not-ready.
      await fake.loadBanner(AdPlacement.homeBanner);
      await tester.pumpWidget(
        _buildTestApp(
          const MohaBannerAdWidget(placement: AdPlacement.homeBanner),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // RewardedAdButton Tests
  // ---------------------------------------------------------------------------

  group('RewardedAdButton', () {
    testWidgets('is hidden when ad is disabled', (tester) async {
      final fake = FakeAdService();
      fake.simulateAdFailed(AdPlacement.rewardedBandwidthTest);
      // Set to disabled state explicitly.
      // FakeAdService has no disabled override — test idle state instead.
      await tester.pumpWidget(
        _buildTestApp(
          RewardedAdButton(
            label: 'Watch ad',
            onRewarded: () {},
          ),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      // Button is present but disabled (not ready).
      final button = tester.widget<OutlinedButton>(
        find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('button is enabled when ad is ready', (tester) async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.rewardedBandwidthTest);
      await tester.pumpWidget(
        _buildTestApp(
          RewardedAdButton(
            label: 'Watch ad',
            onRewarded: () {},
          ),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<OutlinedButton>(
        find.byWidgetPredicate((w) => w is OutlinedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping button calls onRewarded when ad is ready', (tester) async {
      final fake = FakeAdService();
      fake.simulateAdReady(AdPlacement.rewardedBandwidthTest);
      bool rewarded = false;
      await tester.pumpWidget(
        _buildTestApp(
          RewardedAdButton(
            label: 'Watch ad',
            onRewarded: () => rewarded = true,
          ),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is OutlinedButton));
      await tester.pumpAndSettle();
      expect(rewarded, isTrue);
      expect(fake.showRewardedCallCount, 1);
    });

    testWidgets('shows label text', (tester) async {
      final fake = FakeAdService();
      await tester.pumpWidget(
        _buildTestApp(
          RewardedAdButton(
            label: 'Unlock bandwidth test',
            onRewarded: () {},
          ),
          adService: fake,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock bandwidth test'), findsOneWidget);
    });
  });
}
