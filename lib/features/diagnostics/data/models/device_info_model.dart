/// Rich device hardware information collected from Android system APIs.
library;

// -----------------------------------------------------------------------------
// Helper
// -----------------------------------------------------------------------------

String _s(Map<String, dynamic> m, String k, [String fallback = 'Unavailable']) =>
    (m[k] as String?)?.trim().isNotEmpty == true ? m[k] as String : fallback;

int? _i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt();
double? _d(Map<String, dynamic> m, String k) => (m[k] as num?)?.toDouble();
bool? _b(Map<String, dynamic> m, String k) => m[k] as bool?;

// -----------------------------------------------------------------------------
// Basic device identity
// -----------------------------------------------------------------------------

class DeviceIdentity {
  const DeviceIdentity({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.androidVersion,
    required this.sdkInt,
    required this.buildId,
    required this.buildType,
    required this.hardware,
    required this.cpuAbi,
    required this.supportedAbis,
  });

  final String manufacturer;
  final String brand;
  final String model;
  final String device;
  final String product;
  final String androidVersion;
  final int? sdkInt;
  final String buildId;
  final String buildType;
  final String hardware;
  final String cpuAbi;
  final List<String> supportedAbis;

  factory DeviceIdentity.fromMap(Map<String, dynamic> m) => DeviceIdentity(
        manufacturer: _s(m, 'manufacturer'),
        brand: _s(m, 'brand'),
        model: _s(m, 'model'),
        device: _s(m, 'device'),
        product: _s(m, 'product'),
        androidVersion: _s(m, 'androidVersion'),
        sdkInt: _i(m, 'sdkInt'),
        buildId: _s(m, 'buildId'),
        buildType: _s(m, 'buildType'),
        hardware: _s(m, 'hardware'),
        cpuAbi: _s(m, 'cpuAbi'),
        supportedAbis: (m['supportedAbis'] as List?)?.cast<String>() ?? [],
      );

  static const unavailable = DeviceIdentity(
    manufacturer: 'Unavailable',
    brand: 'Unavailable',
    model: 'Unavailable',
    device: 'Unavailable',
    product: 'Unavailable',
    androidVersion: 'Unavailable',
    sdkInt: null,
    buildId: 'Unavailable',
    buildType: 'Unavailable',
    hardware: 'Unavailable',
    cpuAbi: 'Unavailable',
    supportedAbis: [],
  );
}

// -----------------------------------------------------------------------------
// Memory (RAM)
// -----------------------------------------------------------------------------

class MemoryInfo {
  const MemoryInfo({
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.lowMemory,
    required this.lowMemThresholdBytes,
  });

  final int? totalRamBytes;
  final int? availableRamBytes;
  final bool? lowMemory;
  final int? lowMemThresholdBytes;

  double? get totalRamGb =>
      totalRamBytes != null ? totalRamBytes! / (1024 * 1024 * 1024) : null;
  double? get availableRamGb =>
      availableRamBytes != null ? availableRamBytes! / (1024 * 1024 * 1024) : null;
  double? get usedRamGb =>
      (totalRamBytes != null && availableRamBytes != null)
          ? (totalRamBytes! - availableRamBytes!) / (1024 * 1024 * 1024)
          : null;
  int? get usedPercent =>
      (totalRamBytes != null && availableRamBytes != null && totalRamBytes! > 0)
          ? (((totalRamBytes! - availableRamBytes!) / totalRamBytes!) * 100).round()
          : null;

  factory MemoryInfo.fromMap(Map<String, dynamic> m) => MemoryInfo(
        totalRamBytes: _i(m, 'totalRamBytes'),
        availableRamBytes: _i(m, 'availableRamBytes'),
        lowMemory: _b(m, 'lowMemory'),
        lowMemThresholdBytes: _i(m, 'lowMemThresholdBytes'),
      );

  static const unavailable = MemoryInfo(
    totalRamBytes: null,
    availableRamBytes: null,
    lowMemory: null,
    lowMemThresholdBytes: null,
  );
}

// -----------------------------------------------------------------------------
// Storage
// -----------------------------------------------------------------------------

class StorageInfo {
  const StorageInfo({
    required this.internalTotalBytes,
    required this.internalAvailableBytes,
    this.externalTotalBytes,
    this.externalAvailableBytes,
  });

  final int? internalTotalBytes;
  final int? internalAvailableBytes;
  final int? externalTotalBytes;
  final int? externalAvailableBytes;

  double? get internalTotalGb =>
      internalTotalBytes != null ? internalTotalBytes! / (1024 * 1024 * 1024) : null;
  double? get internalAvailableGb =>
      internalAvailableBytes != null ? internalAvailableBytes! / (1024 * 1024 * 1024) : null;
  int? get internalUsedPercent =>
      (internalTotalBytes != null && internalAvailableBytes != null && internalTotalBytes! > 0)
          ? (((internalTotalBytes! - internalAvailableBytes!) / internalTotalBytes!) * 100).round()
          : null;

  factory StorageInfo.fromMap(Map<String, dynamic> m) => StorageInfo(
        internalTotalBytes: _i(m, 'internalTotalBytes'),
        internalAvailableBytes: _i(m, 'internalAvailableBytes'),
        externalTotalBytes: _i(m, 'externalTotalBytes'),
        externalAvailableBytes: _i(m, 'externalAvailableBytes'),
      );

  static const unavailable = StorageInfo(
    internalTotalBytes: null,
    internalAvailableBytes: null,
  );
}

// -----------------------------------------------------------------------------
// Battery
// -----------------------------------------------------------------------------

