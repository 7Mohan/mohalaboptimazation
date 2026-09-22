import 'dart:convert';
import 'package:flutter/material.dart';

/// Supported optimization categories that can be toggled per game.
enum OptimizationCategory {
  performance('Performance', Icons.speed_rounded, 'CPU & GPU resource prioritization'),
  battery('Battery & Thermals', Icons.battery_charging_full_rounded, 'Power curves and thermal limits'),
  network('Network Latency', Icons.wifi_tethering_rounded, 'Gaming packet prioritization'),
  touch('Touch & Input', Icons.touch_app_rounded, 'Sampling rate and touch response'),
  display('Display & Refresh', Icons.tv_rounded, 'Target FPS and refresh rate stability');

  const OptimizationCategory(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

/// Performance tuning profile modes.
enum PerformancePreference {
  balanced('Balanced', 'Adaptive performance managed by system policies'),
  highPerformance('High Performance', 'Maximized CPU/GPU clock limits for sustained FPS'),
  powerSaving('Power Saving', 'Optimized clocks to extend gaming session longevity');

  const PerformancePreference(this.label, this.description);
  final String label;
  final String description;
}

/// Battery & thermal preference modes.
enum BatteryPreference {
  normal('Standard', 'Standard thermal throttling thresholds'),
  batterySaver('Thermal Guard', 'Proactive cooling curve to prevent severe throttling'),
  extremeSaver('Max Battery', 'Reduced energy footprint for lightweight titles');

  const BatteryPreference(this.label, this.description);
  final String label;
  final String description;
}

/// Network prioritization modes.
enum NetworkPreference {
  normal('Normal', 'Standard network bandwidth sharing'),
  lowLatency('Low Latency', 'High-priority packet queue for multiplayer games'),
  bandwidthSaver('Bandwidth Saver', 'Suppresses non-essential background downloads');

  const NetworkPreference(this.label, this.description);
  final String label;
  final String description;
}

/// Touch sensitivity & polling modes.
enum TouchPreference {
  standard('Standard', 'Default touch input sampling rate'),
  highSensitivity('High Sensitivity', 'Increased touch polling rate for responsive aiming'),
  ultraResponsive('Ultra Responsive', 'Zero input buffer delay mode');

  const TouchPreference(this.label, this.description);
  final String label;
  final String description;
}

/// Display refresh rate targeting modes.
enum DisplayPreference {
  auto('Dynamic Auto', 'Matches game request up to screen maximum'),
  fps60('60 Hz Stable', 'Capped for maximum thermal consistency'),
  fps90('90 Hz Smooth', 'Sweet spot for competitive titles'),
  fps120('120 Hz Ultra', 'Maximum smoothness on supported high-refresh panels');

  const DisplayPreference(this.label, this.description);
  final String label;
  final String description;
}

/// Safe whitelist keys for optional user settings.
abstract final class SafeUserSettingsKeys {
  static const String preventNotificationPopups = 'preventNotificationPopups';
  static const String lockBrightness = 'lockBrightness';
  static const String keepScreenAwake = 'keepScreenAwake';
  static const String disableAutoSync = 'disableAutoSync';

  static const List<String> allKeys = [
    preventNotificationPopups,
    lockBrightness,
    keepScreenAwake,
    disableAutoSync,
  ];
}

/// Domain model representing a per-game optimization profile.
class GameProfile {
  const GameProfile({
    required this.gamePackage,
    required this.gameName,
    this.profileVersion = currentVersion,
    this.lastUsed,
    this.enabledCategories = const {
      OptimizationCategory.performance,
      OptimizationCategory.display,
    },
    this.performance = PerformancePreference.balanced,
    this.battery = BatteryPreference.normal,
    this.network = NetworkPreference.normal,
    this.touch = TouchPreference.standard,
    this.display = DisplayPreference.auto,
    this.userSettings = const {
      SafeUserSettingsKeys.preventNotificationPopups: false,
      SafeUserSettingsKeys.lockBrightness: false,
      SafeUserSettingsKeys.keepScreenAwake: true,
      SafeUserSettingsKeys.disableAutoSync: false,
    },
    this.isCustomized = false,
  });

  static const int currentVersion = 1;

  final String gamePackage;
  final String gameName;
  final int profileVersion;
  final DateTime? lastUsed;
  final Set<OptimizationCategory> enabledCategories;
  final PerformancePreference performance;
  final BatteryPreference battery;
  final NetworkPreference network;
  final TouchPreference touch;
  final DisplayPreference display;
  final Map<String, dynamic> userSettings;
  final bool isCustomized;

  /// Creates a default safe profile for a newly detected game.
  factory GameProfile.defaultForGame(String packageName, String gameName) {
    return GameProfile(
      gamePackage: packageName,
      gameName: gameName,
      profileVersion: currentVersion,
      lastUsed: DateTime.now(),
      enabledCategories: const {
        OptimizationCategory.performance,
        OptimizationCategory.display,
      },
      performance: PerformancePreference.balanced,
      battery: BatteryPreference.normal,
      network: NetworkPreference.normal,
      touch: TouchPreference.standard,
      display: DisplayPreference.auto,
      userSettings: const {
        SafeUserSettingsKeys.preventNotificationPopups: false,
        SafeUserSettingsKeys.lockBrightness: false,
        SafeUserSettingsKeys.keepScreenAwake: true,
        SafeUserSettingsKeys.disableAutoSync: false,
      },
      isCustomized: false,
    );
  }

  GameProfile copyWith({
    String? gamePackage,
    String? gameName,
    int? profileVersion,
    DateTime? lastUsed,
    Set<OptimizationCategory>? enabledCategories,
    PerformancePreference? performance,
    BatteryPreference? battery,
    NetworkPreference? network,
    TouchPreference? touch,
    DisplayPreference? display,
    Map<String, dynamic>? userSettings,
    bool? isCustomized,
  }) {
    return GameProfile(
      gamePackage: gamePackage ?? this.gamePackage,
      gameName: gameName ?? this.gameName,
      profileVersion: profileVersion ?? this.profileVersion,
      lastUsed: lastUsed ?? this.lastUsed,
      enabledCategories: enabledCategories ?? this.enabledCategories,
      performance: performance ?? this.performance,
      battery: battery ?? this.battery,
      network: network ?? this.network,
      touch: touch ?? this.touch,
      display: display ?? this.display,
      userSettings: userSettings ?? Map<String, dynamic>.from(this.userSettings),
      isCustomized: isCustomized ?? this.isCustomized,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamePackage': gamePackage,
      'gameName': gameName,
      'profileVersion': profileVersion,
      'lastUsed': lastUsed?.toIso8601String(),
      'enabledCategories': enabledCategories.map((c) => c.name).toList(),
      'performance': performance.name,
      'battery': battery.name,
      'network': network.name,
      'touch': touch.name,
      'display': display.name,
      'userSettings': userSettings,
      'isCustomized': isCustomized,
    };
  }

  factory GameProfile.fromMap(Map<String, dynamic> map) {
    final enabledCategoriesList = (map['enabledCategories'] as List<dynamic>?)
            ?.map((e) => OptimizationCategory.values.firstWhere(
                  (cat) => cat.name == e.toString(),
                  orElse: () => OptimizationCategory.performance,
                ))
            .toSet() ??
        const {OptimizationCategory.performance, OptimizationCategory.display};

    final performance = PerformancePreference.values.firstWhere(
      (e) => e.name == map['performance'],
      orElse: () => PerformancePreference.balanced,
    );

    final battery = BatteryPreference.values.firstWhere(
      (e) => e.name == map['battery'],
      orElse: () => BatteryPreference.normal,
    );

    final network = NetworkPreference.values.firstWhere(
      (e) => e.name == map['network'],
      orElse: () => NetworkPreference.normal,
    );

    final touch = TouchPreference.values.firstWhere(
      (e) => e.name == map['touch'],
      orElse: () => TouchPreference.standard,
    );

    final display = DisplayPreference.values.firstWhere(
      (e) => e.name == map['display'],
      orElse: () => DisplayPreference.auto,
    );

    DateTime? parsedLastUsed;
    if (map['lastUsed'] is String) {
      parsedLastUsed = DateTime.tryParse(map['lastUsed'] as String);
    }

    final rawSettings = map['userSettings'];
    final settings = <String, dynamic>{};
    if (rawSettings is Map) {
      for (final key in SafeUserSettingsKeys.allKeys) {
        if (rawSettings.containsKey(key)) {
          settings[key] = rawSettings[key];
        } else {
          settings[key] = false;
        }
      }
    }

    return GameProfile(
      gamePackage: map['gamePackage'] as String? ?? 'unknown.package',
      gameName: map['gameName'] as String? ?? 'Unknown Game',
      profileVersion: (map['profileVersion'] as num?)?.toInt() ?? currentVersion,
      lastUsed: parsedLastUsed,
      enabledCategories: enabledCategoriesList,
      performance: performance,
      battery: battery,
      network: network,
      touch: touch,
      display: display,
      userSettings: settings.isEmpty
          ? const {
              SafeUserSettingsKeys.preventNotificationPopups: false,
              SafeUserSettingsKeys.lockBrightness: false,
              SafeUserSettingsKeys.keepScreenAwake: true,
              SafeUserSettingsKeys.disableAutoSync: false,
            }
          : settings,
      isCustomized: map['isCustomized'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GameProfile.fromJson(String source) =>
      GameProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameProfile &&
          runtimeType == other.runtimeType &&
          gamePackage == other.gamePackage &&
          profileVersion == other.profileVersion &&
          performance == other.performance &&
          battery == other.battery &&
          network == other.network &&
          touch == other.touch &&
          display == other.display;

  @override
  int get hashCode =>
      gamePackage.hashCode ^
      profileVersion.hashCode ^
      performance.hashCode ^
      battery.hashCode;
}
