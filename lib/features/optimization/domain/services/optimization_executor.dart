import '../entities/optimization_definition.dart';
import '../entities/optimization_result.dart';
import '../entities/optimization_rollback.dart';
import 'optimization_handler.dart';
import 'optimization_validator.dart';

/// Coordinates the strict 8-stage optimization execution pipeline:
///
/// 1. Validate
/// 2. Check capability
/// 3. Check permission
/// 4. Confirm safety
/// 5. Execute
/// 6. Verify
/// 7. Record result
/// 8. Provide rollback when possible
class OptimizationExecutor {
  OptimizationExecutor({
    OptimizationValidator? validator,
    OptimizationRollbackStore? rollbackStore,
    List<OptimizationResult>? historyStore,
  })  : _validator = validator ?? const OptimizationValidator(),
        _rollbackStore = rollbackStore ?? OptimizationRollbackStore(),
        _historyStore = historyStore ?? [];

  final OptimizationValidator _validator;
  final OptimizationRollbackStore _rollbackStore;
  final List<OptimizationResult> _historyStore;

  OptimizationRollbackStore get rollbackStore => _rollbackStore;
  List<OptimizationResult> get history => List.unmodifiable(_historyStore);

  /// Executes the 8-stage optimization pipeline.
  Future<OptimizationResult> execute({
    required OptimizationDefinition definition,
    required OptimizationHandler handler,
    required int currentSdkInt,
    Map<String, dynamic> parameters = const {},
  }) async {
    final effectiveParams = {
      ...definition.defaultParameters,
      ...parameters,
    };

    // ── STAGE 1: Validate ────────────────────────────────────────────────────
    final validation = _validator.validate(
      definition: definition,
      currentSdkInt: currentSdkInt,
      parameters: effectiveParams,
    );
    if (!validation.isValid) {
      final res = OptimizationResult.failure(
        optimizationId: definition.id,
        stage: ExecutionStage.validation,
        message: validation.reason ?? 'Validation failed',
        diagnostics: {'isProhibited': validation.isProhibited},
      );
      _historyStore.add(res);
      return res;
    }

    // ── STAGE 2: Check Capability ────────────────────────────────────────────
    final hasCapability = await handler.checkCapability(definition.requiredCapability);
    if (!hasCapability) {
      final res = OptimizationResult.failure(
        optimizationId: definition.id,
        stage: ExecutionStage.capabilityCheck,
        message: 'Required capability "${definition.requiredCapability.displayName}" is unavailable on this device.',
        diagnostics: {'requiredCapability': definition.requiredCapability.name},
      );
      _historyStore.add(res);
      return res;
    }

    // ── STAGE 3: Check Permission ────────────────────────────────────────────
    if (definition.requiredPermission != null) {
      final hasPermission = await handler.checkPermission(definition.requiredPermission);
      if (!hasPermission) {
        final res = OptimizationResult.failure(
          optimizationId: definition.id,
          stage: ExecutionStage.permissionCheck,
          message: 'Required permission "${definition.requiredPermission}" has not been granted.',
          diagnostics: {'requiredPermission': definition.requiredPermission},
        );
        _historyStore.add(res);
        return res;
      }
    }

    // ── STAGE 4: Confirm Safety ──────────────────────────────────────────────
    final safety = _validator.checkSafety(definition, effectiveParams);
    if (!safety.isValid) {
      final res = OptimizationResult.failure(
        optimizationId: definition.id,
        stage: ExecutionStage.safetyConfirmation,
        message: safety.reason ?? 'Safety check failed.',
        diagnostics: {'isProhibited': true},
      );
      _historyStore.add(res);
      return res;
    }

    // Capture pre-execution state snapshot before modifying anything
    Map<String, dynamic> preState = {};
    if (definition.isReversible) {
      try {
        preState = await handler.capturePreState();
      } catch (e) {
        final res = OptimizationResult.failure(
          optimizationId: definition.id,
          stage: ExecutionStage.safetyConfirmation,
          message: 'Failed to capture pre-execution snapshot: $e',
        );
        _historyStore.add(res);
        return res;
      }
    }

    // ── STAGE 5: Execute ─────────────────────────────────────────────────────
    Map<String, dynamic> executionTelemetry;
    try {
      executionTelemetry = await handler.execute(effectiveParams);
    } catch (e) {
      final res = OptimizationResult.failure(
        optimizationId: definition.id,
        stage: ExecutionStage.execution,
        message: 'Execution failed: $e',
        previousState: preState.isNotEmpty ? preState : null,
      );
      _historyStore.add(res);
      return res;
    }

    // ── STAGE 6: Verify ──────────────────────────────────────────────────────
    bool verified = false;
    try {
      verified = await handler.verify(effectiveParams);
    } catch (e) {
      verified = false;
    }

    if (!verified) {
      // If verification failed and reversible, trigger safety rollback
      if (definition.isReversible && preState.isNotEmpty) {
        try {
          await handler.rollback(preState);
        } catch (_) {}
      }

      final res = OptimizationResult.failure(
        optimizationId: definition.id,
        stage: ExecutionStage.verification,
        message: 'Verification failed: System state did not reflect changes. Reverted if applicable.',
        previousState: preState.isNotEmpty ? preState : null,
        diagnostics: executionTelemetry,
      );
      _historyStore.add(res);
      return res;
    }

    // ── STAGE 7: Record Result ───────────────────────────────────────────────
    final result = OptimizationResult.success(
      optimizationId: definition.id,
      message: 'Optimization applied and verified successfully.',
      previousState: preState.isNotEmpty ? preState : null,
      currentState: executionTelemetry,
      verificationPassed: true,
      diagnostics: {
        'verificationMethod': definition.verificationMethod.name,
        'appliedParameters': effectiveParams,
      },
    );
    _historyStore.add(result);

    // ── STAGE 8: Provide Rollback when possible ──────────────────────────────
    if (definition.isReversible && preState.isNotEmpty) {
      _rollbackStore.recordSnapshot(
        optimizationId: definition.id,
        snapshot: preState,
        appliedParameters: effectiveParams,
      );
    }

    return result;
  }

  /// Restores pre-execution state for a previously executed reversible optimization.
  Future<OptimizationResult> rollback({
    required String optimizationId,
    required OptimizationHandler handler,
  }) async {
    final rollbackItem = _rollbackStore.getSnapshot(optimizationId);
    if (rollbackItem == null) {
      return OptimizationResult.rollbackFailure(
        optimizationId: optimizationId,
        message: 'No rollback snapshot found for optimization "$optimizationId".',
      );
    }

    try {
      final success = await handler.rollback(rollbackItem.snapshot);
      if (!success) {
        return OptimizationResult.rollbackFailure(
          optimizationId: optimizationId,
          message: 'Handler returned failure when restoring previous state.',
        );
      }

      // Verify that rollback actually restored values
      final restoredVerified = await handler.verify(rollbackItem.snapshot);

      _rollbackStore.clearSnapshot(optimizationId);

      final res = OptimizationResult.rollbackSuccess(
        optimizationId: optimizationId,
        message: 'Previous state restored successfully.',
        restoredState: rollbackItem.snapshot,
        diagnostics: {'verificationPassed': restoredVerified},
      );
      _historyStore.add(res);
      return res;
    } catch (e) {
      final res = OptimizationResult.rollbackFailure(
        optimizationId: optimizationId,
        message: 'Error during rollback execution: $e',
      );
      _historyStore.add(res);
      return res;
    }
  }
}
