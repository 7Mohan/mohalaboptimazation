import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/tailwind_tokens.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/tailwind/tailwind_badge.dart';
import '../../../../shared/widgets/tailwind/tailwind_card.dart';
import '../../../optimization/data/services/optimization_native_bridge.dart';
import '../../../optimization/domain/entities/optimization_profile.dart';
import '../../../optimization/presentation/providers/optimization_providers.dart';
import '../../../shizuku/presentation/widgets/shizuku_status_banner.dart';

/// State representing active hardware and kernel optimizations.
class HardwareTweaksState {
  const HardwareTweaksState({
    this.fixedGovernor = false,
    this.zeroTouchLatency = false,
    this.disableBlurs = false,
    this.tcpBuffers = false,
    this.gpuVsync = false,
    this.lock120Hz = false,
    this.zenDnd = false,
    this.bypassFpsCap = false,
    this.isApplying = false,
  });

  final bool fixedGovernor;
  final bool zeroTouchLatency;
  final bool disableBlurs;
  final bool tcpBuffers;
  final bool gpuVsync;
  final bool lock120Hz;
  final bool zenDnd;
  final bool bypassFpsCap;
  final bool isApplying;

  HardwareTweaksState copyWith({
    bool? fixedGovernor,
    bool? zeroTouchLatency,
    bool? disableBlurs,
    bool? tcpBuffers,
    bool? gpuVsync,
    bool? lock120Hz,
    bool? zenDnd,
    bool? bypassFpsCap,
    bool? isApplying,
  }) {
    return HardwareTweaksState(
      fixedGovernor: fixedGovernor ?? this.fixedGovernor,
      zeroTouchLatency: zeroTouchLatency ?? this.zeroTouchLatency,
      disableBlurs: disableBlurs ?? this.disableBlurs,
      tcpBuffers: tcpBuffers ?? this.tcpBuffers,
      gpuVsync: gpuVsync ?? this.gpuVsync,
      lock120Hz: lock120Hz ?? this.lock120Hz,
      zenDnd: zenDnd ?? this.zenDnd,
      bypassFpsCap: bypassFpsCap ?? this.bypassFpsCap,
      isApplying: isApplying ?? this.isApplying,
    );
  }
}

// Backward-compatibility alias
typedef CyberTweaksState = HardwareTweaksState;

final hardwareTweaksProvider =
    StateNotifierProvider<HardwareTweaksNotifier, HardwareTweaksState>((ref) {
  final bridge = ref.watch(optimizationBridgeProvider);
  return HardwareTweaksNotifier(bridge);
});

// Backward-compatibility alias
final cyberTweaksProvider = hardwareTweaksProvider;

class HardwareTweaksNotifier extends StateNotifier<HardwareTweaksState> {
  HardwareTweaksNotifier(this._bridge) : super(const HardwareTweaksState());

  final OptimizationNativeBridge _bridge;

  Future<void> toggleFixedGovernor(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setFixedPerformanceMode(value);
    state = state.copyWith(fixedGovernor: value, isApplying: false);
  }

  Future<void> toggleTouchLatency(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setTouchLatency(value);
    state = state.copyWith(zeroTouchLatency: value, isApplying: false);
  }

  Future<void> toggleDisableBlurs(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setBlurDisabled(value);
    state = state.copyWith(disableBlurs: value, isApplying: false);
  }

  Future<void> toggleTcpBuffers(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.optimizeNetworkBuffers(value);
    state = state.copyWith(tcpBuffers: value, isApplying: false);
  }

  Future<void> toggleGpuVsync(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setGpuRenderingProfile(value);
    state = state.copyWith(gpuVsync: value, isApplying: false);
  }

  Future<void> toggleLock120Hz(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setMinRefreshRate(value ? 120.0 : 60.0);
    state = state.copyWith(lock120Hz: value, isApplying: false);
  }

  Future<void> toggleZenDnd(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.setDndInterruptionFilter(value ? 2 : 1);
    state = state.copyWith(zenDnd: value, isApplying: false);
  }

  Future<void> toggleBypassFpsCap(bool value) async {
    state = state.copyWith(isApplying: true);
    await _bridge.bypassRenderPipelineFpsCap(enabled: value, targetHz: 144.0);
    state = state.copyWith(bypassFpsCap: value, isApplying: false);
  }

