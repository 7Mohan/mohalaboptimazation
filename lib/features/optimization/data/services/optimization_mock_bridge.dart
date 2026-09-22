import 'optimization_native_bridge.dart';

/// In-memory mock bridge for unit tests and non-Android environments.
class OptimizationMockBridge implements OptimizationNativeBridge {
  bool trimMemoryResult = true;

  Map<String, dynamic> animationScales = {
    'window': 1.0,
    'transition': 1.0,
    'animator': 1.0,
  };
  bool setAnimationScalesSuccess = true;

  int dndFilter = 1; // 1 = INTERRUPTION_FILTER_ALL
  bool setDndSuccess = true;

  Map<String, dynamic> refreshRates = {
    'min': 60.0,
    'peak': 120.0,
  };
  bool setMinRefreshRateSuccess = true;

  @override
  Future<bool> trimMemory() async => trimMemoryResult;

  @override
  Future<Map<String, dynamic>> getAnimationScales() async => Map.from(animationScales);

  @override
  Future<bool> setAnimationScales(double scale) async {
    if (!setAnimationScalesSuccess) return false;
    animationScales = {
      'window': scale,
      'transition': scale,
      'animator': scale,
    };
    return true;
  }

  @override
  Future<int> getDndInterruptionFilter() async => dndFilter;

  @override
  Future<bool> setDndInterruptionFilter(int filter) async {
    if (!setDndSuccess) return false;
    dndFilter = filter;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getRefreshRates() async => Map.from(refreshRates);

  @override
  Future<bool> setMinRefreshRate(double rate) async {
    if (!setMinRefreshRateSuccess) return false;
    refreshRates['min'] = rate;
    return true;
  }

  bool cleanSystemCacheResult = true;
  @override
  Future<bool> cleanSystemCache() async => cleanSystemCacheResult;

  bool performanceModeEnabled = false;
  bool setPerformanceModeSuccess = true;
  @override
  Future<bool> setPerformanceMode(bool enabled) async {
    if (!setPerformanceModeSuccess) return false;
    performanceModeEnabled = enabled;
    return true;
  }

  @override
  Future<bool> setFixedPerformanceMode(bool enabled) async => true;

  @override
  Future<bool> setAppGameMode(String packageName, String mode) async => true;

  @override
  Future<bool> setAppDownscale(String packageName, double scale) async => true;

  @override
  Future<bool> setTouchLatency(bool enabled) async => true;

  @override
  Future<bool> setBlurDisabled(bool disabled) async => true;

  @override
  Future<bool> optimizeNetworkBuffers(bool enabled) async => true;

  @override
  Future<bool> setGpuRenderingProfile(bool enabled) async => true;

  @override
  Future<bool> deepRamClean() async => true;

  @override
  Future<bool> bypassRenderPipelineFpsCap({
    required bool enabled,
    double? targetHz,
  }) async => true;
}
