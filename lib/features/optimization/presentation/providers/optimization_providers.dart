import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/handlers/standard_optimization_handlers.dart';
import '../../data/services/optimization_native_bridge.dart';
import '../../domain/entities/optimization_definition.dart';
import '../../domain/entities/optimization_profile.dart';
import '../../domain/entities/optimization_result.dart';
import '../../domain/registry/optimization_registry.dart';
import '../../domain/services/optimization_executor.dart';
import '../../domain/services/optimization_validator.dart';

/// Currently selected global optimization profile.
final selectedProfileProvider =
    StateProvider<OptimizationProfile>((ref) => OptimizationProfile.balanced);

/// Provider for the native Android bridge (overridable in tests).
final optimizationBridgeProvider = Provider<OptimizationNativeBridge>((ref) {
  return const OptimizationNativeBridge();
});

/// Provider for the optimization validator.
final optimizationValidatorProvider = Provider<OptimizationValidator>((ref) {
  return const OptimizationValidator();
});

/// Provider for the global OptimizationRegistry, populated with handlers.
final optimizationRegistryProvider = Provider<OptimizationRegistry>((ref) {
  final bridge = ref.watch(optimizationBridgeProvider);
  final validator = ref.watch(optimizationValidatorProvider);
  final registry = OptimizationRegistry(validator: validator);

  // Bind concrete handlers to built-in optimizations
  registry.registerHandler(
    OptimizationRegistry.ramTrimCaches.id,
    RamTrimOptimizationHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.windowAnimationScale.id,
    WindowAnimationScaleHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.gamingDndZen.id,
    GamingDndHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.peakRefreshRate.id,
    PeakRefreshRateHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.fixedPerformanceMode.id,
    FixedPerformanceHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.touchLatencyTweak.id,
    TouchLatencyHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.disableWindowBlurs.id,
    DisableBlursHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.tcpNetworkBuffer.id,
    TcpBufferHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.gpuVsyncBoost.id,
    GpuVsyncHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.deepRamClean.id,
    DeepRamCleanHandler(bridge),
  );
  registry.registerHandler(
    OptimizationRegistry.bypassFpsPipeline.id,
    BypassFpsPipelineHandler(bridge),
  );

  return registry;
});

/// Provider for the OptimizationExecutor.
final optimizationExecutorProvider = Provider<OptimizationExecutor>((ref) {
  final validator = ref.watch(optimizationValidatorProvider);
  return OptimizationExecutor(validator: validator);
});

/// State of the optimization controller.
class OptimizationControllerState {
  const OptimizationControllerState({
    this.isBusy = false,
    this.executingOptimizationId,
    this.currentStage,
    this.lastResult,
    this.appliedOptimizationIds = const {},
  });

  final bool isBusy;
  final String? executingOptimizationId;
  final ExecutionStage? currentStage;
  final OptimizationResult? lastResult;
  final Set<String> appliedOptimizationIds;

  OptimizationControllerState copyWith({
    bool? isBusy,
    String? executingOptimizationId,
    ExecutionStage? currentStage,
    OptimizationResult? lastResult,
    Set<String>? appliedOptimizationIds,
  }) {
    return OptimizationControllerState(
      isBusy: isBusy ?? this.isBusy,
      executingOptimizationId: executingOptimizationId,
      currentStage: currentStage,
      lastResult: lastResult ?? this.lastResult,
      appliedOptimizationIds: appliedOptimizationIds ?? this.appliedOptimizationIds,
    );
  }
}

/// Notifier managing optimization execution and rollback UX state.
class OptimizationController extends StateNotifier<OptimizationControllerState> {
  OptimizationController(this.ref) : super(const OptimizationControllerState());

  final Ref ref;

