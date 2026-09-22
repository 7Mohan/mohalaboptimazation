import '../../../games/domain/entities/game_profile_entity.dart';
import '../../../shizuku/domain/entities/shizuku_status.dart';
import '../entities/optimization_capability.dart';
import '../entities/optimization_definition.dart';
import '../entities/optimization_outcome.dart';
import '../entities/optimization_result.dart';
import '../entities/pre_flight_report.dart';
import '../registry/optimization_registry.dart';
import '../services/optimization_executor.dart';

/// Contract for supplying live device state to the workflow service.
abstract interface class DeviceInfoSource {
  Future<int> getAndroidSdkInt();
  Future<ShizukuStatus> getShizukuStatus();
  Future<bool> hasDndPermission();
  Future<bool> hasWriteSecureSettings();
  Future<int> getBatteryPercent();
  Future<int> getThermalStatusCode();
  Future<bool> isCharging();
}

/// Orchestrates the full 7-step optimization workflow.
///
/// Responsibilities:
/// - Runs pre-flight device checks.
/// - Filters the registry to optimizations compatible with the current device,
///   profile, and permission state.
/// - Maps raw [OptimizationResult]s to gamer-friendly [OptimizationOutcome]s.
/// - Exposes rollback for reversible applied optimizations.
class OptimizationWorkflowService {
  OptimizationWorkflowService({
    required this.registry,
    required this.executor,
    required this.deviceInfo,
  });

  final OptimizationRegistry registry;
  final OptimizationExecutor executor;
  final DeviceInfoSource deviceInfo;

  // ── Pre-flight ────────────────────────────────────────────────────────────

  /// Runs all pre-flight checks and returns an aggregated [PreFlightReport].
  Future<PreFlightReport> runPreFlight({String? gamePackage}) async {
    final sdk = await deviceInfo.getAndroidSdkInt();
    final shizuku = await deviceInfo.getShizukuStatus();
    final hasDnd = await deviceInfo.hasDndPermission();
    final hasSecure = await deviceInfo.hasWriteSecureSettings();
    final battery = await deviceInfo.getBatteryPercent();
    final thermal = await deviceInfo.getThermalStatusCode();
    final charging = await deviceInfo.isCharging();

    final issues = <PreFlightIssue>[];

    // Thermal critical blocker
    if (thermal >= 4) {
      issues.add(const PreFlightIssue(
        id: 'thermal_critical',
        title: 'Device Overheating',
        detail:
            'Your device is running at a critical temperature. Applying optimizations '
            'while overheating may worsen performance. Let the device cool down first.',
        severity: PreFlightSeverity.blocker,
      ));
    } else if (thermal >= 2) {
      issues.add(const PreFlightIssue(
        id: 'thermal_warm',
        title: 'Device Is Warm',
        detail:
            'Your device temperature is elevated. Optimizations will still apply, '
            'but results may be limited by thermal throttling.',
        severity: PreFlightSeverity.warning,
      ));
    }

    // Battery low blocker
    if (battery < 15 && !charging) {
      issues.add(PreFlightIssue(
        id: 'battery_critical',
        title: 'Battery Low ($battery%)',
        detail:
            'Running optimizations on very low battery may be interrupted. '
            'Plug in your charger or charge to at least 15% first.',
        severity: PreFlightSeverity.blocker,
      ));
    } else if (battery < 30 && !charging) {
      issues.add(PreFlightIssue(
        id: 'battery_low',
        title: 'Battery Below 30% ($battery%)',
        detail:
            'You can proceed, but some display or performance optimizations may '
            'increase power draw during your session.',
        severity: PreFlightSeverity.warning,
      ));
    }

    // Shizuku advisory (non-blocking; some optimizations simply won't run)
    if (!shizuku.isReady) {
      final hasShizukuOpts = registry
          .getAll()
          .any((d) => d.requiredCapability == OptimizationCapability.shizukuPrivileged);
      if (hasShizukuOpts) {
        issues.add(PreFlightIssue(
          id: 'shizuku_unavailable',
          title: 'Advanced Features Unavailable',
          detail:
              'Shizuku is not ready (${shizuku.shortLabel}). Some optimizations '
              'that require elevated access will be skipped. Basic ones still apply.',
          severity: PreFlightSeverity.warning,
          fixAction: shizuku.isActionable ? 'Set Up Shizuku' : null,
        ));
      }
    }

    // DND permission advisory
    if (!hasDnd) {
      issues.add(const PreFlightIssue(
        id: 'dnd_permission_missing',
        title: 'Do Not Disturb Permission Not Granted',
        detail:
            'The "Gaming Do Not Disturb" optimization will be skipped. '
            'Grant notification policy access in Settings to enable it.',
        severity: PreFlightSeverity.warning,
        fixAction: 'Open Settings',
      ));
    }

    // WRITE_SECURE_SETTINGS advisory
    if (!hasSecure) {
      issues.add(const PreFlightIssue(
        id: 'secure_settings_missing',
        title: 'Display Tuning Unavailable',
        detail:
            'Animation scale and refresh rate tuning require WRITE_SECURE_SETTINGS, '
            'which needs Shizuku or ADB. These optimizations will be skipped.',
        severity: PreFlightSeverity.warning,
      ));
    }

    return PreFlightReport(
      androidSdkInt: sdk,
      shizukuStatus: shizuku,
      hasDndPermission: hasDnd,
      hasWriteSecureSettings: hasSecure,
      batteryPercent: battery,
      thermalStatusCode: thermal,
      isCharging: charging,
      gamePackage: gamePackage,
      issues: issues,
    );
  }

