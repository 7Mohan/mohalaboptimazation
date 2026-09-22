import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohalab_optimization/features/diagnostics/data/models/device_info_model.dart';
import 'package:mohalab_optimization/features/diagnostics/data/services/device_info_service.dart';

// ---------------------------------------------------------------------------
// Static provider (loaded once on app start)
// ---------------------------------------------------------------------------

/// Full hardware snapshot -- fetched once at app startup.
final fullDeviceInfoProvider = FutureProvider<FullDeviceInfo>(
  (_) => DeviceInfoService.fetchAll(),
  name: 'fullDeviceInfoProvider',
);

// ---------------------------------------------------------------------------
// Live polling notifiers
// ---------------------------------------------------------------------------

/// Live battery state, refreshed every 30 s.
class BatteryNotifier extends AsyncNotifier<BatteryInfo> {
  Timer? _timer;

  @override
  Future<BatteryInfo> build() async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling();
    return DeviceInfoService.fetchBattery();
  }

  void _startPolling() {
    _timer?.cancel();
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      state = const AsyncLoading<BatteryInfo>().copyWithPrevious(state);
      state = await AsyncValue.guard(DeviceInfoService.fetchBattery);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<BatteryInfo>().copyWithPrevious(state);
    state = await AsyncValue.guard(DeviceInfoService.fetchBattery);
  }
}

final liveBatteryProvider =
    AsyncNotifierProvider<BatteryNotifier, BatteryInfo>(BatteryNotifier.new);

/// Live memory state, refreshed every 15 s.
class MemoryNotifier extends AsyncNotifier<MemoryInfo> {
  Timer? _timer;

  @override
  Future<MemoryInfo> build() async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling();
    return DeviceInfoService.fetchMemory();
  }

  void _startPolling() {
    _timer?.cancel();
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      state = const AsyncLoading<MemoryInfo>().copyWithPrevious(state);
      state = await AsyncValue.guard(DeviceInfoService.fetchMemory);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<MemoryInfo>().copyWithPrevious(state);
    state = await AsyncValue.guard(DeviceInfoService.fetchMemory);
  }
}

final liveMemoryProvider =
    AsyncNotifierProvider<MemoryNotifier, MemoryInfo>(MemoryNotifier.new);