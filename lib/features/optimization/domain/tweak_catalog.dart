import 'package:flutter/material.dart';

import 'tweak.dart';

/// Every tweak the app offers. IDs must match TweakEngine.kt.
///
/// Inclusion rule: the change must be a real Android setting or `cmd`
/// service that the shell user can modify, with an effect that can be read
/// back. Popular "tweaks" that do nothing on modern Android (net.tcp.buffersize,
/// debug.hwc.*, ro.* props, invented touch settings) are intentionally absent.
abstract final class TweakCatalog {
  static const refreshRateLock = TweakDefinition(
    id: 'refresh_rate_lock',
    title: 'Lock Max Refresh Rate',
    summary: 'Keeps the panel at its highest refresh rate instead of dropping to 60 Hz.',
    category: TweakCategory.display,
    access: TweakAccess.settings,
    impact: TweakImpact.high,
    minSdk: 30,
    changes: 'settings put system min_refresh_rate / peak_refresh_rate <max Hz>',
    tradeoff: 'Higher screen power draw. Some OEM skins override this setting.',
  );

  static const animationScale = TweakDefinition(
    id: 'animation_scale',
    title: 'Faster Animations',
    summary: 'Halves window, transition and animator durations system-wide.',
    category: TweakCategory.display,
    access: TweakAccess.settings,
    changes: 'settings put global window/transition/animator scales 0.5',
    tradeoff: 'Purely perceptual — does not change game FPS.',
    impact: TweakImpact.low,
  );

  static const disableBlurs = TweakDefinition(
    id: 'disable_blurs',
    title: 'Disable Window Blurs',
    summary: 'Turns off compositor blur behind dialogs and the shade, saving GPU work.',
    category: TweakCategory.display,
    access: TweakAccess.settings,
    minSdk: 31,
    changes: 'settings put global disable_window_blurs 1',
    tradeoff: 'System panels use flat translucent backgrounds.',
    impact: TweakImpact.low,
  );

  static const fixedPerformance = TweakDefinition(
    id: 'fixed_performance',
    title: 'Fixed Performance Mode',
    summary: 'Asks the Power HAL for stable, sustained clocks instead of bursty boosts.',
    category: TweakCategory.performance,
    access: TweakAccess.shell,
    impact: TweakImpact.high,
    minSdk: 31,
    persistsReboot: false,
    changes: 'cmd power set-fixed-performance-mode-enabled true',
    tradeoff: 'More heat and battery drain. Only works if the device Power HAL supports it.',
  );

  static const gamingDnd = TweakDefinition(
    id: 'gaming_dnd',
    title: 'Gaming Do Not Disturb',
    summary: 'Priority-only mode: silences notifications, keeps priority calls and alarms.',
    category: TweakCategory.focus,
    access: TweakAccess.notificationPolicy,
    changes: 'NotificationManager.setInterruptionFilter(PRIORITY)',
    tradeoff: 'Non-priority notifications are held until you turn it off.',
  );

  static const headsUpOff = TweakDefinition(
    id: 'heads_up_off',
    title: 'Block Pop-up Banners',
    summary: 'Stops heads-up notifications from covering the game. Sounds still play.',
    category: TweakCategory.focus,
    access: TweakAccess.settings,
    changes: 'settings put global heads_up_notifications_enabled 0',
    tradeoff: 'You will not see notification banners until restored.',
  );

  static const privateDns = TweakDefinition(
    id: 'private_dns',
    title: 'Fast Private DNS',
    summary: 'Encrypted DNS via Cloudflare — faster lookups and no ISP DNS hijacking.',
    category: TweakCategory.network,
    access: TweakAccess.settings,
    minSdk: 28,
    changes: 'settings put global private_dns_mode hostname (one.one.one.one)',
    tradeoff: 'Does not lower in-game ping; only speeds up name resolution.',
    impact: TweakImpact.low,
  );

  static const scanOff = TweakDefinition(
    id: 'scan_off',
    title: 'Stop Background Radio Scans',
    summary: 'Disables Wi-Fi & Bluetooth scanning used for location accuracy.',
    category: TweakCategory.network,
    access: TweakAccess.settings,
    changes: 'settings put global wifi_scan_always_enabled 0, ble_scan_always_enabled 0',
    tradeoff: 'Slightly less accurate indoor location.',
    impact: TweakImpact.low,
  );

