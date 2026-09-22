import '../../../shizuku/domain/entities/shizuku_status.dart';

/// Severity of a pre-flight issue.
enum PreFlightSeverity {
  /// Hard blocker — workflow must not proceed until resolved.
  blocker,

  /// Non-blocking advisory shown as a warning.
  warning,

  /// Informational note with no action required.
  info,
}

/// A single pre-flight check result.
class PreFlightIssue {
  const PreFlightIssue({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    this.fixAction,
  });

  /// Unique identifier (e.g. 'thermal_critical', 'missing_dnd_permission').
  final String id;

  /// Short user-facing title.
  final String title;

  /// Detailed explanation without jargon.
  final String detail;

  final PreFlightSeverity severity;

  /// Optional action label shown on a button (e.g. 'Grant Permission').
  final String? fixAction;

  bool get isBlocker => severity == PreFlightSeverity.blocker;
}

/// Aggregated result of the pre-execution pre-flight check.
class PreFlightReport {
  const PreFlightReport({
    required this.androidSdkInt,
    required this.shizukuStatus,
    required this.hasDndPermission,
    required this.hasWriteSecureSettings,
    required this.batteryPercent,
    required this.thermalStatusCode,
    required this.isCharging,
    this.gamePackage,
    this.issues = const [],
  });

  /// Current Android API level (e.g. 34 for Android 14).
  final int androidSdkInt;

  final ShizukuStatus shizukuStatus;

  /// Whether ACCESS_NOTIFICATION_POLICY is granted.
  final bool hasDndPermission;

  /// Whether WRITE_SECURE_SETTINGS is granted (requires Shizuku or ADB).
  final bool hasWriteSecureSettings;

  /// Current battery level 0–100.
  final int batteryPercent;

  /// Android ThermalStatus code (0=none, 1=light, 2=moderate, 3=severe, 4=critical, 5=emergency, 6=shutdown).
  final int thermalStatusCode;

  final bool isCharging;

  /// Target game package if known.
  final String? gamePackage;

  /// List of issues found during pre-flight.
  final List<PreFlightIssue> issues;

  /// True when any blocker issue exists.
  bool get hasBlocker => issues.any((i) => i.isBlocker);

  /// True when any warning-level issue exists.
  bool get hasWarnings =>
      issues.any((i) => i.severity == PreFlightSeverity.warning);

  /// Human-readable Android version label.
  String get androidVersionDisplay {
    if (androidSdkInt >= 34) return 'Android 14 (API $androidSdkInt)';
    if (androidSdkInt >= 33) return 'Android 13 (API $androidSdkInt)';
    if (androidSdkInt >= 31) return 'Android 12 (API $androidSdkInt)';
    if (androidSdkInt >= 29) return 'Android 10 (API $androidSdkInt)';
    return 'Android (API $androidSdkInt)';
  }

  /// Simplified thermal label for non-technical users.
  String get thermalLabel => switch (thermalStatusCode) {
        0 => 'Cool',
        1 => 'Slightly Warm',
        2 => 'Warm',
        3 => 'Hot',
        4 || 5 || 6 => 'Critical',
        _ => 'Unknown',
      };

  bool get isThermalCritical => thermalStatusCode >= 4;

  bool get isBatteryLow => batteryPercent < 15 && !isCharging;
}
