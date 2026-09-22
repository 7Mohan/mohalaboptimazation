import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/games/domain/entities/game_profile_entity.dart';
import 'package:mohalab_optimization/features/optimization/data/handlers/standard_optimization_handlers.dart';
import 'package:mohalab_optimization/features/optimization/data/services/optimization_mock_bridge.dart';
import 'package:mohalab_optimization/features/optimization/domain/entities/optimization_capability.dart';
import 'package:mohalab_optimization/features/optimization/domain/entities/optimization_definition.dart';
import 'package:mohalab_optimization/features/optimization/domain/entities/optimization_result.dart';
import 'package:mohalab_optimization/features/optimization/domain/registry/optimization_registry.dart';
import 'package:mohalab_optimization/features/optimization/domain/services/optimization_executor.dart';
import 'package:mohalab_optimization/features/optimization/domain/services/optimization_validator.dart';
import 'package:mohalab_optimization/features/optimization/presentation/providers/optimization_providers.dart';
import 'package:mohalab_optimization/features/optimization/presentation/screens/optimization_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OptimizationDefinition & Transparency Wording', () {
    test('All built-in definitions have complete transparency metadata', () {
      final registry = OptimizationRegistry();
      for (final def in registry.getAll()) {
        expect(def.id.isNotEmpty, isTrue);
        expect(def.name.isNotEmpty, isTrue);
        expect(def.description.isNotEmpty, isTrue);
        expect(def.whatWillChange.isNotEmpty, isTrue);
        expect(def.whyItHelps.isNotEmpty, isTrue);
        expect(def.whatRiskExists.isNotEmpty, isTrue);
        expect(def.minAndroidSdk, greaterThanOrEqualTo(21));

        // Ensure non-misleading wording: NO false FPS or cheating promises
        final combinedText = '${def.name} ${def.description} ${def.whyItHelps}'.toLowerCase();
        expect(combinedText.contains('boosts fps by'), isFalse);
        expect(combinedText.contains('fake fps'), isFalse);
        expect(combinedText.contains('cheat'), isFalse);
      }
    });
  });

  group('OptimizationValidator & Prohibited Operations', () {
    const validator = OptimizationValidator();

    test('Passes valid safe optimization within SDK bounds', () {
      final report = validator.validate(
        definition: OptimizationRegistry.ramTrimCaches,
        currentSdkInt: 33,
      );
      expect(report.isValid, isTrue);
      expect(report.isProhibited, isFalse);
    });

    test('Rejects optimization when device SDK is below minAndroidSdk', () {
      final report = validator.validate(
        definition: OptimizationRegistry.ramTrimCaches,
        currentSdkInt: 21, // requires 26
      );
      expect(report.isValid, isFalse);
      expect(report.reason, contains('Requires Android SDK 26 or higher'));
    });

    test('Rejects high-risk optimizations', () {
      const highRiskDef = OptimizationDefinition(
        id: 'dangerous_tweak',
        name: 'Dangerous Tweak',
        description: 'Potentially destabilizing',
        category: OptimizationCategory.performance,
        requiredCapability: OptimizationCapability.standardAndroid,
        riskLevel: OptimizationRiskLevel.high,
        minAndroidSdk: 26,
        isReversible: false,
        verificationMethod: VerificationMethod.custom,
        whatWillChange: 'Core files',
        whyItHelps: 'None',
        whatRiskExists: 'Instability',
      );
      final report = validator.validate(
        definition: highRiskDef,
        currentSdkInt: 30,
      );
      expect(report.isValid, isFalse);
      expect(report.isProhibited, isTrue);
    });

    test('Strictly rejects prohibited keywords (CPU spoofing, fake FPS, thermal disabling)', () {
      const prohibitedDef = OptimizationDefinition(
        id: 'spoof_cpu_clock',
        name: 'CPU Frequency Spoof',
        description: 'Spoofs governor frequencies for benchmarks',
        category: OptimizationCategory.performance,
        requiredCapability: OptimizationCapability.standardAndroid,
        riskLevel: OptimizationRiskLevel.medium,
        minAndroidSdk: 26,
        isReversible: false,
        verificationMethod: VerificationMethod.custom,
        whatWillChange: 'Fakes clock values',
        whyItHelps: 'Manipulates benchmarks',
        whatRiskExists: 'Cheating',
      );

      final report = validator.checkSafety(prohibitedDef);
      expect(report.isValid, isFalse);
      expect(report.isProhibited, isTrue);
      expect(report.reason, contains('Security policy violation'));
    });

    test('Rejects arbitrary shell execution in parameters', () {
      final report = validator.checkSafety(
        OptimizationRegistry.windowAnimationScale,
        {'cmd': 'rm -rf /data/system'},
      );
      expect(report.isValid, isFalse);
      expect(report.isProhibited, isTrue);
    });

    test('Validates parameter boundaries for window animation scales', () {
      final valid = validator.validateParameters(
        'window_animation_scale',
        {'scale': 0.5},
      );
      expect(valid.isValid, isTrue);

      final invalid = validator.validateParameters(
        'window_animation_scale',
        {'scale': 3.5},
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.reason, contains('between 0.0 and 2.0'));
    });
  });

  group('OptimizationExecutor 8-Stage Pipeline & Rollback', () {
    late OptimizationMockBridge mockBridge;
    late OptimizationExecutor executor;
    late WindowAnimationScaleHandler handler;

    setUp(() {
      mockBridge = OptimizationMockBridge();
      executor = OptimizationExecutor();
      handler = WindowAnimationScaleHandler(mockBridge);
    });

    test('Full happy path: executes all 8 stages, verifies, and records rollback snapshot', () async {
      final result = await executor.execute(
        definition: OptimizationRegistry.windowAnimationScale,
        handler: handler,
        currentSdkInt: 33,
        parameters: {'scale': 0.5},
      );

      expect(result.success, isTrue);
      expect(result.stage, equals(ExecutionStage.recordResult));
      expect(result.verificationPassed, isTrue);
      expect(result.previousState, isNotNull);
      expect(result.previousState!['window'], equals(1.0));

      // Check that rollback snapshot is stored
      expect(executor.rollbackStore.hasSnapshot('window_animation_scale'), isTrue);

      // Verify actual bridge state
      expect(mockBridge.animationScales['window'], equals(0.5));
    });

    test('Capability failure aborts at Stage 2', () async {
      // Handler where capability check returns false
      final noCapHandler = WindowAnimationScaleHandler(mockBridge);
      final result = await executor.execute(
        definition: const OptimizationDefinition(
          id: 'test_cap',
          name: 'Test Cap',
          description: 'Test',
          category: OptimizationCategory.performance,
          requiredCapability: OptimizationCapability.powerManagerHints, // unsupported
          riskLevel: OptimizationRiskLevel.none,
          minAndroidSdk: 26,
          isReversible: false,
          verificationMethod: VerificationMethod.custom,
          whatWillChange: 'none',
          whyItHelps: 'none',
          whatRiskExists: 'none',
        ),
        handler: noCapHandler,
        currentSdkInt: 33,
      );

      expect(result.success, isFalse);
      expect(result.stage, equals(ExecutionStage.capabilityCheck));
    });

    test('Permission failure aborts at Stage 3', () async {
      handler.permissionGranted = false;

      final result = await executor.execute(
        definition: OptimizationRegistry.windowAnimationScale,
        handler: handler,
        currentSdkInt: 33,
      );

      expect(result.success, isFalse);
      expect(result.stage, equals(ExecutionStage.permissionCheck));
    });

    test('Rollback restores exact previous snapshot and verifies restoration', () async {
      // 1. Apply optimization
      await executor.execute(
        definition: OptimizationRegistry.windowAnimationScale,
        handler: handler,
        currentSdkInt: 33,
        parameters: {'scale': 0.0},
      );
      expect(mockBridge.animationScales['window'], equals(0.0));

      // 2. Rollback
      final rollbackRes = await executor.rollback(
        optimizationId: 'window_animation_scale',
        handler: handler,
      );

      expect(rollbackRes.success, isTrue);
      expect(rollbackRes.stage, equals(ExecutionStage.rollback));
      expect(mockBridge.animationScales['window'], equals(1.0));
      expect(executor.rollbackStore.hasSnapshot('window_animation_scale'), isFalse);
    });

    test('Rollback fails cleanly when no snapshot exists', () async {
      final res = await executor.rollback(
        optimizationId: 'non_existent_id',
        handler: handler,
      );
      expect(res.success, isFalse);
      expect(res.message, contains('No rollback snapshot found'));
    });
  });

  group('OptimizationRegistry & Handlers', () {
    test('Registry contains all 4 built-in safe optimizations', () {
      final registry = OptimizationRegistry();
      expect(registry.getDefinition('ram_trim_caches'), isNotNull);
      expect(registry.getDefinition('window_animation_scale'), isNotNull);
      expect(registry.getDefinition('gaming_dnd_zen'), isNotNull);
      expect(registry.getDefinition('peak_refresh_rate'), isNotNull);
    });

    test('RAM trim handler runs and does not support rollback', () async {
      final mockBridge = OptimizationMockBridge();
      final handler = RamTrimOptimizationHandler(mockBridge);

      final preState = await handler.capturePreState();
      expect(preState.isEmpty, isTrue);

      final exec = await handler.execute({});
      expect(exec['trimmed'], isTrue);

      final canRollback = await handler.rollback({});
      expect(canRollback, isFalse);
    });

    test('Gaming DND handler captures filter and restores on rollback', () async {
      final mockBridge = OptimizationMockBridge();
      final handler = GamingDndHandler(mockBridge);

      mockBridge.dndFilter = 1;
      final pre = await handler.capturePreState();
      expect(pre['filter'], equals(1));

      await handler.execute({});
      expect(mockBridge.dndFilter, equals(2));

      await handler.rollback(pre);
      expect(mockBridge.dndFilter, equals(1));
    });

    test('Peak refresh rate handler locks to peak and restores on rollback', () async {
      final mockBridge = OptimizationMockBridge();
      final handler = PeakRefreshRateHandler(mockBridge);

      mockBridge.refreshRates = {'min': 60.0, 'peak': 144.0};
      final pre = await handler.capturePreState();
      expect(pre['min'], equals(60.0));

      await handler.execute({'targetRefreshRate': 144.0});
      expect(mockBridge.refreshRates['min'], equals(144.0));

      await handler.rollback(pre);
      expect(mockBridge.refreshRates['min'], equals(60.0));
    });
  });

  group('OptimizationCard & Screen Widget Tests', () {
    late OptimizationMockBridge mockBridge;

    setUp(() {
      mockBridge = OptimizationMockBridge();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          optimizationBridgeProvider.overrideWithValue(mockBridge),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const OptimizationScreen(),
        ),
      );
    }

    testWidgets('Renders all safe optimization cards with risk badges and disclosures', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Safe Optimization Tools'), findsOneWidget);
      expect(find.text('Trim Background Application Caches'), findsOneWidget);
      expect(find.text('Window Animation Scale Tuner'), findsOneWidget);
      expect(find.text('Gaming Do Not Disturb'), findsOneWidget);
      expect(find.text('Lock Peak Display Refresh Rate'), findsOneWidget);

      expect(find.text('No Risk'), findsNWidgets(2));
      expect(find.text('Low Risk'), findsNWidgets(2));
    });

    testWidgets('Tapping Apply on reversible optimization switches button to Rollback', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final applyButton = find.byKey(const Key('apply_window_animation_scale'));
      expect(applyButton, findsOneWidget);

      await tester.ensureVisible(applyButton);
      await tester.pumpAndSettle();
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // After successful execution, the button transforms into Rollback
      final rollbackButton = find.byKey(const Key('rollback_window_animation_scale'));
      expect(rollbackButton, findsOneWidget);

      // Tap Rollback
      await tester.ensureVisible(rollbackButton);
      await tester.pumpAndSettle();
      await tester.tap(rollbackButton);
      await tester.pumpAndSettle();

      // Back to Apply
      expect(find.byKey(const Key('apply_window_animation_scale')), findsOneWidget);
    });

    testWidgets('Tapping Disclosures opens transparent bottom sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final disclosureButtons = find.text('Disclosures');
      expect(disclosureButtons, findsWidgets);

      await tester.ensureVisible(disclosureButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(disclosureButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Why It May Help'), findsOneWidget);
      expect(find.text('What Will Change'), findsOneWidget);
      expect(find.text('What Risk Exists'), findsOneWidget);
      expect(find.text('Rollback & Reversibility'), findsOneWidget);
    });
  });
}