  static const touchHoldFast = TweakDefinition(
    id: 'touch_hold_fast',
    title: 'Faster Touch & Hold',
    summary: 'Long-press registers after 250 ms instead of the 400 ms default.',
    category: TweakCategory.input,
    access: TweakAccess.settings,
    changes: 'settings put secure long_press_timeout 250',
    tradeoff: 'Accidental long-presses become slightly more likely.',
    impact: TweakImpact.low,
  );

  static const autoBrightnessOff = TweakDefinition(
    id: 'auto_brightness_off',
    title: 'Stop Auto-Dimming',
    summary: 'Turns off adaptive brightness so the screen never dims mid-match.',
    category: TweakCategory.display,
    access: TweakAccess.settings,
    changes: 'settings put system screen_brightness_mode 0',
    tradeoff: 'Brightness stays where you set it, even in sunlight or the dark.',
    impact: TweakImpact.low,
  );

  static const wifiLowLatency = TweakDefinition(
    id: 'wifi_low_latency',
    title: 'Wi-Fi Low-Latency Mode',
    summary:
        'Holds Android\'s Wi-Fi low-latency and high-performance locks: no power-save naps, fewer ping spikes.',
    category: TweakCategory.network,
    access: TweakAccess.root,
    impact: TweakImpact.high,
    minSdk: 31,
    persistsReboot: false,
    changes: 'cmd wifi force-low-latency-mode enabled + force-hi-perf-mode enabled',
    tradeoff:
        'Android allows these Wi-Fi commands only as root. Higher Wi-Fi power draw; effect depends on the Wi-Fi driver.',
  );

  static const autoSyncOff = TweakDefinition(
    id: 'auto_sync_off',
    title: 'Pause Account Auto-Sync',
    summary:
        'Stops background syncing of mail, contacts, photos and other accounts while you play.',
    category: TweakCategory.focus,
    access: TweakAccess.none,
    changes: 'ContentResolver.setMasterSyncAutomatically(false)',
    tradeoff: 'New mail and cloud changes arrive only after you switch it back on.',
  );

  // Root-only kernel tweaks
  // Kernel values reset on reboot; the app re-applies active ones when the
  // root session resumes. Originals are saved per node and restored on off.

  static const cpuGovernorPerf = TweakDefinition(
    id: 'cpu_governor_perf',
    title: 'CPU Performance Governor',
    summary:
        'Sets every CPU cluster to the `performance` governor: cores stay at top clock, no ramp-up lag.',
    category: TweakCategory.kernel,
    access: TweakAccess.root,
    impact: TweakImpact.high,
    persistsReboot: false,
    changes: 'echo performance > /sys/devices/system/cpu/cpufreq/policy*/scaling_governor',
    tradeoff:
        'Much more heat and battery drain. Thermal limits still apply — use while playing, not all day.',
  );

  static const gpuPerf = TweakDefinition(
    id: 'gpu_perf',
    title: 'GPU Performance Governor',
    summary:
        'Switches the GPU devfreq governor (Adreno / Mali) to `performance` so it never down-clocks mid-frame.',
    category: TweakCategory.kernel,
    access: TweakAccess.root,
    impact: TweakImpact.high,
    persistsReboot: false,
    changes: 'echo performance > /sys/class/devfreq/<gpu>/governor',
    tradeoff: 'Higher GPU power and heat. Only offered when the kernel exposes a GPU devfreq node.',
  );

  static const tcpBbr = TweakDefinition(
    id: 'tcp_bbr',
    title: 'TCP BBR Congestion Control',
    summary:
        'Google\'s BBR algorithm keeps latency low on lossy Wi-Fi / mobile links instead of filling buffers.',
    category: TweakCategory.kernel,
    access: TweakAccess.root,
    persistsReboot: false,
    changes: 'echo bbr > /proc/sys/net/ipv4/tcp_congestion_control',
    tradeoff:
        'Affects TCP only (downloads, some game lobbies); most real-time game traffic is UDP. Needs a kernel built with BBR.',
  );

