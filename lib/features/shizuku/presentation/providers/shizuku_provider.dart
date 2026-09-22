import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/shizuku_service_impl.dart';
import '../../domain/entities/shizuku_status.dart';
import '../../domain/services/shizuku_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the active [ShizukuService] implementation.
///
/// Override in tests with [ShizukuMockService]:
///   shizukuServiceProvider.overrideWithValue(ShizukuMockService(...))
final shizukuServiceProvider = Provider<ShizukuService>((ref) {
  return ShizukuServiceImpl();
});

// ─────────────────────────────────────────────────────────────────────────────
// Status notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Async notifier that holds the current [ShizukuStatus] and exposes actions.
class ShizukuNotifier extends AsyncNotifier<ShizukuStatus> {
  @override
  Future<ShizukuStatus> build() => _fetchStatus();

  Future<ShizukuStatus> _fetchStatus() {
    final service = ref.read(shizukuServiceProvider);
    return service.getStatus();
  }

  /// Re-queries the native layer and updates state.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStatus);
  }

  /// Requests Shizuku permission, then refreshes state.
  ///
  /// Returns true if permission was granted after the request.
  Future<bool> requestPermission() async {
    final service = ref.read(shizukuServiceProvider);
    final granted = await service.requestPermission();
    await refresh();
    return granted;
  }
}

/// Provider for [ShizukuNotifier].
final shizukuStatusProvider =
    AsyncNotifierProvider<ShizukuNotifier, ShizukuStatus>(ShizukuNotifier.new);
