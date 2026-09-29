import 'tweak_catalog.dart';

/// Everything the advisor looks at, measured on the device.
class DeviceSignals {
  const DeviceSignals({
    this.sdkInt = 0,
    this.ramGb,
    this.availableRamPercent,
    this.cpuCores,
    this.maxCpuGhz,
    this.maxRefreshHz = 60,
    this.batteryPercent,
    this.charging = false,
    this.batteryTempC,
    this.thermalStatus,
    this.thermalHeadroom,
    this.storageFreePercent,
    this.onWifi = false,
    this.rooted = false,
  });

  final int sdkInt;
  final double? ramGb;
  final int? availableRamPercent;
  final int? cpuCores;
  final double? maxCpuGhz;
  final double maxRefreshHz;
  final int? batteryPercent;
  final bool charging;
  final double? batteryTempC;
  final int? thermalStatus;
  final double? thermalHeadroom;
  final int? storageFreePercent;
  final bool onWifi;

  /// A root shell is available (su or root Shizuku).
  final bool rooted;

  bool get isHot =>
      (thermalStatus ?? 0) >= 2 || (thermalHeadroom ?? 0) >= 0.8 || (batteryTempC ?? 0) >= 42;

  bool get batteryLow => (batteryPercent ?? 100) < 20 && !charging;

  DeviceTier get tier {
    final ram = ramGb ?? 6;
    final ghz = maxCpuGhz ?? 2.4;
    final cores = cpuCores ?? 8;
    if (ram <= 4.5 || ghz < 2.0 || cores < 6) return DeviceTier.entry;
    if (ram >= 11 && ghz >= 2.9) return DeviceTier.flagship;
    return DeviceTier.midRange;
  }
}

enum DeviceTier {
  entry('Entry-level'),
  midRange('Mid-range'),
  flagship('Flagship');

  const DeviceTier(this.label);
  final String label;
}

enum AdviceKind { recommend, avoid }

/// One recommendation for a catalog tweak or action, with the reason why.
class Advice {
  const Advice({
    required this.id,
    required this.kind,
    required this.reason,
    this.priority = 1,
  });

  /// Catalog tweak id or action id.
  final String id;
  final AdviceKind kind;
  final String reason;

  /// Higher shows first.
  final int priority;

  bool get isAction => TweakCatalog.actions.any((a) => a.id == id);
  String get title =>
      TweakCatalog.byId(id)?.title ?? TweakCatalog.actions.firstWhere((a) => a.id == id).title;
}

/// Suggested ART compile setup for gaming.
class CompileAdvice {
  const CompileAdvice({
    required this.gamesOnly,
    required this.maxSpeed,
    required this.reason,
  });

  final bool gamesOnly;

  /// true → `speed` (compile everything), false → `speed-profile`.
  final bool maxSpeed;
  final String reason;

  String get modeLabel => maxSpeed ? 'Maximum (speed)' : 'Smart (speed-profile)';
  String get compilerFilter => maxSpeed ? 'speed' : 'speed-profile';
}

class DeviceAdvice {
  const DeviceAdvice({required this.signals, required this.items, required this.compile});

  final DeviceSignals signals;
  final List<Advice> items;
  final CompileAdvice compile;

  List<Advice> get recommended => items.where((a) => a.kind == AdviceKind.recommend).toList();
  List<Advice> get avoid => items.where((a) => a.kind == AdviceKind.avoid).toList();

  Set<String> get recommendedTweakIds =>
      recommended.where((a) => !a.isAction).map((a) => a.id).toSet();
}