  Future<void> applyPerformancePreset() async {
    state = state.copyWith(isApplying: true);
    await Future.wait([
      _bridge.setFixedPerformanceMode(true),
      _bridge.setTouchLatency(true),
      _bridge.setBlurDisabled(true),
      _bridge.optimizeNetworkBuffers(true),
      _bridge.setGpuRenderingProfile(true),
      _bridge.setMinRefreshRate(120.0),
      _bridge.setDndInterruptionFilter(2),
      _bridge.deepRamClean(),
      _bridge.bypassRenderPipelineFpsCap(enabled: true, targetHz: 144.0),
    ]);
    state = state.copyWith(
      fixedGovernor: true,
      zeroTouchLatency: true,
      disableBlurs: true,
      tcpBuffers: true,
      gpuVsync: true,
      lock120Hz: true,
      zenDnd: true,
      bypassFpsCap: true,
      isApplying: false,
    );
  }

  Future<void> applyBalancedPreset() async {
    state = state.copyWith(isApplying: true);
    await Future.wait([
      _bridge.setFixedPerformanceMode(false),
      _bridge.setTouchLatency(true),
      _bridge.setBlurDisabled(false),
      _bridge.optimizeNetworkBuffers(true),
      _bridge.setGpuRenderingProfile(false),
      _bridge.setMinRefreshRate(90.0),
      _bridge.setDndInterruptionFilter(2),
    ]);
    state = state.copyWith(
      fixedGovernor: false,
      zeroTouchLatency: true,
      disableBlurs: false,
      tcpBuffers: true,
      gpuVsync: false,
      lock120Hz: false,
      zenDnd: true,
      isApplying: false,
    );
  }

  Future<void> applyBatterySaverPreset() async {
    state = state.copyWith(isApplying: true);
    await Future.wait([
      _bridge.setFixedPerformanceMode(false),
      _bridge.setTouchLatency(false),
      _bridge.setBlurDisabled(false),
      _bridge.optimizeNetworkBuffers(false),
      _bridge.setGpuRenderingProfile(false),
      _bridge.setMinRefreshRate(60.0),
      _bridge.setDndInterruptionFilter(1),
      _bridge.bypassRenderPipelineFpsCap(enabled: false),
    ]);
    state = state.copyWith(
      fixedGovernor: false,
      zeroTouchLatency: false,
      disableBlurs: false,
      tcpBuffers: false,
      gpuVsync: false,
      lock120Hz: false,
      zenDnd: false,
      bypassFpsCap: false,
      isApplying: false,
    );
  }

  // Backward compatibility alias
  Future<void> applyBeastPreset() => applyPerformancePreset();
  Future<void> applyEcoPreset() => applyBatterySaverPreset();
}

