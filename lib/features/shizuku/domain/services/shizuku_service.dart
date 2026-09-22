import '../entities/shizuku_status.dart';

/// Contract for the Shizuku service layer.
///
/// The Flutter layer communicates with Android exclusively through this
/// interface. No Shizuku implementation details (channels, package names,
/// binder codes) may leak above this boundary.
///
/// Implementations:
///   [ShizukuServiceImpl]  — real MethodChannel implementation
///   [ShizukuMockService]  — in-memory stub for tests
abstract interface class ShizukuService {
  /// Returns the current Shizuku state.
  ///
  /// Never throws — returns [ShizukuStatus.notInstalled] on any unrecoverable error.
  Future<ShizukuStatus> getStatus();

  /// Returns true if Shizuku permission is currently granted.
  ///
  /// This is a lightweight check — it does not confirm the binder is alive.
  /// Use [isReady] for a full readiness check.
  Future<bool> checkPermission();

  /// Returns true only if Shizuku is fully ready for privileged operations:
  /// binder alive, permission granted, service confirmed.
  Future<bool> isReady();

  /// Requests the Shizuku USE_SERVICE permission from the user.
  ///
  /// Returns true if permission was granted, false if denied or unavailable.
  /// Safe to call even if permission is already granted (resolves immediately).
  Future<bool> requestPermission();

  /// Executes a shell command with Shizuku privileges.
  /// Returns a map containing: success, exitCode, stdout, and stderr.
  Future<Map<String, dynamic>> execShellCommand(String command);
}
