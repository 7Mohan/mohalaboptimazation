# Production AdMob Setup Guide

This document describes the steps required before publishing Moha Lab Optimization
to the Google Play Store with live ads.

---

## Step 1 — Create an AdMob Account

1. Go to https://admob.google.com
2. Sign in with your Google account.
3. Complete account setup and accept the AdMob Terms of Service.

---

## Step 2 — Register the App

1. In AdMob, click **Add App**.
2. Select **Android**.
3. Search for "Moha Lab Optimization" if already published, or select **Add app manually**.
4. Package name: `com.mohalab.optimization`
5. Note the **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`).

---

## Step 3 — Create Ad Units

Create three ad units in AdMob:

| Type | Suggested Name |
|---|---|
| Banner | Moha Lab - Home Banner |
| Banner | Moha Lab - Games Banner |
| Interstitial | Moha Lab - Post Optimization |
| Interstitial | Moha Lab - Post Diagnostics |
| Rewarded | Moha Lab - Bandwidth Test Unlock |

Note all Ad Unit IDs (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`).

---

## Step 4 — Update `AndroidManifest.xml`

In `android/app/src/main/AndroidManifest.xml`, replace:

```xml
android:value="ca-app-pub-3940256099942544~3347511713"
```

with your real AdMob App ID:

```xml
android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
```

---

## Step 5 — Update `AdConfiguration.production()`

In `lib/core/ads/ad_configuration.dart`, replace the `TODO` constants:

```dart
const _kProductionAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
const _kProductionHomeBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
const _kProductionGamesBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
const _kProductionOptimizationInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
const _kProductionDiagnosticsInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
const _kProductionRewardedId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

---

## Step 6 — Build in Release Mode

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

In release builds `kDebugMode == false`, so `AdConfiguration.forCurrentBuild()`
automatically selects the production IDs.

---

## Step 7 — Test Real Ads on a Physical Device

Before submitting to Play Store:
1. Install the release APK on a physical device.
2. Verify real ads appear (not the Google watermark test ads).
3. Confirm no ads appear during active optimization or diagnostics.
4. Confirm banners appear on Home and Games screens.
5. Confirm interstitials appear after optimization result and after diagnostics complete.
6. Confirm rewarded ad correctly unlocks the bandwidth test.

---

## Important Notes

- **Never use production Ad Unit IDs in debug builds.** This risks invalid traffic
  violations. The code guards against this automatically via `kDebugMode`.
- **AdMob policy**: Do not incentivize ad clicks, place ads near buttons,
  or show ads on loading screens. The current implementation is designed to be
  compliant.
- **Future Pro gating**: When a Pro subscription is added, set `isPro = true`
  in `AdConfiguration.forCurrentBuild(isPro: entitlementService.isPro)`. All
  ads will be silently suppressed for Pro users.

---

## Test Ad Unit IDs Reference (Development Only)

These are safe to use in development. Do not use them in production.

| Type | Test Unit ID |
|---|---|
| Banner | `ca-app-pub-3940256099942544/6300978111` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |
| App ID | `ca-app-pub-3940256099942544~3347511713` |
