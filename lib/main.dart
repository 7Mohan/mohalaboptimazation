import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ads/ad_configuration.dart';
import 'core/ads/ad_placement.dart';
import 'core/ads/ad_providers.dart';
import 'core/ads/ad_service.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Lock to portrait orientations only (typical for mobile gaming utility)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Transparent status and navigation bars — the app chrome handles them.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  // Initialise SharedPreferences synchronously before the widget tree is built.
  final prefs = await SharedPreferences.getInstance();

  // Initialise the Google Mobile Ads SDK.
  final adConfig = AdConfiguration.forCurrentBuild();
  final adService = AdService(configuration: adConfig);
  await adService.initialize();

  if (!kIsWeb) {
    // Pre-load banner ads for screens that will show them immediately.
    unawaited(adService.loadBanner(AdPlacement.homeBanner));
    unawaited(adService.loadBanner(AdPlacement.gameDetailBanner));

    // Pre-load interstitials so they are ready when needed (no cold-load delay).
    unawaited(adService.preloadInterstitial(AdPlacement.postOptimizationInterstitial));
    unawaited(adService.preloadInterstitial(AdPlacement.postDiagnosticsInterstitial));
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject the real SharedPreferences instance.
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Inject the already-initialized AdService singleton.
        adServiceProvider.overrideWithValue(adService),
      ],
      child: const MohaLabApp(),
    ),
  );
}