  static const swappinessLow = TweakDefinition(
    id: 'swappiness_low',
    title: 'Reduce Memory Swapping',
    summary:
        'Lowers vm.swappiness to 40 so the kernel compresses less memory into zRAM while you play.',
    category: TweakCategory.kernel,
    access: TweakAccess.root,
    impact: TweakImpact.low,
    persistsReboot: false,
    changes: 'echo 40 > /proc/sys/vm/swappiness',
    tradeoff:
        'Less CPU spent on compression, but background apps get closed sooner on low-RAM phones.',
  );

  static const List<TweakDefinition> all = [
    refreshRateLock,
    animationScale,
    disableBlurs,
    autoBrightnessOff,
    fixedPerformance,
    gamingDnd,
    headsUpOff,
    autoSyncOff,
    wifiLowLatency,
    privateDns,
    scanOff,
    touchHoldFast,
    cpuGovernorPerf,
    gpuPerf,
    tcpBbr,
    swappinessLow,
  ];

  /// Tweaks that work without root (Shizuku, ADB grant or none).
  static List<TweakDefinition> get nonRoot => all.where((t) => !t.access.isRoot).toList();

  /// Tweaks that need a root shell.
  static List<TweakDefinition> get rootOnly => all.where((t) => t.access.isRoot).toList();

  static TweakDefinition? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const ramBoost = TweakAction(
    id: 'ram_boost',
    title: 'RAM Boost',
    summary: 'Stops cached background apps and measures the memory actually freed.',
    icon: Icons.memory_rounded,
    access: TweakAccess.none,
  );

  static const trimCaches = TweakAction(
    id: 'trim_caches',
    title: 'Clear App Caches',
    summary: 'Clears every app\'s cache with Shizuku (this app\'s only without it).',
    icon: Icons.cleaning_services_rounded,
    access: TweakAccess.none,
  );

  static const compileApps = TweakAction(
    id: 'compile_apps',
    title: 'Compile All Apps',
    summary: 'AOT-compiles apps one by one with live progress. Faster launches, less jank.',
    icon: Icons.rocket_rounded,
    access: TweakAccess.shell,
    longRunning: true,
  );

  static const compileAll = TweakAction(
    id: 'compile_all',
    title: 'System Dexopt',
    summary: 'Runs Android\'s own dexopt job now instead of waiting for idle charging.',
    icon: Icons.bolt_rounded,
    access: TweakAccess.shell,
    longRunning: true,
  );

  static const dropCaches = TweakAction(
    id: 'drop_caches',
    title: 'Drop Kernel Caches',
    summary: 'Frees the kernel page cache (sync + drop_caches) and measures RAM freed.',
    icon: Icons.layers_clear_rounded,
    access: TweakAccess.root,
  );

  static const fstrim = TweakAction(
    id: 'fstrim',
    title: 'Storage TRIM',
    summary: 'Tells the flash which blocks are free so writes and game installs stay fast.',
    icon: Icons.storage_rounded,
    access: TweakAccess.root,
    longRunning: false,
  );

  static const List<TweakAction> quickActions = [ramBoost, trimCaches];
  static const List<TweakAction> rootActions = [dropCaches, fstrim];
  static const List<TweakAction> artActions = [compileApps, compileAll];
  static const List<TweakAction> actions = [...quickActions, ...artActions, ...rootActions];
}

/// Tuning presets built only from catalog tweaks.
enum TweakPreset {
  competitive(
    'Competitive',
    Icons.sports_esports_rounded,
    'Max refresh, stable clocks, zero interruptions.',
    {
      'refresh_rate_lock',
      'fixed_performance',
      'gaming_dnd',
      'heads_up_off',
      'disable_blurs',
      'animation_scale',
      'touch_hold_fast',
      'wifi_low_latency',
      'auto_sync_off',
      'auto_brightness_off',
    },
  ),
  balanced(
    'Balanced',
    Icons.tune_rounded,
    'Smooth display and no pop-ups, normal power use.',
    {'refresh_rate_lock', 'heads_up_off', 'animation_scale'},
  ),
  batterySaver(
    'Battery',
    Icons.eco_rounded,
    'Everything restored to system defaults.',
    <String>{},
  );

  const TweakPreset(this.label, this.icon, this.description, this.enabledIds);
  final String label;
  final IconData icon;
  final String description;

  /// Tweaks switched on by this preset; every other tweak is switched off.
  final Set<String> enabledIds;
}
