/// Capabilities required by optimizations to execute on the Android platform.
enum OptimizationCapability {
  /// Standard unprivileged Android SDK API call (e.g., ActivityManager.trimMemory).
  standardAndroid('Standard Android API', 'Executable without elevated privileges'),

  /// Access to NotificationManager notification and DND policy.
  notificationPolicy('Notification Policy Access', 'Allows managing Zen Mode / Do Not Disturb'),

  /// Elevated system access via Shizuku binder IPC.
  shizukuPrivileged('Shizuku Service', 'Requires Shizuku service running and authorized'),

  /// Capability to read and write system/global settings safely.
  systemSettingsWrite('System Settings Access', 'Allows tuning display and window parameters'),

  /// Android PowerManager power hints and thermal status listeners.
  powerManagerHints('Power Management API', 'Allows issuing system power hints');

  const OptimizationCapability(this.displayName, this.description);

  final String displayName;
  final String description;
}
