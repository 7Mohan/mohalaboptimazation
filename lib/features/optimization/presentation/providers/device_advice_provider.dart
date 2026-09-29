import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../diagnostics/data/services/device_info_service.dart';
import '../../../network/data/datasources/native_network_probe.dart';
import '../../../network/domain/entities/network_connection_type.dart';
import '../../domain/device_advisor.dart';
import 'tweak_providers.dart';

Future<NetworkConnectionType> _connection() async {
  try {
    return await const NativeNetworkProbe().getConnectionType();
  } catch (_) {
    return NetworkConnectionType.unknown;
  }
}

/// Reads fresh device signals and runs [DeviceAdvisor]. Invalidate to re-scan.
final deviceAdviceProvider = FutureProvider.autoDispose<DeviceAdvice>((ref) async {
  final caps = (await ref.watch(tweaksControllerProvider.future)).capabilities;
  final info = await ref.watch(fullDeviceInfoProvider.future);
  final (memory, battery, thermal, network) = await (
    DeviceInfoService.fetchMemory(),
    DeviceInfoService.fetchBattery(),
    DeviceInfoService.fetchThermal(),
    _connection(),
  ).wait;

  final maxKhz = info.cpu.coreFrequencies
      .map((c) => c.maxKhz)
      .whereType<int>()
      .fold<int>(0, (a, b) => b > a ? b : a);
  final storageUsed = info.storage.internalUsedPercent;
  final ramUsed = memory.usedPercent ?? info.memory.usedPercent;
  final bat = battery.percentage != null ? battery : info.battery;

  return DeviceAdvisor.analyze(
    DeviceSignals(
      sdkInt: caps.sdkInt != 0 ? caps.sdkInt : (info.identity.sdkInt ?? 0),
      ramGb: memory.totalRamGb ?? info.memory.totalRamGb,
      availableRamPercent: ramUsed == null ? null : 100 - ramUsed,
      cpuCores: info.cpu.numCores,
      maxCpuGhz: maxKhz > 0 ? maxKhz / 1e6 : null,
      maxRefreshHz: caps.maxRefreshRate,
      batteryPercent: bat.percentage,
      charging: bat.isCharging,
      batteryTempC: bat.temperatureC,
      thermalStatus: thermal.status,
      thermalHeadroom: thermal.headroom,
      storageFreePercent: storageUsed == null ? null : 100 - storageUsed,
      onWifi: network == NetworkConnectionType.wifi,
      rooted: caps.hasRoot,
    ),
  );
});

/// Short spec line for the analysis card, e.g. "8 GB · 8 cores · 120 Hz".
String signalsSummary(DeviceSignals s) => [
      if (s.ramGb != null) '${s.ramGb!.round()} GB RAM',
      if (s.cpuCores != null) '${s.cpuCores} cores',
      if (s.maxCpuGhz != null) '${s.maxCpuGhz!.toStringAsFixed(1)} GHz',
      '${s.maxRefreshHz.round()} Hz',
      if (s.batteryTempC != null) '${s.batteryTempC!.toStringAsFixed(0)}°C',
      s.onWifi ? 'Wi-Fi' : 'Mobile data',
    ].join(' · ');
