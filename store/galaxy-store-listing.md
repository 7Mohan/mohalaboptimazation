# Samsung Galaxy Store — submission kit

## Before you submit
1. Build the signed release APK: `flutter build apk --release`
   (needs `android/key.properties` — see `android/key.properties.example`).
2. Publish `store/privacy-policy.md` as a web page, e.g.
   `https://mohagaminglab.vercel.app/privacy`, and use that URL below.
3. After Samsung approves the app: AdMob → App settings → **Link to app store**
   → Samsung Galaxy Store. Then publish `app-ads.txt` on your website.

## Listing fields
- **App name:** Moha Lab Optimization
- **Package:** com.mohalab.optimization
- **Category:** Tools
- **Price:** Free · **Contains ads:** Yes
- **Age rating:** 3+ (All)
- **Privacy policy URL:** https://mohagaminglab.vercel.app/privacy

**Short description**
Real Android gaming tweaks, live device stats and per-game tuning, with no placebo boosts.

**Full description**
Moha Lab Optimization applies real, verifiable Android tweaks and shows you exactly
what each one changes.

• Verified tweaks: max refresh rate, faster animations, window blurs, gaming Do Not
  Disturb, blocked pop-up banners, private DNS and more. Every change is read back
  from the device, and your original values are restored when you switch a tweak off.
• Recommended for your device: analyses RAM, CPU, display, temperature, battery and
  network, then suggests the right tweaks with a reason for each.
• Per-game tuning (Android 13+): Game Mode, render resolution and FPS limit for each
  game, plus Turbo Launch.
• ART compiler: compile your games or all apps with live progress, for faster launches
  and less stutter.
• Live stats: CPU clocks, thermal headroom, battery, RAM and storage.
• Gaming network test: ping, jitter and packet loss.
• Root mode (optional): Magisk, KernelSU and APatch users get kernel tweaks such as the
  CPU/GPU performance governor and TCP BBR.

Advanced features need Shizuku or a one-time ADB permission. Root features are optional.
No fake FPS boosts, spoofing or thermal bypasses.

Contains ads.

## Screenshots (at least 4, portrait)
1. Home — device card, live stats, CPU & thermals
2. Tweaks — "Recommended for your device" card
3. Tweaks — tweak switches (Display / Performance)
4. Game sheet — Game Mode / resolution / FPS
5. Compile All Apps — progress ring
6. Root tab (optional)

## Notes for Samsung reviewers (Notes to certification)
Some features require Shizuku (https://shizuku.rikka.app) or a one-time ADB
permission; without them the app shows which features are unavailable and why.
Root features are optional and only appear usable on rooted devices.
