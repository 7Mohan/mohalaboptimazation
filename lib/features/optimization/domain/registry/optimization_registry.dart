import '../../../games/domain/entities/game_profile_entity.dart';
import '../entities/optimization_capability.dart';
import '../entities/optimization_definition.dart';
import '../services/optimization_handler.dart';
import '../services/optimization_validator.dart';

/// Central registry for all vetted, safe optimizations and their handlers.
///
/// Ensures no prohibited or unvetted optimizations can ever be registered.
class OptimizationRegistry {
  OptimizationRegistry({
    OptimizationValidator? validator,
  }) : _validator = validator ?? const OptimizationValidator() {
    _registerBuiltinOptimizations();
  }

  final OptimizationValidator _validator;
  final Map<String, OptimizationDefinition> _definitions = {};
  final Map<String, OptimizationHandler> _handlers = {};

  /// Predefined safe optimizations adhering strictly to legitimate Android mechanisms.
  static const OptimizationDefinition ramTrimCaches = OptimizationDefinition(
    id: 'ram_trim_caches',
    name: 'Trim Background Application Caches',
    description: 'Signals the Android system to reclaim unneeded memory caches from background processes.',
    category: OptimizationCategory.performance,
    requiredCapability: OptimizationCapability.standardAndroid,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 26,
    isReversible: false,
    verificationMethod: VerificationMethod.memoryStateVerification,
    whatWillChange: 'Releases cached background buffers via ActivityManager.trimMemory.',
    whyItHelps: 'May reduce background memory contention before launching games.',
    whatRiskExists: 'Background applications may take slightly longer to reload when reopened.',
  );

  static const OptimizationDefinition windowAnimationScale = OptimizationDefinition(
    id: 'window_animation_scale',
    name: 'Window Animation Scale Tuner',
    description: 'Reduces system animation scales for snappier window transitions and lower transition latency.',
    category: OptimizationCategory.display,
    requiredCapability: OptimizationCapability.systemSettingsWrite,
    riskLevel: OptimizationRiskLevel.low,
    minAndroidSdk: 26,
    isReversible: true,
    requiredPermission: 'android.permission.WRITE_SECURE_SETTINGS',
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Sets window_animation_scale, transition_animation_scale, and animator_duration_scale.',
    whyItHelps: 'May reduce perceived transition delay when switching apps or games.',
    whatRiskExists: 'System animations will appear accelerated until restored.',
    defaultParameters: {'scale': 0.5},
  );

  static const OptimizationDefinition gamingDndZen = OptimizationDefinition(
    id: 'gaming_dnd_zen',
    name: 'Gaming Do Not Disturb',
    description: 'Suppresses notification banners, heads-up popups, and vibration alerts during gameplay.',
    category: OptimizationCategory.battery,
    requiredCapability: OptimizationCapability.notificationPolicy,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 26,
    isReversible: true,
    requiredPermission: 'android.permission.ACCESS_NOTIFICATION_POLICY',
    verificationMethod: VerificationMethod.notificationPolicyVerification,
    whatWillChange: 'Configures NotificationManager interruption filter to priority only.',
    whyItHelps: 'May prevent sudden notification stutters and visual obstruction during gameplay.',
    whatRiskExists: 'Calls and notifications from non-whitelisted senders will be silenced until restored.',
  );

  static const OptimizationDefinition peakRefreshRate = OptimizationDefinition(
    id: 'peak_refresh_rate',
    name: 'Lock Peak Display Refresh Rate',
    description: 'Locks the minimum display refresh rate to the peak rate to eliminate adaptive down-throttling.',
    category: OptimizationCategory.display,
    requiredCapability: OptimizationCapability.systemSettingsWrite,
    riskLevel: OptimizationRiskLevel.low,
    minAndroidSdk: 28,
    isReversible: true,
    requiredPermission: 'android.permission.WRITE_SECURE_SETTINGS',
    verificationMethod: VerificationMethod.displayModeVerification,
    whatWillChange: 'Sets system min_refresh_rate to equal peak_refresh_rate.',
    whyItHelps: 'May reduce frame pacing jitter caused by dynamic display frequency downclocking.',
    whatRiskExists: 'May slightly increase screen battery consumption during idle periods.',
    defaultParameters: {'targetRefreshRate': 120.0},
  );