  // ── Proposal Resolution ───────────────────────────────────────────────────

  /// Resolves which optimizations to run vs skip, based on the pre-flight report
  /// and the enabled categories in the game profile.
  ///
  /// Returns two lists:
  ///   - `toRun`: optimization IDs that should be executed
  ///   - `preResolved`: outcomes already determined without running the executor
  ({List<String> toRun, List<OptimizationOutcome> preResolved})
      resolveProposals({
    required PreFlightReport report,
    required GameProfile profile,
  }) {
    final toRun = <String>[];
    final preResolved = <OptimizationOutcome>[];

    for (final def in registry.getAll()) {
      // SDK too low → unavailable
      if (report.androidSdkInt < def.minAndroidSdk) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.unavailable,
          userFriendlyReason:
              'Your Android version (API ${report.androidSdkInt}) is below the '
              'minimum required (API ${def.minAndroidSdk}) for this optimization.',
        ));
        continue;
      }

      // SDK too high (deprecated API)
      if (def.maxAndroidSdk != null &&
          report.androidSdkInt > def.maxAndroidSdk!) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.unavailable,
          userFriendlyReason:
              'This optimization was discontinued in newer Android versions '
              '(your device runs API ${report.androidSdkInt}).',
        ));
        continue;
      }

      // Needs Shizuku but it's not ready
      if (def.requiredCapability ==
              OptimizationCapability.shizukuPrivileged &&
          !report.shizukuStatus.isReady) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.skipped,
          userFriendlyReason:
              'Requires Shizuku (currently: ${report.shizukuStatus.shortLabel}). '
              'Set up Shizuku to enable this feature.',
        ));
        continue;
      }

      // DND permission missing
      if (def.requiredPermission ==
              'android.permission.ACCESS_NOTIFICATION_POLICY' &&
          !report.hasDndPermission) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.skipped,
          userFriendlyReason:
              'Do Not Disturb permission was not granted. '
              'Grant it in Settings → Apps → Special App Access.',
        ));
        continue;
      }

      // WRITE_SECURE_SETTINGS missing
      if (def.requiredPermission ==
              'android.permission.WRITE_SECURE_SETTINGS' &&
          !report.hasWriteSecureSettings) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.skipped,
          userFriendlyReason:
              'System settings write access requires Shizuku or ADB. '
              'Enable Shizuku to unlock this optimization.',
        ));
        continue;
      }

      // Category not enabled in profile
      final categoryEnabled = _isCategoryEnabled(def, profile);
      if (!categoryEnabled) {
        preResolved.add(OptimizationOutcome(
          definition: def,
          status: OutcomeStatus.skipped,
          userFriendlyReason:
              'This optimization belongs to the "${def.category.label}" category, '
              'which is not enabled in your game profile.',
        ));
        continue;
      }

      // All checks passed — schedule for execution
      toRun.add(def.id);
    }

    return (toRun: toRun, preResolved: preResolved);
  }

  bool _isCategoryEnabled(OptimizationDefinition def, GameProfile profile) {
    // Map OptimizationCategory from optimization to profile's OptimizationCategory
    return switch (def.category) {
      OptimizationCategory.performance =>
        profile.enabledCategories.contains(OptimizationCategory.performance),
      OptimizationCategory.display =>
        profile.enabledCategories.contains(OptimizationCategory.display),
      OptimizationCategory.battery =>
        profile.enabledCategories.contains(OptimizationCategory.battery),
      OptimizationCategory.network =>
        profile.enabledCategories.contains(OptimizationCategory.network),
      OptimizationCategory.touch =>
        profile.enabledCategories.contains(OptimizationCategory.touch),
    };
  }

  // ── Execution ─────────────────────────────────────────────────────────────

  /// Executes a list of optimization IDs, emitting progress updates via
  /// [onProgress] after each individual optimization completes.
  Future<List<OptimizationOutcome>> executeAll({
    required List<String> ids,
    required int sdkInt,
    required void Function(OptimizationOutcome completed) onProgress,
  }) async {
    final outcomes = <OptimizationOutcome>[];

    for (final id in ids) {
      final def = registry.getDefinition(id);
      final handler = registry.getHandler(id);

      if (def == null || handler == null) {
        final outcome = OptimizationOutcome(
          definition: OptimizationDefinition(
            id: id,
            name: id,
            description: '',
            category: OptimizationCategory.performance,
            requiredCapability: OptimizationCapability.standardAndroid,
            riskLevel: OptimizationRiskLevel.none,
            minAndroidSdk: 26,
            isReversible: false,
            verificationMethod: VerificationMethod.custom,
            whatWillChange: '',
            whyItHelps: '',
            whatRiskExists: '',
          ),
          status: OutcomeStatus.failed,
          userFriendlyReason:
              'Internal error: optimization handler not found.',
        );
        outcomes.add(outcome);
        onProgress(outcome);
        continue;
      }

      final result = await executor.execute(
        definition: def,
        handler: handler,
        currentSdkInt: sdkInt,
      );

      final hasSnap = executor.rollbackStore.hasSnapshot(id);

      final outcome = _toOutcome(def, result, hasSnap);
      outcomes.add(outcome);
      onProgress(outcome);
    }

    return outcomes;
  }

  /// Rolls back all reversible applied optimizations that have snapshots.
  Future<List<OptimizationOutcome>> rollbackAll({
    required List<String> ids,
  }) async {
    final outcomes = <OptimizationOutcome>[];
    for (final id in ids) {
      if (!executor.rollbackStore.hasSnapshot(id)) continue;
      final def = registry.getDefinition(id);
      final handler = registry.getHandler(id);
      if (def == null || handler == null) continue;

      final result = await executor.rollback(
        optimizationId: id,
        handler: handler,
      );
      outcomes.add(_toOutcome(def, result, false));
    }
    return outcomes;
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  OptimizationOutcome _toOutcome(
    OptimizationDefinition def,
    OptimizationResult result,
    bool hasRollback,
  ) {
    if (result.success) {
      return OptimizationOutcome(
        definition: def,
        status: OutcomeStatus.completed,
        userFriendlyReason: 'Applied and verified successfully.',
        hasRollback: hasRollback && def.isReversible,
        rawResult: result,
      );
    }

    // Map execution stage to a plain-English reason
    final reason = switch (result.stage) {
      ExecutionStage.validation =>
        'This optimization is not compatible with your device configuration.',
      ExecutionStage.capabilityCheck =>
        'Your device does not support the required system capability.',
      ExecutionStage.permissionCheck =>
        'A required permission was not granted. Check your app permissions.',
      ExecutionStage.safetyConfirmation =>
        'Safety check blocked this optimization. No changes were made.',
      ExecutionStage.execution =>
        'The optimization could not be applied. The system may have rejected it.',
      ExecutionStage.verification =>
        'Applied, but could not confirm the change took effect. Reverted if possible.',
      ExecutionStage.recordResult => 'An unexpected error occurred.',
      ExecutionStage.rollback => 'Rollback completed.',
    };

    return OptimizationOutcome(
      definition: def,
      status: OutcomeStatus.failed,
      userFriendlyReason: reason,
      hasRollback: false,
      rawResult: result,
    );
  }
}
