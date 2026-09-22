/// Represents the Android platform thermal throttling status (API 29+).
///
/// Maps directly to [android.os.PowerManager.THERMAL_STATUS_*] constants.
enum ThermalStatus {
  none(0, 'Normal', 'No thermal throttling active'),
  light(1, 'Light', 'Device warming up; light throttling may occur'),
  moderate(2, 'Moderate', 'Noticeable thermal throttling active to control heat'),
  severe(3, 'Severe', 'Significant throttling; performance noticeably affected'),
  critical(4, 'Critical', 'Critical temperature; platform aggressive cooldown'),
  emergency(5, 'Emergency', 'Emergency state; components shutting down to protect hardware'),
  shutdown(6, 'Shutdown', 'Device thermal shutdown imminent'),
  unavailable(-1, 'Unavailable', 'Thermal status reporting not supported on this device/OS');

  const ThermalStatus(this.code, this.displayName, this.description);

  final int code;
  final String displayName;
  final String description;

  /// Whether thermal throttling is currently affecting device performance.
  bool get isThrottling => code >= 2;

  /// Whether thermal state is at a hazardous or critical level.
  bool get isCritical => code >= 4;

  /// Resolves an integer code from Android PowerManager to [ThermalStatus].
  static ThermalStatus fromCode(int? code) {
    if (code == null) return ThermalStatus.unavailable;
    for (final status in ThermalStatus.values) {
      if (status.code == code) return status;
    }
    return ThermalStatus.unavailable;
  }
}