/// Hardware Performance Control Engine Screen
class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweaks = ref.watch(hardwareTweaksProvider);

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'Performance Engine',
        subtitle: 'Hardware Governor & Display Pipeline Tuning',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // ── Shizuku Privileged Status Banner ──────────────────────────────
          const ShizukuStatusBanner(),
          const SizedBox(height: AppSpacing.sm),

          // ── Tailwind Hardware Performance Status Card ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _PerformanceStatusCard(tweaks: tweaks),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Presets Section Header ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 16,
                  color: TailwindColors.zinc400,
                ),
                SizedBox(width: 8),
                Text(
                  'TUNING PROFILES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: TailwindColors.zinc400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Tuning Profile Deck ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _TuningProfileCard(
                    title: 'Performance',
                    subtitle: 'Max Throughput',
                    icon: Icons.speed_rounded,
                    accentColor: TailwindColors.blue500,
                    isActive: tweaks.fixedGovernor && tweaks.lock120Hz,
                    onTap: () async {
                      ref.read(selectedProfileProvider.notifier).state =
                          OptimizationProfile.extreme;
                      await ref
                          .read(hardwareTweaksProvider.notifier)
                          .applyPerformancePreset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Performance Profile applied: Peak clocks & 120/144Hz locked.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TuningProfileCard(
                    title: 'Balanced',
                    subtitle: 'Adaptive Rate',
                    icon: Icons.tune_rounded,
                    accentColor: TailwindColors.emerald500,
                    isActive: !tweaks.fixedGovernor && tweaks.zeroTouchLatency,
                    onTap: () async {
                      ref.read(selectedProfileProvider.notifier).state =
                          OptimizationProfile.balanced;
                      await ref
                          .read(hardwareTweaksProvider.notifier)
                          .applyBalancedPreset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Balanced Profile applied.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TuningProfileCard(
                    title: 'Power Saver',
                    subtitle: 'Thermal Focus',
                    icon: Icons.energy_savings_leaf_outlined,
                    accentColor: TailwindColors.amber500,
                    isActive: !tweaks.fixedGovernor && !tweaks.zeroTouchLatency,
                    onTap: () async {
                      ref.read(selectedProfileProvider.notifier).state =
                          OptimizationProfile.batterySaver;
                      await ref
                          .read(hardwareTweaksProvider.notifier)
                          .applyBatterySaverPreset();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Power Saver Profile applied.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Quick Maintenance Action ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TailwindCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TailwindColors.zinc800,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TailwindColors.zinc700, width: 1),
                    ),
                    child: const Icon(
                      Icons.cleaning_services_outlined,
                      color: TailwindColors.zinc200,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Cache Flush',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TailwindColors.zinc100,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Purge package cache and dormant background tasks.',
                          style: TextStyle(
                            fontSize: 12,
                            color: TailwindColors.zinc400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TailwindColors.zinc100,
                      side: const BorderSide(color: TailwindColors.zinc700),
                      backgroundColor: TailwindColors.zinc800.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final bridge = ref.read(optimizationBridgeProvider);
                      final success = await bridge.deepRamClean();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'System caches and memory pages successfully purged.'
                                  : 'Cache cleanup executed with standard privileges.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Flush'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 1: Display & Frame Pipeline ───────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_rounded,
                  size: 16,
                  color: TailwindColors.zinc400,
                ),
                SizedBox(width: 8),
                Text(
                  'DISPLAY & FRAME PIPELINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: TailwindColors.zinc400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TailwindCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _TweakSwitchRow(
                    title: '144Hz FPS Pipeline Bypass',
                    subtitle:
                        'Unlocks display refresh rate by bypassing SurfaceFlinger late latching & compositor rate limits.',
                    shellCommand: 'service call SurfaceFlinger 1034 i32 1 + peak 144Hz',
                    value: tweaks.bypassFpsCap,
                    badgeLabel: '144Hz',
                    badgeVariant: TailwindBadgeVariant.info,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleBypassFpsCap(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Lock 120Hz Refresh Rate',
                    subtitle:
                        'Forces minimum refresh rate to 120Hz to prevent dynamic display downclocking.',
                    shellCommand: 'settings put system min_refresh_rate 120.0',
                    value: tweaks.lock120Hz,
                    badgeLabel: '120Hz',
                    badgeVariant: TailwindBadgeVariant.neutral,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleLock120Hz(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Disable Window Blurs',
                    subtitle:
                        'Reclaims GPU shading bandwidth by disabling live background Gaussian blurs.',
                    shellCommand: 'settings put global disable_window_blurs 1',
                    value: tweaks.disableBlurs,
                    badgeLabel: 'GPU Fillrate',
                    badgeVariant: TailwindBadgeVariant.warning,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleDisableBlurs(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Hardware Composer V-Sync Priority',
                    subtitle:
                        'Enforces hardware V-Sync synchronization for consistent frame pacing.',
                    shellCommand: 'setprop debug.hwc.force_gpu_vsync 1',
                    value: tweaks.gpuVsync,
                    badgeLabel: 'Frame Pacing',
                    badgeVariant: TailwindBadgeVariant.neutral,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleGpuVsync(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Section 2: Processor & Input Controls ─────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.memory_rounded,
                  size: 16,
                  color: TailwindColors.zinc400,
                ),
                SizedBox(width: 8),
                Text(
                  'PROCESSOR, INPUT & NETWORK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: TailwindColors.zinc400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TailwindCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _TweakSwitchRow(
                    title: 'Fixed Performance Governor',
                    subtitle:
                        'Instructs Android Power HAL to sustain peak CPU/GPU clock frequencies.',
                    shellCommand: 'cmd power set-fixed-performance-mode-enabled true',
                    value: tweaks.fixedGovernor,
                    badgeLabel: 'Power HAL',
                    badgeVariant: TailwindBadgeVariant.danger,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleFixedGovernor(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Zero Touch Latency',
                    subtitle:
                        'Sets tap duration and touch blocking threshold to zero for instant input response.',
                    shellCommand: 'settings put secure tap_duration_threshold 0.0',
                    value: tweaks.zeroTouchLatency,
                    badgeLabel: '0.0ms Input',
                    badgeVariant: TailwindBadgeVariant.success,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleTouchLatency(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Network Socket Buffers',
                    subtitle:
                        'Expands TCP read/write buffer sizes to minimize multiplayer packet latency.',
                    shellCommand: 'setprop net.tcp.buffersize.wifi 4096,87380,524288,...',
                    value: tweaks.tcpBuffers,
                    badgeLabel: 'Low Latency',
                    badgeVariant: TailwindBadgeVariant.neutral,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleTcpBuffers(v),
                  ),
                  const Divider(height: 1, color: TailwindColors.zinc800, indent: 16),
                  _TweakSwitchRow(
                    title: 'Gaming Do Not Disturb',
                    subtitle:
                        'Suppresses notification banners, vibration, and call popups during gameplay.',
                    shellCommand: 'settings put global zen_mode 1',
                    value: tweaks.zenDnd,
                    badgeLabel: 'Focus',
                    badgeVariant: TailwindBadgeVariant.neutral,
                    onChanged: (v) => ref
                        .read(hardwareTweaksProvider.notifier)
                        .toggleZenDnd(v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcomponents (Tailwind / Bootstrap Style)
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceStatusCard extends StatelessWidget {
  const _PerformanceStatusCard({required this.tweaks});

  final HardwareTweaksState tweaks;

  @override
  Widget build(BuildContext context) {
    final activeCount = [
      tweaks.fixedGovernor,
      tweaks.zeroTouchLatency,
      tweaks.disableBlurs,
      tweaks.tcpBuffers,
      tweaks.gpuVsync,
      tweaks.lock120Hz,
      tweaks.zenDnd,
      tweaks.bypassFpsCap,
    ].where((e) => e).length;

    final isPerformanceMode = activeCount >= 5;

    return TailwindCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TailwindBadge(
                label: isPerformanceMode ? 'PERFORMANCE ACTIVE' : 'STANDARD PROFILE',
                variant: isPerformanceMode
                    ? TailwindBadgeVariant.info
                    : TailwindBadgeVariant.success,
                showDot: true,
              ),
              const Spacer(),
              Text(
                '$activeCount of 8 active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TailwindColors.zinc400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isPerformanceMode
                ? 'High-Performance Governor'
                : 'Adaptive Hardware Tuning',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: TailwindColors.zinc100,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPerformanceMode
                ? 'CPU/GPU clocks locked at peak frequencies. Frame pipeline throttles bypassed.'
                : 'Balanced operating parameters active. Tap a profile preset or customize options below.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: TailwindColors.zinc400,
            ),
          ),
          const SizedBox(height: 16),
          // Clean Stat Metric Row (Bootstrap Card / Tailwind Stat Row)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: TailwindColors.zinc950,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TailwindColors.zinc800, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISPLAY PIPELINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: TailwindColors.zinc500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tweaks.bypassFpsCap ? '144Hz Direct' : (tweaks.lock120Hz ? '120Hz Locked' : 'Dynamic 60-120'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tweaks.bypassFpsCap ? TailwindColors.emerald400 : TailwindColors.zinc200,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: TailwindColors.zinc800,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOUCH RESPONSE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: TailwindColors.zinc500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tweaks.zeroTouchLatency ? '0.0ms Immediate' : 'System Default',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tweaks.zeroTouchLatency ? TailwindColors.blue400 : TailwindColors.zinc200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuningProfileCard extends StatelessWidget {
  const _TuningProfileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withOpacity(0.1)
              : TailwindColors.zinc900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? accentColor : TailwindColors.zinc800,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? accentColor : TailwindColors.zinc400,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isActive ? TailwindColors.zinc100 : TailwindColors.zinc300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isActive ? accentColor : TailwindColors.zinc500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TweakSwitchRow extends StatelessWidget {
  const _TweakSwitchRow({
    required this.title,
    required this.subtitle,
    required this.shellCommand,
    required this.value,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String shellCommand;
  final bool value;
  final String badgeLabel;
  final TailwindBadgeVariant badgeVariant;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: TailwindColors.zinc100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TailwindBadge(
                      label: badgeLabel,
                      variant: badgeVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: TailwindColors.zinc400,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: TailwindColors.zinc950,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: TailwindColors.zinc800, width: 1),
                  ),
                  child: Text(
                    shellCommand,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: TailwindColors.zinc500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Switch(
            value: value,
            activeColor: TailwindColors.emerald500,
            activeTrackColor: TailwindColors.emerald950,
            inactiveThumbColor: TailwindColors.zinc400,
            inactiveTrackColor: TailwindColors.zinc800,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
