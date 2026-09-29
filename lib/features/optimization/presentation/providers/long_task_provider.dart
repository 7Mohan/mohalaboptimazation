import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';
import 'tweak_providers.dart';

/// Live state of a long ART task (per-app compile or system dexopt).
class LongTaskState {
  const LongTaskState({
    required this.task,
    required this.startedAt,
    this.running = true,
    this.stopping = false,
    this.done = 0,
    this.total = 0,
    this.label,
    this.packageName,
    this.ok = 0,
    this.failed = 0,
    this.result,
  });

  /// TweakAction id: `compile_apps` or `compile_all`.
  final String task;
  final DateTime startedAt;
  final bool running;
  final bool stopping;
  final int done;
  final int total;
  final String? label;
  final String? packageName;
  final int ok;
  final int failed;
  final TweakResult? result;

  /// 0–1, or null while the total is unknown (system dexopt reports none).
  double? get progress => total > 0 ? (done / total).clamp(0.0, 1.0) : null;

  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Linear estimate from the pace so far; null until a few apps are done.
  Duration? get remaining {
    if (total == 0 || done < 3) return null;
    final perApp = elapsed.inMilliseconds / done;
    return Duration(milliseconds: (perApp * (total - done)).round());
  }

  LongTaskState copyWith({
    bool? running,
    bool? stopping,
    int? done,
    int? total,
    String? label,
    String? packageName,
    int? ok,
    int? failed,
    TweakResult? result,
  }) =>
      LongTaskState(
        task: task,
        startedAt: startedAt,
        running: running ?? this.running,
        stopping: stopping ?? this.stopping,
        done: done ?? this.done,
        total: total ?? this.total,
        label: label ?? this.label,
        packageName: packageName ?? this.packageName,
        ok: ok ?? this.ok,
        failed: failed ?? this.failed,
        result: result ?? this.result,
      );
}

class LongTaskController extends Notifier<LongTaskState?> {
  @override
  LongTaskState? build() {
    ref.read(tweakBridgeProvider).setProgressListener(_onEvent);
    return null;
  }

  bool get isRunning => state?.running ?? false;

  void _onEvent(Map<dynamic, dynamic> e) {
    final current = state;
    if (current == null || !current.running) return;
    state = current.copyWith(
      done: (e['done'] as num?)?.toInt(),
      total: (e['total'] as num?)?.toInt(),
      label: e['label'] as String? ?? e['packageName'] as String?,
      packageName: e['packageName'] as String?,
      ok: (e['ok'] as num?)?.toInt(),
      failed: (e['failed'] as num?)?.toInt(),
    );
  }

  Future<TweakResult> compileApps({
    required bool maxSpeed,
    bool includeSystem = false,
    List<String>? packages,
  }) async {
    if (isRunning) return const TweakResult(success: false, message: 'A task is already running');
    state = LongTaskState(task: TweakCatalog.compileApps.id, startedAt: DateTime.now());
    final res = await ref
        .read(tweakBridgeProvider)
        .compileApps(maxSpeed: maxSpeed, includeSystem: includeSystem, packages: packages);
    _finish(res);
    return res;
  }

  Future<TweakResult> systemDexopt() async {
    if (isRunning) return const TweakResult(success: false, message: 'A task is already running');
    state = LongTaskState(task: TweakCatalog.compileAll.id, startedAt: DateTime.now());
    final res = await ref.read(tweakBridgeProvider).runAction(TweakCatalog.compileAll.id);
    _finish(res);
    return res;
  }

  void _finish(TweakResult res) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      running: false,
      stopping: false,
      done: current.total > 0 && res.success && !current.stopping ? current.total : null,
      result: res,
    );
  }

  Future<void> cancel() async {
    final current = state;
    if (current == null || !current.running) return;
    state = current.copyWith(stopping: true);
    await ref.read(tweakBridgeProvider).cancelLongTask();
  }

  /// Clears a finished task so the next one starts fresh.
  void dismiss() {
    if (!isRunning) state = null;
  }
}

final longTaskProvider =
    NotifierProvider<LongTaskController, LongTaskState?>(LongTaskController.new);