class BatteryInfo {
  const BatteryInfo({
    required this.percentage,
    required this.status,
    required this.health,
    required this.technology,
    this.temperatureC,
    this.voltageMv,
    this.plugged,
    this.capacity,
  });

  final int? percentage;
  final String status;
  final String health;
  final String technology;
  final double? temperatureC;
  final int? voltageMv;
  final String? plugged;
  final int? capacity;

  bool get isCharging => status == 'Charging' || status == 'Full';

  factory BatteryInfo.fromMap(Map<String, dynamic> m) => BatteryInfo(
        percentage: _i(m, 'percentage'),
        status: _s(m, 'status'),
        health: _s(m, 'health'),
        technology: _s(m, 'technology'),
        temperatureC: _d(m, 'temperatureC'),
        voltageMv: _i(m, 'voltageMv'),
        plugged: m['plugged'] as String?,
        capacity: _i(m, 'capacity'),
      );

  static const unavailable = BatteryInfo(
    percentage: null,
    status: 'Unavailable',
    health: 'Unavailable',
    technology: 'Unavailable',
  );
}

// -----------------------------------------------------------------------------
// Display
// -----------------------------------------------------------------------------

class DisplayInfo {
  const DisplayInfo({
    required this.widthPx,
    required this.heightPx,
    required this.densityDpi,
    required this.refreshRateHz,
    required this.supportedRatesHz,
  });

  final int? widthPx;
  final int? heightPx;
  final int? densityDpi;
  final double? refreshRateHz;
  final List<double> supportedRatesHz;

  String get resolution =>
      (widthPx != null && heightPx != null) ? '$widthPx\u00D7$heightPx' : 'Unavailable';

  factory DisplayInfo.fromMap(Map<String, dynamic> m) => DisplayInfo(
        widthPx: _i(m, 'widthPx'),
        heightPx: _i(m, 'heightPx'),
        densityDpi: _i(m, 'densityDpi'),
        refreshRateHz: _d(m, 'refreshRateHz'),
        supportedRatesHz:
            (m['supportedRatesHz'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      );

  static const unavailable = DisplayInfo(
    widthPx: null,
    heightPx: null,
    densityDpi: null,
    refreshRateHz: null,
    supportedRatesHz: [],
  );
}

// -----------------------------------------------------------------------------
// CPU
// -----------------------------------------------------------------------------

class CoreFrequency {
  const CoreFrequency({
    required this.core,
    this.currentKhz,
    this.maxKhz,
    this.minKhz,
  });

  final int core;
  final int? currentKhz;
  final int? maxKhz;
  final int? minKhz;

  double? get currentGhz => currentKhz != null ? currentKhz! / 1000000.0 : null;
  double? get maxGhz => maxKhz != null ? maxKhz! / 1000000.0 : null;

  factory CoreFrequency.fromMap(Map<String, dynamic> m) => CoreFrequency(
        core: _i(m, 'core') ?? 0,
        currentKhz: _i(m, 'curKhz'),
        maxKhz: _i(m, 'maxKhz'),
        minKhz: _i(m, 'minKhz'),
      );
}

class CpuInfo {
  const CpuInfo({
    required this.numCores,
    required this.hardware,
    required this.primaryAbi,
    required this.abis,
    required this.coreFrequencies,
    this.model,
  });

  final int? numCores;
  final String hardware;
  final String primaryAbi;
  final List<String> abis;
  final List<CoreFrequency> coreFrequencies;
  final String? model;

  factory CpuInfo.fromMap(Map<String, dynamic> m) => CpuInfo(
        numCores: _i(m, 'numCores'),
        hardware: _s(m, 'hardware'),
        primaryAbi: _s(m, 'primaryAbi'),
        abis: (m['abis'] as List?)?.cast<String>() ?? [],
        coreFrequencies: (m['coreFreqs'] as List?)
                ?.map((e) => CoreFrequency.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        model: m['model'] as String?,
      );

  static const unavailable = CpuInfo(
    numCores: null,
    hardware: 'Unavailable',
    primaryAbi: 'Unavailable',
    abis: [],
    coreFrequencies: [],
  );
}

// -----------------------------------------------------------------------------
// Aggregate
// -----------------------------------------------------------------------------

class FullDeviceInfo {
  const FullDeviceInfo({
    required this.identity,
    required this.memory,
    required this.storage,
    required this.battery,
    required this.display,
    required this.cpu,
  });

  final DeviceIdentity identity;
  final MemoryInfo memory;
  final StorageInfo storage;
  final BatteryInfo battery;
  final DisplayInfo display;
  final CpuInfo cpu;

  factory FullDeviceInfo.fromMap(Map<String, dynamic> m) => FullDeviceInfo(
        identity: DeviceIdentity.fromMap(Map<String, dynamic>.from(m['device'] as Map)),
        memory: MemoryInfo.fromMap(Map<String, dynamic>.from(m['memory'] as Map)),
        storage: StorageInfo.fromMap(Map<String, dynamic>.from(m['storage'] as Map)),
        battery: BatteryInfo.fromMap(Map<String, dynamic>.from(m['battery'] as Map)),
        display: DisplayInfo.fromMap(Map<String, dynamic>.from(m['display'] as Map)),
        cpu: CpuInfo.fromMap(Map<String, dynamic>.from(m['cpu'] as Map)),
      );

  static const unavailable = FullDeviceInfo(
    identity: DeviceIdentity.unavailable,
    memory: MemoryInfo.unavailable,
    storage: StorageInfo.unavailable,
    battery: BatteryInfo.unavailable,
    display: DisplayInfo.unavailable,
    cpu: CpuInfo.unavailable,
  );
}
