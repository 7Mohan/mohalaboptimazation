/// Represents the 7 distinct states of the Shizuku service lifecycle.
///
/// States must be evaluated in order — never infer a "higher" state from
/// partial evidence. For example, detecting the rikka.shizuku package
/// does NOT imply the service is running.
enum ShizukuStatus {
  /// The Shizuku application is not installed on this device.
  notInstalled,

  /// Shizuku is installed but its background service is not running.
  /// User must manually start it via ADB or Wireless Debugging.
  notRunning,

  /// The Shizuku service binder is alive and connected to this process.
  /// Permission has not yet been checked.
  binderConnected,

  /// Binder is connected but the user explicitly denied the permission request,
  /// or the app has never requested it.
  permissionDenied,

  /// Permission was granted. Considered ready for privileged calls.
  permissionGranted,

  /// All checks pass — permission granted, binder alive, service confirmed.
  /// This is the only state where privileged operations should be attempted.
  ready,
}

/// Helpers for user-facing text and state-machine logic.
extension ShizukuStatusExtension on ShizukuStatus {
  /// Short title shown in status banners and headings.
  String get displayTitle => switch (this) {
        ShizukuStatus.notInstalled => 'Shizuku Not Installed',
        ShizukuStatus.notRunning => 'Shizuku Not Running',
        ShizukuStatus.binderConnected => 'Shizuku Connected',
        ShizukuStatus.permissionDenied => 'Permission Required',
        ShizukuStatus.permissionGranted => 'Permission Granted',
        ShizukuStatus.ready => 'Shizuku Ready',
      };

  /// Full explanation shown in the setup sheet.
  String get displayDescription => switch (this) {
        ShizukuStatus.notInstalled =>
          'Shizuku is required for advanced system controls such as per-game '
              'performance tuning. Please install it from the Play Store or GitHub.',
        ShizukuStatus.notRunning =>
          'Shizuku is installed but its service is not currently running. '
              'Start it using ADB or Wireless Debugging in Developer Options.',
        ShizukuStatus.binderConnected =>
          'Shizuku service is running. Grant permission to enable '
              'advanced optimization features.',
        ShizukuStatus.permissionDenied =>
          'Moha Lab Optimization was denied access to Shizuku. '
              'Tap "Request Permission" to try again.',
        ShizukuStatus.permissionGranted =>
          'Permission granted. Verifying service availability…',
        ShizukuStatus.ready =>
          'Shizuku is connected and ready. Advanced system optimization '
              'features are now available.',
      };

  /// Short label used in compact badges and list tiles.
  String get shortLabel => switch (this) {
        ShizukuStatus.notInstalled => 'Not Installed',
        ShizukuStatus.notRunning => 'Not Running',
        ShizukuStatus.binderConnected => 'Connected',
        ShizukuStatus.permissionDenied => 'Denied',
        ShizukuStatus.permissionGranted => 'Granted',
        ShizukuStatus.ready => 'Ready',
      };

  /// True when the user can take an action to advance the state.
  bool get isActionable => switch (this) {
        ShizukuStatus.notInstalled => true,
        ShizukuStatus.notRunning => true,
        ShizukuStatus.binderConnected => true,
        ShizukuStatus.permissionDenied => true,
        ShizukuStatus.permissionGranted => false,
        ShizukuStatus.ready => false,
      };

  /// True only when fully ready for privileged operations.
  bool get isReady => this == ShizukuStatus.ready;

  /// True when Shizuku is at least running (binder alive).
  bool get isRunning => switch (this) {
        ShizukuStatus.notInstalled => false,
        ShizukuStatus.notRunning => false,
        _ => true,
      };

  /// Maps raw string codes from the Android MethodChannel to this enum.
  static ShizukuStatus fromCode(String code) => switch (code) {
        'notInstalled' => ShizukuStatus.notInstalled,
        'notRunning' => ShizukuStatus.notRunning,
        'binderConnected' => ShizukuStatus.binderConnected,
        'permissionDenied' => ShizukuStatus.permissionDenied,
        'permissionGranted' => ShizukuStatus.permissionGranted,
        'ready' => ShizukuStatus.ready,
        _ => ShizukuStatus.notInstalled, // safe default
      };
}
