/// Stages in the 8-stage optimization execution pipeline.
enum ExecutionStage {
  /// Stage 1: Validate Android SDK bounds and parameter boundaries.
  validation('Validation'),

  /// Stage 2: Check device hardware/platform capabilities.
  capabilityCheck('Capability Check'),

  /// Stage 3: Check whether required Android or Shizuku permission is granted.
  permissionCheck('Permission Check'),

  /// Stage 4: Confirm safety against prohibited rules and system constraints.
  safetyConfirmation('Safety Confirmation'),

  /// Stage 5: Execute legitimate Android API or documented mechanism.
  execution('Execution'),

  /// Stage 6: Verify that system state reflects the desired modification.
  verification('Verification'),

  /// Stage 7: Record outcome in local audit log and state store.
  recordResult('Record Result'),

  /// Stage 8: Rollback to previous state snapshot if requested or on failure.
  rollback('Rollback');

  const ExecutionStage(this.label);
  final String label;
}

/// The recorded result of executing, verifying, or rolling back an optimization.
class OptimizationResult {
  const OptimizationResult({
    required this.optimizationId,
    required this.success,
    required this.stage,
    required this.timestamp,
    required this.message,
    this.previousState,
    this.currentState,
    this.verificationPassed = false,
    this.diagnostics = const {},
  });

  /// Factory for a successful pipeline completion.
  factory OptimizationResult.success({
    required String optimizationId,
    required String message,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? currentState,
    bool verificationPassed = true,
    Map<String, dynamic> diagnostics = const {},
  }) {
    return OptimizationResult(
      optimizationId: optimizationId,
      success: true,
      stage: ExecutionStage.recordResult,
      timestamp: DateTime.now(),
      message: message,
      previousState: previousState,
      currentState: currentState,
      verificationPassed: verificationPassed,
      diagnostics: diagnostics,
    );
  }

  /// Factory for an aborted or failed stage.
  factory OptimizationResult.failure({
    required String optimizationId,
    required ExecutionStage stage,
    required String message,
    Map<String, dynamic>? previousState,
    Map<String, dynamic> diagnostics = const {},
  }) {
    return OptimizationResult(
      optimizationId: optimizationId,
      success: false,
      stage: stage,
      timestamp: DateTime.now(),
      message: message,
      previousState: previousState,
      currentState: null,
      verificationPassed: false,
      diagnostics: diagnostics,
    );
  }

  /// Factory for a successful rollback outcome.
  factory OptimizationResult.rollbackSuccess({
    required String optimizationId,
    required String message,
    Map<String, dynamic>? restoredState,
    Map<String, dynamic> diagnostics = const {},
  }) {
    return OptimizationResult(
      optimizationId: optimizationId,
      success: true,
      stage: ExecutionStage.rollback,
      timestamp: DateTime.now(),
      message: message,
      previousState: null,
      currentState: restoredState,
      verificationPassed: true,
      diagnostics: diagnostics,
    );
  }

  /// Factory for a failed rollback.
  factory OptimizationResult.rollbackFailure({
    required String optimizationId,
    required String message,
    Map<String, dynamic> diagnostics = const {},
  }) {
    return OptimizationResult(
      optimizationId: optimizationId,
      success: false,
      stage: ExecutionStage.rollback,
      timestamp: DateTime.now(),
      message: message,
      previousState: null,
      currentState: null,
      verificationPassed: false,
      diagnostics: diagnostics,
    );
  }

  /// ID of the target optimization.
  final String optimizationId;

  /// Overall success status.
  final bool success;

  /// The execution stage where the result was finalized or failed.
  final ExecutionStage stage;

  /// Timestamp of the operation.
  final DateTime timestamp;

  /// Human-readable outcome message or failure reason.
  final String message;

  /// Captured pre-execution state for safe rollback.
  final Map<String, dynamic>? previousState;

  /// Post-execution state after applying the optimization.
  final Map<String, dynamic>? currentState;

  /// Whether the verification probe confirmed the modification took effect.
  final bool verificationPassed;

  /// Detailed technical diagnostics and telemetry.
  final Map<String, dynamic> diagnostics;

  @override
  String toString() =>
      'OptimizationResult(id: $optimizationId, success: $success, stage: ${stage.name}, verified: $verificationPassed)';
}
