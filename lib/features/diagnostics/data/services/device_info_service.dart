import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/utils/logger.dart';
import '../models/device_info_model.dart';

/// Platform channel client that talks to the native Kotlin engine in
/// [MainActivity]. All calls are fire-and-forget best-effort; failures
/// fall back to [FullDeviceInfo.unavailable] so the UI always renders.
class DeviceInfoService {
  static const _channel = MethodChannel('com.mohalab.optimization/device_info');

  static bool get _isTesting => WidgetsBinding.instance is! WidgetsFlutterBinding;

  /// Fetch all hardware telemetry in a single round-trip.
  static Future<FullDeviceInfo> fetchAll() async {
    if (_isTesting) return FullDeviceInfo.unavailable;
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('getAllDeviceInfo')
          .timeout(const Duration(seconds: 3));
      if (raw == null) return FullDeviceInfo.unavailable;
      return FullDeviceInfo.fromMap(Map<String, dynamic>.from(raw));
    } on PlatformException catch (e) {
      AppLogger.warning('PlatformException: ${e.message}', tag: 'DeviceInfoService');
      return FullDeviceInfo.unavailable;
    } on MissingPluginException {
      // Running on web or non-Android target.
      return FullDeviceInfo.unavailable;
    } catch (e) {
      AppLogger.error('Unexpected error: $e', tag: 'DeviceInfoService');
      return FullDeviceInfo.unavailable;
    }
  }

  /// Live battery polling -- call periodically to refresh battery state.
  static Future<BatteryInfo> fetchBattery() async {
    if (_isTesting) return BatteryInfo.unavailable;
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('getBatteryInfo')
          .timeout(const Duration(seconds: 2));
      if (raw == null) return BatteryInfo.unavailable;
      return BatteryInfo.fromMap(Map<String, dynamic>.from(raw));
    } on PlatformException {
      return BatteryInfo.unavailable;
    } on MissingPluginException {
      return BatteryInfo.unavailable;
    } catch (_) {
      return BatteryInfo.unavailable;
    }
  }

  /// Live memory polling -- call periodically to refresh RAM state.
  static Future<MemoryInfo> fetchMemory() async {
    if (_isTesting) return MemoryInfo.unavailable;
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('getMemoryInfo')
          .timeout(const Duration(seconds: 2));
      if (raw == null) return MemoryInfo.unavailable;
      return MemoryInfo.fromMap(Map<String, dynamic>.from(raw));
    } on PlatformException {
      return MemoryInfo.unavailable;
    } on MissingPluginException {
      return MemoryInfo.unavailable;
    } catch (_) {
      return MemoryInfo.unavailable;
    }
  }

  /// Current vs. max clock of every core that exposes cpufreq. Returns an
  /// empty snapshot when the kernel hides it.
  static Future<CpuClockSnapshot> fetchCpuClocks() async {
    if (_isTesting) return const CpuClockSnapshot([]);
    try {
      final raw = await _channel
          .invokeListMethod<dynamic>('getCpuFreqs')
          .timeout(const Duration(seconds: 2));
      return CpuClockSnapshot([
        for (final m in raw ?? const [])
          if (m is Map && m['curKhz'] is num)
            CoreClock(
              curKhz: (m['curKhz'] as num).toInt(),
              maxKhz: (m['maxKhz'] as num?)?.toInt(),
            ),
      ]);
    } catch (_) {
      return const CpuClockSnapshot([]);
    }
  }

  /// PowerManager thermal status (API 29+) and headroom forecast (API 30+).
  static Future<ThermalSnapshot> fetchThermal() async {
    if (_isTesting) return const ThermalSnapshot();
    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('getThermal')
          .timeout(const Duration(seconds: 2));
      return ThermalSnapshot(
        status: raw?['status'] as int?,
        headroom: (raw?['headroom'] as num?)?.toDouble(),
      );
    } catch (_) {
      return const ThermalSnapshot();
    }
  }
}

class CoreClock {
  const CoreClock({required this.curKhz, this.maxKhz});

  final int curKhz;
  final int? maxKhz;

  double? get load => (maxKhz == null || maxKhz == 0) ? null : (curKhz / maxKhz!).clamp(0.0, 1.0);
}

class CpuClockSnapshot {
  const CpuClockSnapshot(this.cores);

  final List<CoreClock> cores;

  bool get isAvailable => cores.isNotEmpty;

  /// Average current/max clock ratio across cores (0–1).
  double? get averageLoad {
    final loads = cores.map((c) => c.load).whereType<double>().toList();
    if (loads.isEmpty) return null;
    return loads.reduce((a, b) => a + b) / loads.length;
  }

  int get peakMhz =>
      cores.isEmpty ? 0 : cores.map((c) => c.curKhz).reduce((a, b) => a > b ? a : b) ~/ 1000;
}

class ThermalSnapshot {
  const ThermalSnapshot({this.status, this.headroom});

  /// PowerManager.THERMAL_STATUS_* (0 none … 6 shutdown).
  final int? status;

  /// Forecast fraction of the throttling threshold in 10 s (1.0 = throttling).
  final double? headroom;

  String? get statusLabel => switch (status) {
        0 => 'None',
        1 => 'Light',
        2 => 'Moderate',
        3 => 'Severe',
        4 => 'Critical',
        5 => 'Emergency',
        6 => 'Shutdown',
        _ => null,
      };
}
