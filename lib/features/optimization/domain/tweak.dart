import 'package:flutter/material.dart';

/// Grouping used to lay tweaks out in sections.
enum TweakCategory {
  display('Display & Graphics', Icons.monitor_rounded),
  performance('Performance', Icons.speed_rounded),
  focus('Focus & Notifications', Icons.do_not_disturb_on_outlined),
  network('Network', Icons.wifi_rounded),
  input('Touch & Input', Icons.touch_app_outlined),
  kernel('Kernel', Icons.developer_board_rounded);

  const TweakCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// What the device must provide before a tweak can run.
enum TweakAccess {
  /// Works for any app.
  none('No setup'),

  /// System settings write: Shizuku, or WRITE_SECURE_SETTINGS granted over ADB.
  settings('Shizuku or ADB grant'),

  /// Needs a shell-level `cmd` service — Shizuku only.
  shell('Shizuku'),

  /// Do Not Disturb access or Shizuku.
  notificationPolicy('DND access or Shizuku'),

  /// Root shell: Magisk, KernelSU, APatch, or Shizuku started as root.
  root('Root (Magisk / KernelSU / APatch)');

  bool get isRoot => this == TweakAccess.root;

  const TweakAccess(this.label);
  final String label;
}

enum TweakImpact {
  low('Subtle'),
  medium('Noticeable'),
  high('Strong');

  const TweakImpact(this.label);
  final String label;
}

/// A reversible on/off system tweak. Everything described here is exactly
/// what the native engine writes — no hidden or placebo properties.
class TweakDefinition {
  const TweakDefinition({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.access,
    required this.changes,
    required this.tradeoff,
    this.impact = TweakImpact.medium,
    this.minSdk = 26,
    this.persistsReboot = true,
  });

  final String id;
  final String title;
  final String summary;
  final TweakCategory category;
  final TweakAccess access;

  /// The exact setting or command, shown to the user.
  final String changes;

  /// Honest downside.
  final String tradeoff;
  final TweakImpact impact;
  final int minSdk;

  /// False when Android forgets it on reboot (the app re-applies it once
  /// Shizuku reconnects).
  final bool persistsReboot;
}

/// A one-shot action whose result is measured on the device.
class TweakAction {
  const TweakAction({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.access,
    this.longRunning = false,
  });

  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final TweakAccess access;

  /// Takes minutes; runs in the progress sheet instead of inline.
  final bool longRunning;
}

/// Live state for one tweak, read back from the device.
class TweakState {
  const TweakState({
    this.supported = true,
    this.active = false,
    this.detail,
  });

  factory TweakState.fromMap(Map<dynamic, dynamic> map) => TweakState(
        supported: map['supported'] as bool? ?? true,
        active: map['active'] as bool? ?? false,
        detail: map['detail'] as String?,
      );

  final bool supported;
  final bool active;
  final String? detail;
}

/// What the device currently allows.
class TweakCapabilities {
  const TweakCapabilities({
    this.sdkInt = 0,
    this.manufacturer = '',
    this.shizukuReady = false,
    this.secureSettingsGranted = false,
    this.notificationPolicyGranted = false,
    this.refreshRates = const [60.0],
    this.rootAvailable = false,
    this.rootGranted = false,
    this.shizukuRoot = false,
    this.rootManager,
  });

  factory TweakCapabilities.fromMap(Map<dynamic, dynamic> map) => TweakCapabilities(
        sdkInt: map['sdkInt'] as int? ?? 0,
        manufacturer: map['manufacturer'] as String? ?? '',
        shizukuReady: map['shizukuReady'] as bool? ?? false,
        secureSettingsGranted: map['secureSettingsGranted'] as bool? ?? false,
        notificationPolicyGranted: map['notificationPolicyGranted'] as bool? ?? false,
        refreshRates:
            (map['refreshRates'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ??
                const [60.0],
        rootAvailable: map['rootAvailable'] as bool? ?? false,
        rootGranted: map['rootGranted'] as bool? ?? false,
        shizukuRoot: map['shizukuRoot'] as bool? ?? false,
        rootManager: map['rootManager'] as String?,
      );

  final int sdkInt;
  final String manufacturer;
  final bool shizukuReady;
  final bool secureSettingsGranted;
  final bool notificationPolicyGranted;
  final List<double> refreshRates;

  /// An su binary or root manager exists on the device.
  final bool rootAvailable;

  /// This app holds a root shell (manager granted it).
  final bool rootGranted;

  /// Shizuku itself runs as root (uid 0).
  final bool shizukuRoot;

  /// "Magisk", "KernelSU", "APatch"…, or null.
  final String? rootManager;

  bool get hasRoot => rootGranted || shizukuRoot;
  bool get _privShell => shizukuReady || hasRoot;

  double get maxRefreshRate =>
      refreshRates.isEmpty ? 60 : refreshRates.reduce((a, b) => a > b ? a : b);

  bool allows(TweakAccess access) => switch (access) {
        TweakAccess.none => true,
        TweakAccess.settings => _privShell || secureSettingsGranted,
        TweakAccess.shell => _privShell,
        TweakAccess.notificationPolicy => _privShell || notificationPolicyGranted,
        TweakAccess.root => hasRoot,
      };
}

/// Outcome of apply / revert / action calls.
class TweakResult {
  const TweakResult({required this.success, required this.message, this.freedBytes});

  factory TweakResult.fromMap(Map<dynamic, dynamic>? map) => TweakResult(
        success: map?['success'] as bool? ?? false,
        message: map?['message'] as String? ?? 'No response from device',
        freedBytes: (map?['freedBytes'] as num?)?.toInt(),
      );

  final bool success;
  final String message;
  final int? freedBytes;
}
