import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/utils/logger.dart';
import '../models/device_info_model.dart';

/// Platform channel client that talks to the native Kotlin engine in
/// [MainActivity]. All calls are fire-and-forget best-effort; failures
/// fall back to [FullDeviceInfo.unavailable] so the UI always renders.
class DeviceInfoService {
  static const _channel = MethodChannel('com.mohalab.optimization/device_info');

  static bool get _isTesting =>
      WidgetsBinding.instance is! WidgetsFlutterBinding;

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
}