  static const OptimizationDefinition fixedPerformanceMode = OptimizationDefinition(
    id: 'fixed_performance_mode',
    name: 'Fixed CPU/GPU Performance Governor',
    description: 'Forces Android power hal into fixed sustained performance governor to prevent mid-game clock drops.',
    category: OptimizationCategory.performance,
    requiredCapability: OptimizationCapability.shizukuPrivileged,
    riskLevel: OptimizationRiskLevel.low,
    minAndroidSdk: 28,
    isReversible: true,
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Enables fixed performance mode via Android Power HAL shell API.',
    whyItHelps: 'Prevents CPU/GPU frequency drops during heavy 3D rendering spikes.',
    whatRiskExists: 'May slightly increase battery drain and device warmth during gaming sessions.',
  );

  static const OptimizationDefinition touchLatencyTweak = OptimizationDefinition(
    id: 'ultra_touch_latency',
    name: 'Zero Touch Latency Response',
    description: 'Minimizes tap duration threshold and touch blocking period for instant touch input responsiveness.',
    category: OptimizationCategory.touch,
    requiredCapability: OptimizationCapability.systemSettingsWrite,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 26,
    isReversible: true,
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Sets tap_duration_threshold and touch_blocking_period to 0.0.',
    whyItHelps: 'Reduces touch sample-to-display delay in fast-paced competitive shooters and rhythm games.',
    whatRiskExists: 'Slightly higher touch sensitivity may register micro-finger taps.',
  );

  static const OptimizationDefinition disableWindowBlurs = OptimizationDefinition(
    id: 'disable_window_blurs',
    name: 'Disable Surface Gaussian Blurs',
    description: 'Turns off expensive real-time background composition blurs to free up GPU fillrate for games.',
    category: OptimizationCategory.display,
    requiredCapability: OptimizationCapability.systemSettingsWrite,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 31,
    isReversible: true,
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Sets global disable_window_blurs to 1.',
    whyItHelps: 'Reclaims GPU shading power previously wasted on compositor background blurs.',
    whatRiskExists: 'System panels will render with solid or semi-transparent backgrounds without blur.',
  );

  static const OptimizationDefinition tcpNetworkBuffer = OptimizationDefinition(
    id: 'tcp_network_buffer',
    name: 'Gaming TCP Buffer Optimization',
    description: 'Expands Wi-Fi and LTE socket buffers to reduce packet jitter and prevent micro-drops in multiplayer matches.',
    category: OptimizationCategory.network,
    requiredCapability: OptimizationCapability.shizukuPrivileged,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 26,
    isReversible: true,
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Tuning net.tcp.buffersize for Wi-Fi and mobile networks.',
    whyItHelps: 'Reduces ping fluctuation and packet retransmission in competitive online games.',
    whatRiskExists: 'Slightly increases socket memory allocation when transmitting heavy data packets.',
  );

  static const OptimizationDefinition gpuVsyncBoost = OptimizationDefinition(
    id: 'gpu_vsync_boost',
    name: 'Hardware Composer V-Sync Priority',
    description: 'Forces hardware-accelerated V-Sync synchronization for tear-free, butter-smooth frame pacing.',
    category: OptimizationCategory.performance,
    requiredCapability: OptimizationCapability.shizukuPrivileged,
    riskLevel: OptimizationRiskLevel.low,
    minAndroidSdk: 26,
    isReversible: true,
    verificationMethod: VerificationMethod.settingsVerification,
    whatWillChange: 'Sets debug.hwc.force_gpu_vsync property to 1.',
    whyItHelps: 'Minimizes stutter and display tearing during fluctuating framerates.',
    whatRiskExists: 'May increase GPU active duty cycle slightly.',
  );

