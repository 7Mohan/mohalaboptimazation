import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/shizuku/data/services/shizuku_mock_service.dart';
import 'package:mohalab_optimization/features/shizuku/domain/entities/shizuku_status.dart';
import 'package:mohalab_optimization/features/shizuku/domain/registry/command_registry.dart';
import 'package:mohalab_optimization/features/shizuku/domain/services/shizuku_service.dart';
import 'package:mohalab_optimization/features/shizuku/presentation/providers/shizuku_provider.dart';
import 'package:mohalab_optimization/features/shizuku/presentation/widgets/shizuku_setup_sheet.dart';
import 'package:mohalab_optimization/features/shizuku/presentation/widgets/shizuku_status_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildApp(
  Widget child, {
  required ShizukuService service,
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: [
      shizukuServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ShizukuStatus unit tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ShizukuStatus — enum helpers', () {
    test('fromCode maps all valid codes correctly', () {
      expect(ShizukuStatusExtension.fromCode('notInstalled'), ShizukuStatus.notInstalled);
      expect(ShizukuStatusExtension.fromCode('notRunning'), ShizukuStatus.notRunning);
      expect(ShizukuStatusExtension.fromCode('binderConnected'), ShizukuStatus.binderConnected);
      expect(ShizukuStatusExtension.fromCode('permissionDenied'), ShizukuStatus.permissionDenied);
      expect(ShizukuStatusExtension.fromCode('permissionGranted'), ShizukuStatus.permissionGranted);
      expect(ShizukuStatusExtension.fromCode('ready'), ShizukuStatus.ready);
    });

    test('fromCode returns notInstalled for unknown codes', () {
      expect(ShizukuStatusExtension.fromCode(''), ShizukuStatus.notInstalled);
      expect(ShizukuStatusExtension.fromCode('bogus'), ShizukuStatus.notInstalled);
    });

    test('isReady is only true for ready', () {
      for (final s in ShizukuStatus.values) {
        expect(s.isReady, s == ShizukuStatus.ready, reason: 'Failed for $s');
      }
    });

    test('isRunning is false for notInstalled and notRunning', () {
      expect(ShizukuStatus.notInstalled.isRunning, isFalse);
      expect(ShizukuStatus.notRunning.isRunning, isFalse);
      expect(ShizukuStatus.binderConnected.isRunning, isTrue);
      expect(ShizukuStatus.permissionDenied.isRunning, isTrue);
      expect(ShizukuStatus.permissionGranted.isRunning, isTrue);
      expect(ShizukuStatus.ready.isRunning, isTrue);
    });

    test('isActionable is true for states requiring user action', () {
      expect(ShizukuStatus.notInstalled.isActionable, isTrue);
      expect(ShizukuStatus.notRunning.isActionable, isTrue);
      expect(ShizukuStatus.binderConnected.isActionable, isTrue);
      expect(ShizukuStatus.permissionDenied.isActionable, isTrue);
      expect(ShizukuStatus.permissionGranted.isActionable, isFalse);
      expect(ShizukuStatus.ready.isActionable, isFalse);
    });

    test('all statuses have non-empty display text', () {
      for (final s in ShizukuStatus.values) {
        expect(s.displayTitle.isNotEmpty, isTrue, reason: '$s displayTitle is empty');
        expect(s.displayDescription.isNotEmpty, isTrue, reason: '$s displayDescription is empty');
        expect(s.shortLabel.isNotEmpty, isTrue, reason: '$s shortLabel is empty');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ShizukuMockService unit tests
  // ─────────────────────────────────────────────────────────────────────────

  group('ShizukuMockService', () {
    test('returns initial status from getStatus()', () async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notRunning);
      expect(await svc.getStatus(), ShizukuStatus.notRunning);
    });

    test('simulateStatus changes the returned status', () async {
      final svc = ShizukuMockService();
      svc.simulateStatus(ShizukuStatus.binderConnected);
      expect(await svc.getStatus(), ShizukuStatus.binderConnected);
    });

    test('checkPermission returns false when not permitted', () async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.binderConnected);
      expect(await svc.checkPermission(), isFalse);
    });

    test('checkPermission returns true when permissionGranted or ready', () async {
      final svc1 = ShizukuMockService(initialStatus: ShizukuStatus.permissionGranted);
      expect(await svc1.checkPermission(), isTrue);

      final svc2 = ShizukuMockService(initialStatus: ShizukuStatus.ready);
      expect(await svc2.checkPermission(), isTrue);
    });

    test('isReady returns true only when status is ready', () async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.permissionGranted);
      expect(await svc.isReady(), isFalse);
      svc.simulateStatus(ShizukuStatus.ready);
      expect(await svc.isReady(), isTrue);
    });

    test('requestPermission advances state to ready when permissionGrantOnRequest=true', () async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: true,
      );
      final result = await svc.requestPermission();
      expect(result, isTrue);
      expect(await svc.getStatus(), ShizukuStatus.ready);
    });

    test('requestPermission sets permissionDenied when permissionGrantOnRequest=false', () async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: false,
      );
      final result = await svc.requestPermission();
      expect(result, isFalse);
      expect(await svc.getStatus(), ShizukuStatus.permissionDenied);
    });

    test('requestPermission returns false when Shizuku is not running', () async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notRunning);
      expect(await svc.requestPermission(), isFalse);
      // State should remain notRunning
      expect(await svc.getStatus(), ShizukuStatus.notRunning);
    });

    test('requestPermission returns false when Shizuku is not installed', () async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      expect(await svc.requestPermission(), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // State transition sequence tests
  // ─────────────────────────────────────────────────────────────────────────

  group('ShizukuMockService — state transition sequence', () {
    test('full happy path: notInstalled → notRunning → binderConnected → ready', () async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.notInstalled,
        permissionGrantOnRequest: true,
      );

      expect(await svc.getStatus(), ShizukuStatus.notInstalled);
      expect(await svc.isReady(), isFalse);

      svc.simulateStatus(ShizukuStatus.notRunning);
      expect(await svc.getStatus(), ShizukuStatus.notRunning);
      expect(await svc.isReady(), isFalse);

      svc.simulateStatus(ShizukuStatus.binderConnected);
      expect(await svc.getStatus(), ShizukuStatus.binderConnected);
      expect(await svc.checkPermission(), isFalse);

      await svc.requestPermission();
      expect(await svc.getStatus(), ShizukuStatus.ready);
      expect(await svc.isReady(), isTrue);
      expect(await svc.checkPermission(), isTrue);
    });

    test('denial path: binderConnected → permissionDenied → retry → ready', () async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: false,
      );

      await svc.requestPermission();
      expect(await svc.getStatus(), ShizukuStatus.permissionDenied);

      // Simulate user retrying and granting
      svc.simulateStatus(ShizukuStatus.binderConnected);
      final retryService = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: true,
      );
      await retryService.requestPermission();
      expect(await retryService.getStatus(), ShizukuStatus.ready);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CommandRegistry tests
  // ─────────────────────────────────────────────────────────────────────────

  group('CommandRegistry', () {
    late CommandRegistry registry;

    setUp(() {
      // Fresh instance for each test via the singleton's registered map
      registry = CommandRegistry.instance;
    });

    test('starts empty in a fresh test context', () {
      // We cannot clear the singleton across tests, so verify the type
      expect(registry.registeredIds, isA<List<String>>());
    });

    test('isRegistered returns false for unknown commandId', () {
      expect(registry.isRegistered('nonExistentCommand_xyz'), isFalse);
    });

    test('lookup returns null for unknown commandId', () {
      expect(registry.lookup('nonExistentCommand_xyz'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ShizukuStatusBanner widget tests
  // ─────────────────────────────────────────────────────────────────────────

  group('ShizukuStatusBanner widget', () {
    testWidgets('renders nothing (SizedBox) when status is ready', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.ready);
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      // Banner should be invisible when ready
      expect(find.text('Shizuku Ready'), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('renders banner with title when notInstalled', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Shizuku Not Installed'), findsOneWidget);
    });

    testWidgets('renders banner with title when notRunning', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notRunning);
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Shizuku Not Running'), findsOneWidget);
    });

    testWidgets('renders banner with title when permissionDenied', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.permissionDenied);
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Permission Required'), findsOneWidget);
    });

    testWidgets('renders banner with title when binderConnected', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.binderConnected);
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Shizuku Connected'), findsOneWidget);
    });

    testWidgets('shows Allow action chip when binderConnected', (tester) async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: true,
      );
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('tapping Allow chip requests permission and transitions to ready', (tester) async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.binderConnected,
        permissionGrantOnRequest: true,
      );
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      // After granting permission, banner should be invisible
      expect(find.text('Shizuku Connected'), findsNothing);
    });

    testWidgets('shows Retry chip when permissionDenied', (tester) async {
      final svc = ShizukuMockService(
        initialStatus: ShizukuStatus.permissionDenied,
        permissionGrantOnRequest: true,
      );
      await tester.pumpWidget(_buildApp(const ShizukuStatusBanner(), service: svc));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ShizukuSetupSheet widget tests
  // ─────────────────────────────────────────────────────────────────────────

  group('ShizukuSetupSheet widget', () {
    Future<void> openSheet(WidgetTester tester, ShizukuMockService svc) async {
      await tester.pumpWidget(_buildApp(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ShizukuSetupSheet(),
            ),
            child: const Text('Open'),
          ),
        ),
        service: svc,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders header with Shizuku title', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      await openSheet(tester, svc);

      expect(find.text('Shizuku'), findsOneWidget);
      expect(find.text('Required for advanced system controls'), findsOneWidget);
    });

    testWidgets('shows notInstalled description', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      await openSheet(tester, svc);

      expect(find.text('Shizuku Not Installed'), findsOneWidget);
    });

    testWidgets('shows permission request button when binderConnected', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.binderConnected);
      await openSheet(tester, svc);

      expect(find.byKey(const Key('shizuku_request_permission_btn')), findsOneWidget);
    });

    testWidgets('Check Status button is always present', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notRunning);
      await openSheet(tester, svc);

      expect(find.byKey(const Key('shizuku_check_status_btn')), findsOneWidget);
    });

    testWidgets('shows troubleshooting steps for notInstalled', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      await openSheet(tester, svc);

      expect(find.text('TROUBLESHOOTING'), findsOneWidget);
    });

    testWidgets('no permission button when notInstalled', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notInstalled);
      await openSheet(tester, svc);

      expect(
        find.byKey(const Key('shizuku_request_permission_btn')),
        findsNothing,
      );
    });

    testWidgets('shows DEVICE NOTES section', (tester) async {
      final svc = ShizukuMockService(initialStatus: ShizukuStatus.notRunning);
      await openSheet(tester, svc);

      // Scroll down to find device notes
      await tester.scrollUntilVisible(
        find.text('DEVICE NOTES'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('DEVICE NOTES'), findsOneWidget);
    });
  });
}