  /// Executes an optimization by ID using the 8-stage pipeline.
  Future<OptimizationResult> executeOptimization({
    required String id,
    int deviceSdkInt = 34,
    Map<String, dynamic> parameters = const {},
  }) async {
    final registry = ref.read(optimizationRegistryProvider);
    final executor = ref.read(optimizationExecutorProvider);

    final definition = registry.getDefinition(id);
    if (definition == null) {
      final res = OptimizationResult.failure(
        optimizationId: id,
        stage: ExecutionStage.validation,
        message: 'Unknown optimization ID: $id',
      );
      state = state.copyWith(lastResult: res);
      return res;
    }

    final handler = registry.getHandler(id);
    if (handler == null) {
      final res = OptimizationResult.failure(
        optimizationId: id,
        stage: ExecutionStage.capabilityCheck,
        message: 'No handler registered for optimization: $id',
      );
      state = state.copyWith(lastResult: res);
      return res;
    }

    state = state.copyWith(
      isBusy: true,
      executingOptimizationId: id,
      currentStage: ExecutionStage.validation,
    );

    final result = await executor.execute(
      definition: definition,
      handler: handler,
      currentSdkInt: deviceSdkInt,
      parameters: parameters,
    );

    final updatedApplied = Set<String>.from(state.appliedOptimizationIds);
    if (result.success && definition.isReversible) {
      updatedApplied.add(id);
    }

    state = state.copyWith(
      isBusy: false,
      executingOptimizationId: null,
      currentStage: null,
      lastResult: result,
      appliedOptimizationIds: updatedApplied,
    );

    return result;
  }

  /// Applies all safe (zero risk) optimizations sequentially.
  Future<List<OptimizationResult>> applyAllSafe({int deviceSdkInt = 34}) async {
    final registry = ref.read(optimizationRegistryProvider);
    final allDefs = registry.getAll();
    final safeDefs = allDefs
        .where((d) => d.riskLevel == OptimizationRiskLevel.none)
        .toList();

    final results = <OptimizationResult>[];
    for (final def in safeDefs) {
      final res = await executeOptimization(
        id: def.id,
        deviceSdkInt: deviceSdkInt,
      );
      results.add(res);
    }
    return results;
  }

  /// Applies optimizations matching the given [profile]'s filter.
  Future<List<OptimizationResult>> applyProfile({
    required OptimizationProfile profile,
    int deviceSdkInt = 34,
  }) async {
    final registry = ref.read(optimizationRegistryProvider);
    final allDefs = registry.getAll();
    final filtered = allDefs.where((d) => profile.shouldApply(d)).toList();

    final results = <OptimizationResult>[];
    for (final def in filtered) {
      final res = await executeOptimization(
        id: def.id,
        deviceSdkInt: deviceSdkInt,
      );
      results.add(res);
    }
    return results;
  }

  /// Rolls back a previously applied optimization.
  Future<OptimizationResult> rollbackOptimization(String id) async {
    final registry = ref.read(optimizationRegistryProvider);
    final executor = ref.read(optimizationExecutorProvider);

    final handler = registry.getHandler(id);
    if (handler == null) {
      final res = OptimizationResult.rollbackFailure(
        optimizationId: id,
        message: 'No handler found for rollback: $id',
      );
      state = state.copyWith(lastResult: res);
      return res;
    }

    state = state.copyWith(
      isBusy: true,
      executingOptimizationId: id,
      currentStage: ExecutionStage.rollback,
    );

    final result = await executor.rollback(
      optimizationId: id,
      handler: handler,
    );

    final updatedApplied = Set<String>.from(state.appliedOptimizationIds);
    if (result.success) {
      updatedApplied.remove(id);
    }

    state = state.copyWith(
      isBusy: false,
      executingOptimizationId: null,
      currentStage: null,
      lastResult: result,
      appliedOptimizationIds: updatedApplied,
    );

    return result;
  }
}

final optimizationControllerProvider =
    StateNotifierProvider<OptimizationController, OptimizationControllerState>((ref) {
  return OptimizationController(ref);
});
