import 'package:flutter/services.dart';

/// MethodChannel communication bridge for executing safe native Android optimizations.
class OptimizationNativeBridge {
  const OptimizationNativeBridge([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('com.mohalab.optimization/optimizations');

  final MethodChannel _channel;

  /// Trims memory caches via ActivityManager.trimMemory.
  Future<bool> trimMemory() async {
    try {
      final res = await _channel.invokeMethod<bool>('trimMemory');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Gets current window, transition, and animator duration animation scales.
  Future<Map<String, dynamic>> getAnimationScales() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getAnimationScales');
      return res ?? {'window': 1.0, 'transition': 1.0, 'animator': 1.0};
    } catch (_) {
      return {'window': 1.0, 'transition': 1.0, 'animator': 1.0};
    }
  }

  /// Sets window, transition, and animator duration scales.
  Future<bool> setAnimationScales(double scale) async {
    try {
      final res = await _channel.invokeMethod<bool>('setAnimationScales', {'scale': scale});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Gets current NotificationManager interruption filter.
  Future<int> getDndInterruptionFilter() async {
    try {
      final res = await _channel.invokeMethod<int>('getDndInterruptionFilter');
      return res ?? 1; // INTERRUPTION_FILTER_ALL
    } catch (_) {
      return 1;
    }
  }

  /// Sets NotificationManager interruption filter (e.g., 2 for PRIORITY_ONLY).
  Future<bool> setDndInterruptionFilter(int filter) async {
    try {
      final res = await _channel.invokeMethod<bool>('setDndInterruptionFilter', {'filter': filter});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Gets current min and peak display refresh rates.
  Future<Map<String, dynamic>> getRefreshRates() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getRefreshRates');
      return res ?? {'min': 60.0, 'peak': 60.0};
    } catch (_) {
      return {'min': 60.0, 'peak': 60.0};
    }
  }

  /// Sets minimum display refresh rate.
  Future<bool> setMinRefreshRate(double rate) async {
    try {
      final res = await _channel.invokeMethod<bool>('setMinRefreshRate', {'rate': rate});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Trims system-wide and app caches using privileged pm trim-caches or internal cache flush.
  Future<bool> cleanSystemCache() async {
    try {
      final res = await _channel.invokeMethod<bool>('cleanSystemCache');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enables or disables fixed Android performance mode for gaming.
  Future<bool> setPerformanceMode(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setPerformanceMode', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enables or disables fixed CPU/GPU performance governor.
  Future<bool> setFixedPerformanceMode(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setFixedPerformanceMode', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets Android Game Mode for specific package (performance, battery, standard).
  Future<bool> setAppGameMode(String packageName, String mode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setAppGameMode', {
        'packageName': packageName,
        'mode': mode,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Scales rendering resolution down for heavy 3D titles (e.g. 0.75).
  Future<bool> setAppDownscale(String packageName, double scale) async {
    try {
      final res = await _channel.invokeMethod<bool>('setAppDownscale', {
        'packageName': packageName,
        'scale': scale,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Toggles ultra low touch latency mode.
  Future<bool> setTouchLatency(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setTouchLatency', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Disables system window blurs for lower GPU composition overhead.
  Future<bool> setBlurDisabled(bool disabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setBlurDisabled', {'disabled': disabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Optimizes Wi-Fi/LTE TCP buffers for ultra low packet jitter.
  Future<bool> optimizeNetworkBuffers(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('optimizeNetworkBuffers', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prioritizes hardware GPU vsync composition.
  Future<bool> setGpuRenderingProfile(bool enabled) async {
    try {
      final res = await _channel.invokeMethod<bool>('setGpuRenderingProfile', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Deep cleans RAM and system caches.
  Future<bool> deepRamClean() async {
    try {
      final res = await _channel.invokeMethod<bool>('deepRamClean');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Bypasses 60/120 FPS game cap by overriding SurfaceFlinger backpressure,
  /// disabling DisplayManager downclocking, and locking refresh to 144Hz/peak.
  Future<bool> bypassRenderPipelineFpsCap({
    required bool enabled,
    double? targetHz,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('bypassRenderPipelineFpsCap', {
        'enabled': enabled,
        if (targetHz != null) 'targetHz': targetHz,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
