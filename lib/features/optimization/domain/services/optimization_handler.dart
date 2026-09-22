import '../entities/optimization_capability.dart';

/// Contract for executing and verifying an optimization on the platform.
abstract class OptimizationHandler {
  /// Probes whether the required platform/device capability is available.
  Future<bool> checkCapability(OptimizationCapability capability);

  /// Probes whether the required permission is granted.
  Future<bool> checkPermission(String? permission);

  /// Captures the current pre-execution state for safe rollback.
  /// Returns an empty map if the optimization is irreversible.
  Future<Map<String, dynamic>> capturePreState();

  /// Executes the optimization modification using legitimate Android APIs.
  /// Returns diagnostic or post-execution telemetry.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> parameters);

  /// Verifies that the modification actually took effect on the system.
  Future<bool> verify(Map<String, dynamic> parameters);

  /// Restores the pre-execution state using the captured snapshot.
  Future<bool> rollback(Map<String, dynamic> snapshot);
}