  static const OptimizationDefinition deepRamClean = OptimizationDefinition(
    id: 'deep_ram_clean',
    name: 'Deep System RAM & Cache Purge',
    description: 'Performs an intensive memory sweep, clearing inactive background cache pages and freeing gigabytes of RAM.',
    category: OptimizationCategory.performance,
    requiredCapability: OptimizationCapability.standardAndroid,
    riskLevel: OptimizationRiskLevel.none,
    minAndroidSdk: 26,
    isReversible: false,
    verificationMethod: VerificationMethod.memoryStateVerification,
    whatWillChange: 'Trims package caches and invokes garbage collection across background processes.',
    whyItHelps: 'Provides maximum headroom for game assets and textures without background app interference.',
    whatRiskExists: 'Cold-restarting closed background apps may take slightly longer.',
  );

  static const OptimizationDefinition bypassFpsPipeline = OptimizationDefinition(
    id: 'bypass_fps_pipeline',
    name: 'Unlock Peak FPS via Render Pipeline Bypass',
    description: 'Overrides SurfaceFlinger backpressure, DisplayManager frame-rate matching, and refresh-rate downclocking so all games run at the display\'s true peak Hz (e.g. 144 Hz).',
    category: OptimizationCategory.display,
    requiredCapability: OptimizationCapability.shizukuPrivileged,
    riskLevel: OptimizationRiskLevel.low,
    minAndroidSdk: 28,
    isReversible: true,
    verificationMethod: VerificationMethod.displayModeVerification,
    whatWillChange: 'Sets debug.sf.disable_backpressure, debug.sf.latch_unsignaled, disables content-detection refresh-rate matching, and locks min/peak refresh rates to display peak.',
    whyItHelps: 'Games capped at 60/120 fps by SurfaceFlinger\'s render pipeline can now render and present frames up to the hardware display limit (144 Hz).',
    whatRiskExists: 'Higher sustained GPU/CPU load when battery optimization is off. Reboot reverts setprop changes; Settings-based values persist until manually restored.',
    defaultParameters: {'enabled': true, 'targetHz': 144.0},
  );

  void _registerBuiltinOptimizations() {
    registerDefinition(ramTrimCaches);
    registerDefinition(windowAnimationScale);
    registerDefinition(gamingDndZen);
    registerDefinition(peakRefreshRate);
    registerDefinition(fixedPerformanceMode);
    registerDefinition(touchLatencyTweak);
    registerDefinition(disableWindowBlurs);
    registerDefinition(tcpNetworkBuffer);
    registerDefinition(gpuVsyncBoost);
    registerDefinition(deepRamClean);
    registerDefinition(bypassFpsPipeline);
  }

  /// Registers an optimization definition with safety validation.
  void registerDefinition(OptimizationDefinition definition) {
    final report = _validator.checkSafety(definition);
    if (!report.isValid) {
      throw ArgumentError(
        'Cannot register prohibited optimization "${definition.id}": ${report.reason}',
      );
    }
    _definitions[definition.id] = definition;
  }

  /// Binds an executable handler to an optimization definition.
  void registerHandler(String optimizationId, OptimizationHandler handler) {
    if (!_definitions.containsKey(optimizationId)) {
      throw StateError(
        'Optimization definition "$optimizationId" must be registered before attaching a handler.',
      );
    }
    _handlers[optimizationId] = handler;
  }

  /// Returns all registered definitions.
  List<OptimizationDefinition> getAll() => List.unmodifiable(_definitions.values);

  /// Looks up a definition by its ID.
  OptimizationDefinition? getDefinition(String id) => _definitions[id];

  /// Looks up a handler by optimization ID.
  OptimizationHandler? getHandler(String id) => _handlers[id];

  /// Returns all definitions belonging to a specific category.
  List<OptimizationDefinition> getByCategory(OptimizationCategory category) {
    return _definitions.values.where((d) => d.category == category).toList();
  }

  /// Returns all reversible definitions.
  List<OptimizationDefinition> getReversible() {
    return _definitions.values.where((d) => d.isReversible).toList();
  }
}
