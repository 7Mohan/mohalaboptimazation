import 'package:flutter/services.dart';

import '../domain/tweak.dart';

/// Talks to TweakEngine.kt. Only tweak IDs and validated parameters cross
/// the channel — commands are built natively from fixed templates.
class TweakEngineBridge {
  const TweakEngineBridge([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('com.mohalab.optimization/tweaks');

  final MethodChannel _channel;

  Future<TweakCapabilities> capabilities() async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
      return map == null ? const TweakCapabilities() : TweakCapabilities.fromMap(map);
    } on PlatformException {
      return const TweakCapabilities();
    } on MissingPluginException {
      return const TweakCapabilities();
    }
  }

  Future<Map<String, TweakState>> states() async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getStates');
      return {
        for (final e in (map ?? const {}).entries)
          e.key: TweakState.fromMap(e.value as Map<dynamic, dynamic>),
      };
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  Future<TweakResult> apply(String id, [Map<String, Object?> params = const {}]) =>
      _call('apply', {'id': id, ...params});

  Future<TweakResult> revert(String id) => _call('revert', {'id': id});

  Future<TweakResult> runAction(String id, {String? packageName, String? mode}) => _call('runAction', {
        'id': id,
        if (packageName != null) 'packageName': packageName,
        if (mode != null) 'mode': mode,
      });

  Future<TweakResult> applyGameTuning({
    required String packageName,
    required String mode,
    double downscale = 1.0,
    int? fps,
  }) =>
      _call('applyGameTuning', {
        'packageName': packageName,
        'mode': mode,
        'downscale': downscale,
        if (fps != null) 'fps': fps,
      });

  Future<TweakResult> resetGameTuning(String packageName) =>
      _call('resetGameTuning', {'packageName': packageName});

  /// Receives live progress events pushed by TweakEngine during long tasks.
  void setProgressListener(void Function(Map<dynamic, dynamic> event) onEvent) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'taskProgress' && call.arguments is Map) {
        onEvent(call.arguments as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  /// AOT-compiles apps one by one; progress arrives via [setProgressListener].
  Future<TweakResult> compileApps({
    required bool maxSpeed,
    bool includeSystem = false,
    List<String>? packages,
  }) =>
      _call('compileApps', {
        'mode': maxSpeed ? 'speed' : 'speed-profile',
        'includeSystem': includeSystem,
        if (packages != null) 'packages': packages,
      });

  Future<TweakResult> cancelLongTask() => _call('cancelLongTask', const {});

  /// Asks Magisk / KernelSU / APatch for root (shows the manager's prompt).
  Future<TweakResult> requestRoot() => _call('requestRoot', const {});

  Future<TweakResult> disableRoot() => _call('disableRoot', const {});

  /// Opens Android's "Do Not Disturb access" screen for this app.
  Future<void> openDndSettings() async {
    try {
      await _channel.invokeMethod<bool>('openDndSettings');
    } on PlatformException {
      // Settings screen unavailable on this ROM.
    } on MissingPluginException {
      // Not on Android.
    }
  }

  Future<TweakResult> _call(String method, Map<String, Object?> args) async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(method, args);
      return TweakResult.fromMap(map);
    } on PlatformException catch (e) {
      return TweakResult(success: false, message: e.message ?? 'Platform error');
    } on MissingPluginException {
      return const TweakResult(success: false, message: 'Only available on Android');
    }
  }
}
