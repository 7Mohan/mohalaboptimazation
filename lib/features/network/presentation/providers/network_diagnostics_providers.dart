import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/native_network_probe.dart';
import '../../data/datasources/network_history_local_datasource.dart';
import '../../data/repositories/network_history_repository_impl.dart';
import '../../domain/datasources/network_probe_datasource.dart';
import '../../domain/entities/network_diagnostic_session.dart';
import '../../domain/repositories/network_history_repository.dart';
import '../../domain/services/network_diagnostics_engine.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

/// Provider for the network probe data source (overridable in tests).
final networkProbeDataSourceProvider = Provider<NetworkProbeDataSource>((ref) {
  return const NativeNetworkProbe();
});

/// Provider for the network history repository.
final networkHistoryRepositoryProvider = Provider<NetworkHistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final ds = NetworkHistoryLocalDataSource(prefs);
  return NetworkHistoryRepositoryImpl(ds);
});

/// Provider for the diagnostics engine.
final networkDiagnosticsEngineProvider = Provider<NetworkDiagnosticsEngine>((ref) {
  final probe = ref.watch(networkProbeDataSourceProvider);
  return NetworkDiagnosticsEngine(probe);
});

enum NetworkTestStatus {
  idle,
  running,
  completed,
  error,
}

class NetworkDiagnosticsState {
  const NetworkDiagnosticsState({
    this.status = NetworkTestStatus.idle,
    this.progressStep = '',
    this.latestSession,
    this.history = const [],
    this.errorMessage,
  });

  final NetworkTestStatus status;
  final String progressStep;
  final NetworkDiagnosticSession? latestSession;
  final List<NetworkDiagnosticSession> history;
  final String? errorMessage;

  bool get isRunning => status == NetworkTestStatus.running;

  NetworkDiagnosticsState copyWith({
    NetworkTestStatus? status,
    String? progressStep,
    NetworkDiagnosticSession? latestSession,
    List<NetworkDiagnosticSession>? history,
    String? errorMessage,
  }) {
    return NetworkDiagnosticsState(
      status: status ?? this.status,
      progressStep: progressStep ?? this.progressStep,
      latestSession: latestSession ?? this.latestSession,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }
}

class NetworkDiagnosticsController extends StateNotifier<NetworkDiagnosticsState> {
  NetworkDiagnosticsController(this.ref) : super(const NetworkDiagnosticsState()) {
    loadHistory();
  }

  final Ref ref;

  Future<void> loadHistory() async {
    try {
      final repo = ref.read(networkHistoryRepositoryProvider);
      final list = await repo.getHistory();
      state = state.copyWith(history: list);
    } catch (_) {
      // Ignored if prefs not ready yet
    }
  }

  Future<void> runDiagnostics() async {
    final engine = ref.read(networkDiagnosticsEngineProvider);
    final repo = ref.read(networkHistoryRepositoryProvider);

    state = state.copyWith(
      status: NetworkTestStatus.running,
      progressStep: 'Initializing network diagnostics...',
      errorMessage: null,
    );

    try {
      final session = await engine.runDiagnostics(
        onProgress: (step) {
          state = state.copyWith(progressStep: step);
        },
      );

      await repo.saveSession(session);
      final updatedHistory = await repo.getHistory();

      state = state.copyWith(
        status: NetworkTestStatus.completed,
        progressStep: 'Diagnostics completed',
        latestSession: session,
        history: updatedHistory,
      );
    } catch (e) {
      state = state.copyWith(
        status: NetworkTestStatus.error,
        errorMessage: 'Diagnostic probe failed: $e',
      );
    }
  }

  Future<void> deleteSession(String id) async {
    final repo = ref.read(networkHistoryRepositoryProvider);
    await repo.deleteSession(id);
    final updatedHistory = await repo.getHistory();
    state = state.copyWith(history: updatedHistory);
  }

  Future<void> clearHistory() async {
    final repo = ref.read(networkHistoryRepositoryProvider);
    await repo.clearHistory();
    state = state.copyWith(history: const []);
  }
}

final networkDiagnosticsControllerProvider =
    StateNotifierProvider<NetworkDiagnosticsController, NetworkDiagnosticsState>((ref) {
  return NetworkDiagnosticsController(ref);
});
