import 'thermal_status.dart';

/// An immutable sample of real-time device performance telemetry at a given point in time.
///
/// Only contains legitimate values retrieved from Android APIs.
/// If a metric is not exposed or measurable, it is strictly `null` (never fabricated).
class PerformanceSnapshot {
  const PerformanceSnapshot({
    required this.timestamp,
    this.ramUsedBytes,
    this.ramTotalBytes,
    this.isLowMemory = false,
    this.batteryPercent,
    this.batteryTempC,
    this.batteryStatus,
    this.displayRefreshRate,
    this.thermalStatus = ThermalStatus.unavailable,
    this.frameTimeMs,
    this.fps,
    this.cpuCoreFreqsKhz,
  });

  final DateTime timestamp;

  /// RAM used in bytes.
  final int? ramUsedBytes;

  /// Total system RAM in bytes.
  final int? ramTotalBytes;

  /// Whether the system reports being in a low-memory situation.
  final bool isLowMemory;

  /// Battery charge percentage (0–100).
  final int? batteryPercent;

  /// Battery temperature in degrees Celsius (from BatteryManager).
  final double? batteryTempC;

  /// Battery charging state (e.g., 'Charging', 'Discharging', 'Full').
  final String? batteryStatus;

  /// Active display refresh rate in Hz (e.g. 60.0, 90.0, 120.0).
  final double? displayRefreshRate;

  /// Platform thermal throttling state.
  final ThermalStatus thermalStatus;

  /// Frame rendering time in milliseconds, where accessible.
  final double? frameTimeMs;

  /// Frames per second, ONLY where legitimately and reliably measurable.
  /// Strictly null if cross-process frame metrics are not exposed by the OS.
  final double? fps;

  /// Current operating frequencies of CPU cores in kHz.
  final List<int>? cpuCoreFreqsKhz;

  // ---------------------------------------------------------------------------
  // Helper getters
  // ---------------------------------------------------------------------------

  /// Ratio of used RAM to total RAM (0.0 to 1.0), or null if unavailable.
  double? get ramUsageRatio {
    if (ramUsedBytes == null || ramTotalBytes == null || ramTotalBytes == 0) {
      return null;
    }
    return (ramUsedBytes! / ramTotalBytes!).clamp(0.0, 1.0);
  }

  /// Formatted string for used RAM (e.g., "4.2 GB").
  String get ramUsedFormatted {
    if (ramUsedBytes == null) return 'Unavailable';
    final gb = ramUsedBytes! / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }

  /// Formatted string for total RAM (e.g., "8.0 GB").
  String get ramTotalFormatted {
    if (ramTotalBytes == null) return 'Unavailable';
    final gb = ramTotalBytes! / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }

  /// Formatted string for FPS or "Unavailable".
  String get fpsDisplay {
    if (fps == null) return 'Unavailable';
    return '${fps!.toStringAsFixed(1)} FPS';
  }

  /// Formatted string for frame time or "Unavailable".
  String get frameTimeDisplay {
    if (frameTimeMs == null) return 'Unavailable';
    return '${frameTimeMs!.toStringAsFixed(1)} ms';
  }

  /// Formatted string for battery temperature or "Unavailable".
  String get batteryTempDisplay {
    if (batteryTempC == null) return 'Unavailable';
    return '${batteryTempC!.toStringAsFixed(1)}°C';
  }

  /// Formatted string for display refresh rate or "Unavailable".
  String get refreshRateDisplay {
    if (displayRefreshRate == null) return 'Unavailable';
    return '${displayRefreshRate!.toStringAsFixed(0)} Hz';
  }

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'ramUsedBytes': ramUsedBytes,
        'ramTotalBytes': ramTotalBytes,
        'isLowMemory': isLowMemory,
        'batteryPercent': batteryPercent,
        'batteryTempC': batteryTempC,
        'batteryStatus': batteryStatus,
        'displayRefreshRate': displayRefreshRate,
        'thermalStatusCode': thermalStatus.code,
        'frameTimeMs': frameTimeMs,
        'fps': fps,
        'cpuCoreFreqsKhz': cpuCoreFreqsKhz,
      };

  factory PerformanceSnapshot.fromMap(Map<String, dynamic> map) {
    return PerformanceSnapshot(
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      ramUsedBytes: map['ramUsedBytes'] as int?,
      ramTotalBytes: map['ramTotalBytes'] as int?,
      isLowMemory: map['isLowMemory'] as bool? ?? false,
      batteryPercent: map['batteryPercent'] as int?,
      batteryTempC: (map['batteryTempC'] as num?)?.toDouble(),
      batteryStatus: map['batteryStatus'] as String?,
      displayRefreshRate: (map['displayRefreshRate'] as num?)?.toDouble(),
      thermalStatus: ThermalStatus.fromCode(map['thermalStatusCode'] as int?),
      frameTimeMs: (map['frameTimeMs'] as num?)?.toDouble(),
      fps: (map['fps'] as num?)?.toDouble(),
      cpuCoreFreqsKhz: (map['cpuCoreFreqsKhz'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }
}
