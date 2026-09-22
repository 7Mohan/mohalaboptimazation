import '../entities/optimization_definition.dart';
import '../entities/optimization_result.dart';

/// Status of a single optimization after execution.
enum OutcomeStatus {
  /// Optimization applied and verified successfully.
  completed('Completed'),

  /// Optimization was skipped intentionally (permission missing, not in profile, etc.).
  skipped('Skipped'),

  /// Optimization is not available on this device (SDK too low, capability absent).
  unavailable('Unavailable'),

  /// Optimization attempted but failed during execution or verification.
  failed('Failed');

  const OutcomeStatus(this.label);
  final String label;
}

/// Per-optimization outcome for the result summary screen.
class OptimizationOutcome {
  const OptimizationOutcome({
    required this.definition,
    required this.status,
    required this.userFriendlyReason,
    this.hasRollback = false,
    this.rawResult,
  });

  final OptimizationDefinition definition;
  final OutcomeStatus status;

  /// Plain-English explanation of why this outcome occurred.
  final String userFriendlyReason;

  /// True when a rollback snapshot was recorded and can be used.
  final bool hasRollback;

  /// The raw technical result from the executor (available when executed).
  final OptimizationResult? rawResult;

  bool get isSuccess => status == OutcomeStatus.completed;
  bool get didExecute =>
      status == OutcomeStatus.completed || status == OutcomeStatus.failed;
}
