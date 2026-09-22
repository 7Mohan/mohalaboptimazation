import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/feedback/moha_error_state.dart';
import '../../../../shared/widgets/feedback/moha_loading_state.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/device_info_model.dart';
import '../../data/providers/full_device_info_provider.dart';

// -----------------------------------------------------------------------------
// Screen
// -----------------------------------------------------------------------------

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(fullDeviceInfoProvider);
    final batteryAsync = ref.watch(liveBatteryProvider);
    final memoryAsync = ref.watch(liveMemoryProvider);

    return Scaffold(
      appBar: MohaAppBar(
        title: 'Diagnostics',
        subtitle: 'Real-time hardware telemetry',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(fullDeviceInfoProvider);
              ref.read(liveBatteryProvider.notifier).refresh();
              ref.read(liveMemoryProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: deviceAsync.when(
        loading: () => const MohaLoadingState(message: 'Reading hardware telemetry…'),
        error: (e, _) => MohaErrorState(
          title: 'Hardware Telemetry Unavailable',
          message: 'Could not read device information. Ensure the app has the required permissions and retry.',
          onRetry: () => ref.invalidate(fullDeviceInfoProvider),
        ),
        data: (info) => _DeviceDashboard(
          info: info,
          batteryAsync: batteryAsync,
          memoryAsync: memoryAsync,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Main dashboard
// -----------------------------------------------------------------------------

class _DeviceDashboard extends StatelessWidget {
  const _DeviceDashboard({
    required this.info,
    required this.batteryAsync,
    required this.memoryAsync,
  });

  final FullDeviceInfo info;
  final AsyncValue<BatteryInfo> batteryAsync;
  final AsyncValue<MemoryInfo> memoryAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        // -- Device Identity ----------------------------------------------
        const SectionHeader(
          title: 'Device Identity',
          subtitle: 'Hardware and software identification.',
          icon: Icons.smartphone_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: InfoCard(
            title: 'DEVICE',
            children: [
              InfoRow(label: 'Manufacturer', value: info.identity.manufacturer),
              InfoRow(label: 'Brand', value: info.identity.brand),
              InfoRow(label: 'Model', value: info.identity.model),
              InfoRow(label: 'Device', value: info.identity.device),
              InfoRow(label: 'Android', value: 'Android ${info.identity.androidVersion}'),
              InfoRow(
                label: 'SDK Level',
                value: info.identity.sdkInt?.toString() ?? 'Unavailable',
              ),
              InfoRow(label: 'Build ID', value: info.identity.buildId),
              InfoRow(label: 'Build Type', value: info.identity.buildType),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Advanced Diagnostics ----------------------------------------
        const SectionHeader(
          title: 'Advanced Diagnostics',
          subtitle: 'CPU architecture and core information.',
          icon: Icons.memory_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: InfoCard(
            title: 'CPU',
            children: [
              InfoRow(label: 'Hardware', value: info.cpu.hardware),
              if (info.cpu.model != null)
                InfoRow(label: 'Processor', value: info.cpu.model!),
              InfoRow(label: 'Cores', value: info.cpu.numCores?.toString() ?? 'Unavailable'),
              InfoRow(label: 'Architecture', value: info.cpu.primaryAbi),
              InfoRow(label: 'Supported ABIs', value: info.cpu.abis.join(', ')),
            ],
          ),
        ),
        if (info.cpu.coreFrequencies.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: AppSpacing.screenPadding,
            child: _CpuCoresCard(cores: info.cpu.coreFrequencies),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // -- Memory ------------------------------------------------------
        const SectionHeader(
          title: 'Memory',
          subtitle: 'RAM usage refreshed every 15 s.',
          icon: Icons.storage_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: memoryAsync.when(
            loading: () => const InfoCard(
              title: 'RAM',
              children: [InfoRow(label: 'Loading…', value: '')],
            ),
            error: (e, _) => InfoCard(
              title: 'RAM',
              children: [InfoRow(label: 'Error', value: e.toString())],
            ),
            data: (mem) => _MemoryCard(memory: mem),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Storage -----------------------------------------------------
        const SectionHeader(
          title: 'Storage',
          subtitle: 'Internal and external storage capacity.',
          icon: Icons.folder_open_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: _StorageCard(storage: info.storage),
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Battery -----------------------------------------------------
        const SectionHeader(
          title: 'Battery',
          subtitle: 'Power state refreshed every 30 s.',
          icon: Icons.battery_charging_full_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: batteryAsync.when(
            loading: () => const InfoCard(
              title: 'BATTERY',
              children: [InfoRow(label: 'Loading…', value: '')],
            ),
            error: (e, _) => InfoCard(
              title: 'BATTERY',
              children: [InfoRow(label: 'Error', value: e.toString())],
            ),
            data: (bat) => _BatteryCard(battery: bat),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Display -----------------------------------------------------
        const SectionHeader(
          title: 'Display',
          subtitle: 'Screen hardware characteristics.',
          icon: Icons.monitor_rounded,
        ),
        Padding(
          padding: AppSpacing.screenPadding,
          child: _DisplayCard(display: info.display),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Specialised cards
// -----------------------------------------------------------------------------

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});
  final MemoryInfo memory;

  @override
  Widget build(BuildContext context) {
    final total = memory.totalRamGb;
    final avail = memory.availableRamGb;
    final used = memory.usedRamGb;
    final pct = memory.usedPercent;
    final low = memory.lowMemory ?? false;

    return InfoCard(
      title: 'RAM',
      trailing: MohaStatusBadge(
        customLabel: low ? 'Low Memory' : 'Normal',
        type: low ? MohaStatusType.warning : MohaStatusType.optimal,
      ),
      children: [
        InfoRow(
          label: 'Total RAM',
          value: total != null ? '${total.toStringAsFixed(1)} GB' : 'Unavailable',
        ),
        InfoRow(
          label: 'Used RAM',
          value: used != null
              ? '${used.toStringAsFixed(1)} GB${pct != null ? ' ($pct%)' : ''}'
              : 'Unavailable',
        ),
        InfoRow(
          label: 'Available RAM',
          value: avail != null ? '${avail.toStringAsFixed(1)} GB' : 'Unavailable',
        ),
        if (pct != null) _UsageBar(percent: pct / 100, isWarning: low),
      ],
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.storage});
  final StorageInfo storage;

  @override
  Widget build(BuildContext context) {
    final total = storage.internalTotalGb;
    final avail = storage.internalAvailableGb;
    final usedPct = storage.internalUsedPercent;

    return InfoCard(
      title: 'STORAGE',
      children: [
        InfoRow(
          label: 'Internal Total',
          value: total != null ? '${total.toStringAsFixed(1)} GB' : 'Unavailable',
        ),
        InfoRow(
          label: 'Internal Free',
          value: avail != null
              ? '${avail.toStringAsFixed(1)} GB${usedPct != null ? ' (${100 - usedPct}% free)' : ''}'
              : 'Unavailable',
        ),
        if (usedPct != null)
          _UsageBar(percent: usedPct / 100, isWarning: usedPct > 85),
        if (storage.externalTotalBytes != null)
          InfoRow(
            label: 'SD Card Total',
            value: storage.externalTotalBytes != null
                ? '${(storage.externalTotalBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                : 'None',
          ),
        if (storage.externalAvailableBytes != null)
          InfoRow(
            label: 'SD Card Free',
            value: '${(storage.externalAvailableBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
          ),
      ],
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.battery});
  final BatteryInfo battery;

  @override
  Widget build(BuildContext context) {
    final pct = battery.percentage;
    final statusType = pct != null && pct < 20
        ? MohaStatusType.warning
        : battery.isCharging
            ? MohaStatusType.safe
            : MohaStatusType.optimal;

    return InfoCard(
      title: 'BATTERY',
      trailing: MohaStatusBadge(
        customLabel: battery.status, type: statusType),
      children: [
        InfoRow(
          label: 'Level',
          value: pct != null ? '$pct%' : 'Unavailable',
        ),
        if (pct != null) _UsageBar(percent: pct / 100, isWarning: pct < 20, invert: true),
        InfoRow(label: 'Health', value: battery.health),
        InfoRow(label: 'Technology', value: battery.technology),
        InfoRow(
          label: 'Temperature',
          value: battery.temperatureC != null
              ? '${battery.temperatureC!.toStringAsFixed(1)} °C'
              : 'Unavailable',
        ),
        InfoRow(
          label: 'Voltage',
          value: battery.voltageMv != null ? '${battery.voltageMv} mV' : 'Unavailable',
        ),
        if (battery.plugged != null)
          InfoRow(label: 'Charging via', value: battery.plugged!),
      ],
    );
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.display});
  final DisplayInfo display;

  @override
  Widget build(BuildContext context) {
    final rates = display.supportedRatesHz
        .map((r) => '${r.toStringAsFixed(0)} Hz')
        .join(' / ');

    return InfoCard(
      title: 'DISPLAY',
      children: [
        InfoRow(label: 'Resolution', value: display.resolution),
        InfoRow(
          label: 'Density',
          value: display.densityDpi != null ? '${display.densityDpi} dpi' : 'Unavailable',
        ),
        InfoRow(
          label: 'Refresh Rate',
          value: display.refreshRateHz != null
              ? '${display.refreshRateHz!.toStringAsFixed(1)} Hz'
              : 'Unavailable',
        ),
        if (rates.isNotEmpty)
          InfoRow(label: 'Supported Rates', value: rates),
      ],
    );
  }
}

class _CpuCoresCard extends StatelessWidget {
  const _CpuCoresCard({required this.cores});
  final List<CoreFrequency> cores;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'CORE FREQUENCIES',
      children: cores
          .map(
            (c) => InfoRow(
              label: 'Core ${c.core}',
              value: c.currentGhz != null
                  ? '${c.currentGhz!.toStringAsFixed(2)} GHz'
                      '${c.maxGhz != null ? ' / max ${c.maxGhz!.toStringAsFixed(2)} GHz' : ''}'
                  : 'Unavailable',
            ),
          )
          .toList(),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared usage bar widget
// -----------------------------------------------------------------------------

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.percent,
    this.isWarning = false,
    this.invert = false,
  });

  /// 0.0 – 1.0
  final double percent;
  final bool isWarning;

  /// When true, full = good (battery). When false, full = bad (RAM/storage).
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // For battery (invert=true): high % = good (secondary/green tint).
    // For RAM/storage (invert=false): high % = bad (stays primary, turns error via isWarning).
    final barColor = isWarning
        ? theme.colorScheme.error
        : invert
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusSm,
        child: LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ),
    );
  }
}

