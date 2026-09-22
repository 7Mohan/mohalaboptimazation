import '../../domain/entities/optimization_capability.dart';
import '../../domain/services/optimization_handler.dart';
import '../services/optimization_native_bridge.dart';

/// Handler for RAM cache trimming via ActivityManager.trimMemory.
class RamTrimOptimizationHandler implements OptimizationHandler {
  const RamTrimOptimizationHandler(this.bridge);
  final OptimizationNativeBridge bridge;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.standardAndroid;
  }

  @override
  Future<bool> checkPermission(String? permission) async => true;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final success = await bridge.trimMemory();
    return {'trimmed': success, 'timestamp': DateTime.now().toIso8601String()};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async => false;
}

/// Handler for tuning window, transition, and animator scales.
class WindowAnimationScaleHandler implements OptimizationHandler {
  WindowAnimationScaleHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.systemSettingsWrite ||
        capability == OptimizationCapability.shizukuPrivileged;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async {
    final scales = await bridge.getAnimationScales();
    return Map<String, dynamic>.from(scales);
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final scale = (parameters['scale'] as num?)?.toDouble() ?? 0.5;
    final success = await bridge.setAnimationScales(scale);
    return {'appliedScale': scale, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async {
    final scale = (parameters['scale'] as num?)?.toDouble() ?? 0.5;
    final current = await bridge.getAnimationScales();
    return (current['window'] as num?)?.toDouble() == scale;
  }

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    final target = (snapshot['window'] as num?)?.toDouble() ?? 1.0;
    return bridge.setAnimationScales(target);
  }
}

/// Handler for Gaming Do Not Disturb ZenMode suppression.
class GamingDndHandler implements OptimizationHandler {
  GamingDndHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.notificationPolicy;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async {
    final filter = await bridge.getDndInterruptionFilter();
    return {'filter': filter};
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    // 2 = INTERRUPTION_FILTER_PRIORITY
    final success = await bridge.setDndInterruptionFilter(2);
    return {'appliedFilter': 2, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async {
    final current = await bridge.getDndInterruptionFilter();
    return current == 2;
  }

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    final originalFilter = (snapshot['filter'] as int?) ?? 1;
    return bridge.setDndInterruptionFilter(originalFilter);
  }
}

/// Handler for locking minimum refresh rate to peak rate.
class PeakRefreshRateHandler implements OptimizationHandler {
  PeakRefreshRateHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.systemSettingsWrite ||
        capability == OptimizationCapability.shizukuPrivileged;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async {
    final rates = await bridge.getRefreshRates();
    return Map<String, dynamic>.from(rates);
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final rates = await bridge.getRefreshRates();
    final peak = (parameters['targetRefreshRate'] as num?)?.toDouble() ??
        (rates['peak'] as num?)?.toDouble() ??
        120.0;
    final success = await bridge.setMinRefreshRate(peak);
    return {'lockedRate': peak, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async {
    final rates = await bridge.getRefreshRates();
    final target = (parameters['targetRefreshRate'] as num?)?.toDouble() ??
        (rates['peak'] as num?)?.toDouble() ??
        120.0;
    return (rates['min'] as num?)?.toDouble() == target;
  }

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    final originalMin = (snapshot['min'] as num?)?.toDouble() ?? 60.0;
    return bridge.setMinRefreshRate(originalMin);
  }
}

/// Handler for fixed performance mode (CPU/GPU governor lock).
class FixedPerformanceHandler implements OptimizationHandler {
  FixedPerformanceHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.standardAndroid;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'enabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final enabled = parameters['enabled'] as bool? ?? true;
    final success = await bridge.setFixedPerformanceMode(enabled);
    return {'enabled': enabled, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    return bridge.setFixedPerformanceMode(false);
  }
}

/// Handler for ultra-low touch latency tuning.
class TouchLatencyHandler implements OptimizationHandler {
  TouchLatencyHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.systemSettingsWrite;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'enabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final enabled = parameters['enabled'] as bool? ?? true;
    final success = await bridge.setTouchLatency(enabled);
    return {'enabled': enabled, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    return bridge.setTouchLatency(false);
  }
}

/// Handler for disabling system Gaussian window blurs.
class DisableBlursHandler implements OptimizationHandler {
  DisableBlursHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.systemSettingsWrite;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'disabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final disabled = parameters['disabled'] as bool? ?? true;
    final success = await bridge.setBlurDisabled(disabled);
    return {'disabled': disabled, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    return bridge.setBlurDisabled(false);
  }
}

/// Handler for gaming TCP network buffers.
class TcpBufferHandler implements OptimizationHandler {
  TcpBufferHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.standardAndroid;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'enabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final enabled = parameters['enabled'] as bool? ?? true;
    final success = await bridge.optimizeNetworkBuffers(enabled);
    return {'enabled': enabled, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async => true;
}

/// Handler for GPU vsync and rendering boost.
class GpuVsyncHandler implements OptimizationHandler {
  GpuVsyncHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.standardAndroid;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'enabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final enabled = parameters['enabled'] as bool? ?? true;
    final success = await bridge.setGpuRenderingProfile(enabled);
    return {'enabled': enabled, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    return bridge.setGpuRenderingProfile(false);
  }
}

/// Handler for deep RAM cache purge and process reclamation.
class DeepRamCleanHandler implements OptimizationHandler {
  const DeepRamCleanHandler(this.bridge);
  final OptimizationNativeBridge bridge;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.standardAndroid ||
        capability == OptimizationCapability.shizukuPrivileged;
  }

  @override
  Future<bool> checkPermission(String? permission) async => true;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final success = await bridge.deepRamClean();
    return {'cleaned': success, 'timestamp': DateTime.now().toIso8601String()};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async => false;
}

/// Handler for bypassing game 60/120 FPS limits and unlocking 144Hz pipeline.
class BypassFpsPipelineHandler implements OptimizationHandler {
  BypassFpsPipelineHandler(this.bridge, {this.permissionGranted = true});
  final OptimizationNativeBridge bridge;
  bool permissionGranted;

  @override
  Future<bool> checkCapability(OptimizationCapability capability) async {
    return capability == OptimizationCapability.shizukuPrivileged ||
        capability == OptimizationCapability.systemSettingsWrite;
  }

  @override
  Future<bool> checkPermission(String? permission) async => permissionGranted;

  @override
  Future<Map<String, dynamic>> capturePreState() async => {'enabled': false};

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters) async {
    final enabled = parameters['enabled'] as bool? ?? true;
    final targetHz = (parameters['targetHz'] as num?)?.toDouble() ?? 144.0;
    final success = await bridge.bypassRenderPipelineFpsCap(
      enabled: enabled,
      targetHz: targetHz,
    );
    return {'enabled': enabled, 'targetHz': targetHz, 'success': success};
  }

  @override
  Future<bool> verify(Map<String, dynamic> parameters) async => true;

  @override
  Future<bool> rollback(Map<String, dynamic> snapshot) async {
    return bridge.bypassRenderPipelineFpsCap(enabled: false);
  }
}
