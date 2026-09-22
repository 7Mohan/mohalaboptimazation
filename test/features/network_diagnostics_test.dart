import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/theme/app_theme.dart';
import 'package:mohalab_optimization/features/network/data/datasources/mock_network_probe.dart';
import 'package:mohalab_optimization/features/network/data/datasources/network_history_local_datasource.dart';
import 'package:mohalab_optimization/features/network/data/repositories/network_history_repository_impl.dart';
import 'package:mohalab_optimization/features/network/domain/entities/gaming_network_verdict.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_connection_type.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_diagnostic_session.dart';
import 'package:mohalab_optimization/features/network/domain/entities/network_metrics.dart';
import 'package:mohalab_optimization/features/network/domain/services/network_diagnostics_engine.dart';
import 'package:mohalab_optimization/features/network/presentation/providers/network_diagnostics_providers.dart';
import 'package:mohalab_optimization/features/network/presentation/screens/network_diagnostics_screen.dart';
import 'package:mohalab_optimization/features/settings/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkMetrics & Formatted Displays', () {
    test('Formats metrics accurately with null-safety', () {
      final now = DateTime.now();
      final metrics = NetworkMetrics(
        connectionType: NetworkConnectionType.wifi,
        isOnline: true,
        dnsResolutionMs: 14.2,
        latencyMs: 28.6,
        minLatencyMs: 25.0,
        maxLatencyMs: 32.0,
        jitterMs: 2.4,
        packetLossPercent: 0.0,
        probeSamplesCount: 8,
        timestamp: now,
        wifiFrequencyMhz: 5240,
        wifiLinkSpeedMbps: 866,
        localGatewayLatencyMs: 1.8,
      );

      expect(metrics.latencyDisplay, equals('29 ms'));
      expect(metrics.jitterDisplay, equals('2.4 ms'));
      expect(metrics.packetLossDisplay, equals('0.0%'));
      expect(metrics.dnsDisplay, equals('14 ms'));
      expect(metrics.wifiBandDisplay, equals('5.0 GHz'));

      // Test serialization
      final map = metrics.toMap();
      final revived = NetworkMetrics.fromMap(map);
      expect(revived.connectionType, equals(NetworkConnectionType.wifi));
      expect(revived.latencyMs, equals(28.6));
      expect(revived.packetLossPercent, equals(0.0));
    });

    test('Handles unavailable metrics gracefully', () {
      final metrics = NetworkMetrics(
        connectionType: NetworkConnectionType.offline,
        isOnline: false,
        timestamp: DateTime.now(),
      );

      expect(metrics.latencyDisplay, equals('Unavailable'));
      expect(metrics.jitterDisplay, equals('Unavailable'));
      expect(metrics.dnsDisplay, equals('Unavailable'));
      expect(metrics.wifiBandDisplay, isNull);
    });
  });

  group('NetworkDiagnosticsEngine Evaluation Scenarios', () {
    test('Low latency Wi-Fi produces lowLatency verdict and positive recommendation', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.wifi,
        dnsResolutionDurationMs: 12.0,
        samples: [22.0, 23.0, 22.5, 23.5, 22.8, 23.2, 22.9, 23.1],
        gatewayLatencyMs: 1.5,
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.primaryVerdict, equals(GamingNetworkVerdict.lowLatency));
      expect(session.metrics.isOnline, isTrue);
      expect(session.metrics.packetLossPercent, equals(0.0));
      expect(session.metrics.jitterMs, lessThan(5.0));
      expect(session.recommendations.any((r) => r.title.contains('Optimal')), isTrue);
    });

    test('High jitter scenario flags highJitter verdict and bufferbloat recommendation', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.wifi,
        samples: [20.0, 85.0, 18.0, 92.0, 22.0, 78.0, 19.0, 88.0],
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.primaryVerdict, equals(GamingNetworkVerdict.highJitter));
      expect(session.metrics.jitterMs, greaterThanOrEqualTo(20.0));
      expect(session.recommendations.any((r) => r.title.contains('Bufferbloat')), isTrue);
    });

    test('Packet loss scenario computes loss % accurately and flags packetLossDetected', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.wifi,
        // 2 out of 8 dropped = 25% loss
        samples: [30.0, null, 32.0, 31.0, null, 33.0, 30.5, 31.2],
        gatewayLatencyMs: 1.8, // Healthy local gateway
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.primaryVerdict, equals(GamingNetworkVerdict.packetLossDetected));
      expect(session.metrics.packetLossPercent, equals(25.0));
      // Confirms upstream attribution because local gateway is healthy (< 5ms)
      expect(session.recommendations.any((r) => r.title.contains('Upstream Packet Loss')), isTrue);
    });

    test('2.4GHz Wi-Fi band flags switch to 5GHz recommendation', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.wifi,
        interfaceDetails: {
          'wifiFrequencyMhz': 2437, // 2.4 GHz channel
          'wifiLinkSpeedMbps': 72,
        },
        samples: [42.0, 44.0, 41.0, 45.0, 43.0, 42.5, 43.5, 42.8],
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.metrics.wifiBandDisplay, equals('2.4 GHz'));
      expect(session.recommendations.any((r) => r.title.contains('Switch to 5GHz')), isTrue);
    });

    test('Offline state immediately returns networkUnavailable verdict', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.offline,
        samples: [],
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.primaryVerdict, equals(GamingNetworkVerdict.networkUnavailable));
      expect(session.metrics.isOnline, isFalse);
      expect(session.metrics.packetLossPercent, equals(100.0));
      expect(session.recommendations.first.title, contains('No Active Connection'));
    });

    test('Failed DNS resolution is handled without crashing', () async {
      final probe = MockNetworkProbe(
        connectionType: NetworkConnectionType.cellular,
        dnsResolutionDurationMs: null, // DNS failed
        samples: [65.0, 68.0, 64.0, 67.0, 66.0, 65.5, 67.2, 66.8],
      );
      final engine = NetworkDiagnosticsEngine(probe);

      final session = await engine.runDiagnostics();

      expect(session.metrics.dnsResolutionMs, isNull);
      expect(session.metrics.isOnline, isTrue);
      // Cellular advisory present
      expect(session.recommendations.any((r) => r.title.contains('Mobile Cellular')), isTrue);
    });
  });

  group('NetworkHistoryRepository & Persistence', () {
    test('Saves, retrieves, and deletes sessions from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localDs = NetworkHistoryLocalDataSource(prefs);
      final repo = NetworkHistoryRepositoryImpl(localDs);

      final session = NetworkDiagnosticSession(
        id: 'net_test_1',
        timestamp: DateTime.now(),
        metrics: NetworkMetrics(
          connectionType: NetworkConnectionType.wifi,
          isOnline: true,
          latencyMs: 30.0,
          timestamp: DateTime.now(),
        ),
        primaryVerdict: GamingNetworkVerdict.lowLatency,
        durationMs: 450,
      );

      await repo.saveSession(session);
      var history = await repo.getHistory();
      expect(history.length, equals(1));
      expect(history.first.id, equals('net_test_1'));
      expect(history.first.primaryVerdict, equals(GamingNetworkVerdict.lowLatency));

      // Delete session
      await repo.deleteSession('net_test_1');
      history = await repo.getHistory();
      expect(history.isEmpty, isTrue);
    });
  });

  group('NetworkDiagnosticsScreen Widget Tests', () {
    late MockNetworkProbe mockProbe;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockProbe = MockNetworkProbe(
        connectionType: NetworkConnectionType.wifi,
        samples: [28.0, 29.0, 27.5, 29.5, 28.5, 28.2, 29.1, 28.8],
      );
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          networkProbeDataSourceProvider.overrideWithValue(mockProbe),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const NetworkDiagnosticsScreen(),
        ),
      );
    }

    testWidgets('Renders connection overview, transparency banner, and run CTA', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Network Diagnostics'), findsOneWidget);
      expect(find.text('Diagnostic Transparency'), findsOneWidget);
      expect(find.text('Active Connection'), findsOneWidget);
      expect(find.text('Run Network Diagnostics'), findsOneWidget);
      expect(find.text('No past test runs recorded'), findsOneWidget);
    });

    testWidgets('Tapping Run Network Diagnostics runs test and displays results grid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final runButton = find.byKey(const Key('run_network_diagnostics_button'));
      expect(runButton, findsOneWidget);

      await tester.tap(runButton);
      await tester.pumpAndSettle();

      // Confirms verdict, metrics grid, and recommendations are displayed
      expect(find.text('Gaming Quality Verdict'), findsOneWidget);
      expect(find.text('Low Latency'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Telemetry Metrics'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Telemetry Metrics'), findsOneWidget);
      expect(find.text('Ping (Latency)'), findsOneWidget);
      expect(find.text('Jitter'), findsOneWidget);
      expect(find.text('Packet Loss'), findsOneWidget);
      expect(find.text('DNS Resolution'), findsOneWidget);

      // Verify historical run was recorded
      await tester.scrollUntilVisible(
        find.text('Recent Tests (1)'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recent Tests (1)'), findsOneWidget);
    });
  });
}