/// Turns measured device signals into honest, explained recommendations.
///
/// Rules favour stability: anything that adds heat or drain is skipped
/// when the phone is already warm or low on battery, and GPU-saving tweaks
/// are only suggested where the GPU is likely to be the bottleneck.
abstract final class DeviceAdvisor {
  static DeviceAdvice analyze(DeviceSignals s) {
    final items = <Advice>[];
    final tier = s.tier;
    void rec(String id, String reason, [int p = 1]) =>
        items.add(Advice(id: id, kind: AdviceKind.recommend, reason: reason, priority: p));
    void avoid(String id, String reason) =>
        items.add(Advice(id: id, kind: AdviceKind.avoid, reason: reason));
    bool sdk(int min) => s.sdkInt == 0 || s.sdkInt >= min;

    // Display
    if (s.maxRefreshHz > 61 && sdk(TweakCatalog.refreshRateLock.minSdk)) {
      final hz = s.maxRefreshHz.round();
      if (s.batteryLow) {
        avoid(TweakCatalog.refreshRateLock.id,
            'Battery is at ${s.batteryPercent}% — $hz Hz would drain it faster.');
      } else {
        rec(TweakCatalog.refreshRateLock.id,
            'Your panel runs up to $hz Hz; this stops it dropping to 60 Hz in games.', 5);
      }
    }
    if (tier != DeviceTier.flagship && sdk(TweakCatalog.disableBlurs.minSdk)) {
      rec(TweakCatalog.disableBlurs.id,
          '${tier.label} GPU: skipping compositor blur leaves more GPU time for the game.', 3);
    }
    if (tier == DeviceTier.entry) {
      rec(TweakCatalog.animationScale.id,
          'Shorter animations make an entry-level phone feel noticeably snappier.', 2);
    }
    rec(TweakCatalog.autoBrightnessOff.id, 'Stops the screen dimming during dark game scenes.', 1);

    // Performance
    if (sdk(TweakCatalog.fixedPerformance.minSdk)) {
      if (s.isHot) {
        final t = s.batteryTempC != null ? ' (${s.batteryTempC!.toStringAsFixed(1)}°C)' : '';
        avoid(TweakCatalog.fixedPerformance.id,
            'Phone is already warm$t — sustained clocks would make it throttle harder.');
      } else if (s.batteryLow) {
        avoid(TweakCatalog.fixedPerformance.id, 'Battery is low — fixed clocks increase drain.');
      } else {
        rec(
          TweakCatalog.fixedPerformance.id,
          tier == DeviceTier.flagship
              ? 'Cool with headroom to spare: stable clocks remove boost/throttle frame-time swings.'
              : 'Stable clocks help a ${tier.label.toLowerCase()} CPU avoid sudden frame drops.',
          4,
        );
      }
    }

    // Focus
    rec(TweakCatalog.gamingDnd.id,
        'Keeps calls from priority contacts while silencing everything else.', 3);
    rec(TweakCatalog.headsUpOff.id, 'No notification banners covering your controls.', 3);
    if ((s.ramGb ?? 8) <= 6.5 || (s.availableRamPercent ?? 100) < 30) {
      rec(
          TweakCatalog.autoSyncOff.id,
          'With ${s.ramGb?.toStringAsFixed(0) ?? 'limited'} GB RAM, background sync competes with the game for memory and CPU.',
          2);
    } else {
      rec(TweakCatalog.autoSyncOff.id, 'Background sync can cause network spikes mid-match.', 1);
    }

    // Network
    if (s.onWifi && sdk(TweakCatalog.wifiLowLatency.minSdk)) {
      rec(TweakCatalog.wifiLowLatency.id,
          'You\'re on Wi-Fi: disabling Wi-Fi power-save removes periodic ping spikes.', 4);
    }
    if (s.batteryLow || ((s.batteryPercent ?? 100) < 50 && !s.charging)) {
      rec(TweakCatalog.scanOff.id,
          'Battery at ${s.batteryPercent}% — background radio scans are wasted energy.', 1);
    }

    // Maintenance
    final freeRam = s.availableRamPercent;
    if ((freeRam != null && freeRam < 30) || (s.ramGb ?? 8) <= 4.5) {
      rec(
          TweakCatalog.ramBoost.id,
          freeRam != null
              ? 'Only $freeRam% RAM free — stop cached apps before launching a game.'
              : 'Low total RAM — free memory before launching a game.',
          4);
    }
    final freeDisk = s.storageFreePercent;
    if (freeDisk != null && freeDisk < 15) {
      rec(TweakCatalog.trimCaches.id,
          'Only $freeDisk% storage free — low storage slows installs and game asset loading.', 3);
    }

    // Root (kernel)
    if (s.rooted) {
      rec(TweakCatalog.tcpBbr.id,
          'Rooted: BBR keeps TCP latency low when Wi-Fi or mobile signal drops packets.', 2);
      if (s.isHot || s.batteryLow) {
        avoid(
            TweakCatalog.cpuGovernorPerf.id,
            s.isHot
                ? 'Phone is warm — pinning CPU clocks would trigger harder throttling.'
                : 'Battery is low — max CPU clocks drain it fast.');
      } else {
        rec(TweakCatalog.cpuGovernorPerf.id,
            'Cool and charged: max CPU clocks while you play. Turn it off afterwards.', 3);
        if (tier != DeviceTier.flagship) {
          rec(TweakCatalog.gpuPerf.id, '${tier.label} GPU: stop it down-clocking mid-match.', 3);
        }
      }
      if (freeRam != null && freeRam < 30) {
        rec(TweakCatalog.dropCaches.id,
            'Only $freeRam% RAM free — drop the kernel page cache before launching.', 2);
      }
    }

    final compile = _compileAdvice(s);
    rec(TweakCatalog.compileApps.id,
        'Compile your games with ${compile.modeLabel}. ${compile.reason}', 2);

    items.sort((a, b) => b.priority.compareTo(a.priority));
    return DeviceAdvice(signals: s, items: items, compile: compile);
  }

  static CompileAdvice _compileAdvice(DeviceSignals s) {
    final free = s.storageFreePercent ?? 50;
    if (free < 10) {
      return const CompileAdvice(
        gamesOnly: true,
        maxSpeed: false,
        reason: 'Storage is tight, so profile-guided compiling keeps the extra code small.',
      );
    }
    return const CompileAdvice(
      gamesOnly: true,
      maxSpeed: true,
      reason:
          'Games run heavy Java/Kotlin code (engine launchers, SDKs). Full `speed` compilation removes '
          'JIT warm-up stutter, and a handful of games costs little storage.',
    );
  }
}
