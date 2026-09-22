/// Represents a captured pre-execution state snapshot that can be rolled back.
class OptimizationRollback {
  const OptimizationRollback({
    required this.optimizationId,
    required this.timestamp,
    required this.snapshot,
    required this.appliedParameters,
  });

  /// The ID of the optimization this rollback snapshot belongs to.
  final String optimizationId;

  /// Timestamp when the pre-execution snapshot was captured.
  final DateTime timestamp;

  /// Exact previous state parameters before execution.
  final Map<String, dynamic> snapshot;

  /// The parameters that were applied during execution.
  final Map<String, dynamic> appliedParameters;

  @override
  String toString() =>
      'OptimizationRollback(id: $optimizationId, at: $timestamp, keys: ${snapshot.keys.join(",")})';
}

/// In-memory store and manager for active rollback snapshots.
class OptimizationRollbackStore {
  final Map<String, OptimizationRollback> _snapshots = {};

  /// Stores a pre-execution rollback snapshot.
  void recordSnapshot({
    required String optimizationId,
    required Map<String, dynamic> snapshot,
    Map<String, dynamic> appliedParameters = const {},
  }) {
    _snapshots[optimizationId] = OptimizationRollback(
      optimizationId: optimizationId,
      timestamp: DateTime.now(),
      snapshot: Map.unmodifiable(snapshot),
      appliedParameters: Map.unmodifiable(appliedParameters),
    );
  }

  /// Retrieves the active rollback snapshot for an optimization, or null if none exists.
  OptimizationRollback? getSnapshot(String optimizationId) => _snapshots[optimizationId];

  /// Checks if a rollback snapshot exists for this optimization.
  bool hasSnapshot(String optimizationId) => _snapshots.containsKey(optimizationId);

  /// Clears the rollback snapshot once rolled back or discarded.
  void clearSnapshot(String optimizationId) {
    _snapshots.remove(optimizationId);
  }

  /// All active rollback snapshots.
  List<OptimizationRollback> get activeRollbacks => _snapshots.values.toList();
}
