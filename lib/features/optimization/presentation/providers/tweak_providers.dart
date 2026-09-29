import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/presentation/providers/theme_provider.dart';
import '../../../shizuku/presentation/providers/shizuku_provider.dart';
import '../../data/tweak_engine_bridge.dart';
import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';

final tweakBridgeProvider = Provider<TweakEngineBridge>((ref) => const TweakEngineBridge());

/// Immutable view of the device's tweak state.
class TweaksSnapshot {
  const TweaksSnapshot({
    this.capabilities = const TweakCapabilities(),
    this.states = const {},
    this.busy = const {},
  });

  final TweakCapabilities capabilities;
  final Map<String, TweakState> states;

  /// IDs of tweaks/actions currently running.
  final Set<String> busy;

  TweakState stateOf(String id) => states[id] ?? const TweakState();
  bool isActive(String id) => stateOf(id).active;
  bool isBusy(String id) => busy.contains(id);

  bool canRun(TweakDefinition def) =>
      capabilities.allows(def.access) &&
      stateOf(def.id).supported &&
      (capabilities.sdkInt == 0 || capabilities.sdkInt >= def.minSdk);

  int get activeCount => TweakCatalog.all.where((t) => isActive(t.id)).length;

  TweaksSnapshot copyWith({
    TweakCapabilities? capabilities,
    Map<String, TweakState>? states,
    Set<String>? busy,
  }) =>
      TweaksSnapshot(
        capabilities: capabilities ?? this.capabilities,
        states: states ?? this.states,
        busy: busy ?? this.busy,
      );
}

/// Single source of truth for every tweak toggle in the app.
///
/// State is always read back from the device — never assumed — so toggles
/// survive navigation, app restarts and changes made outside the app. It
/// re-syncs whenever the app returns to the foreground or Shizuku changes.
class TweaksController extends AsyncNotifier<TweaksSnapshot> {
  TweakEngineBridge get _bridge => ref.read(tweakBridgeProvider);

  @override
  Future<TweaksSnapshot> build() async {
    final lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    ref.onDispose(lifecycle.dispose);
    ref.listen(shizukuStatusProvider, (prev, next) {
      if (prev?.valueOrNull != next.valueOrNull) unawaited(refresh());
    });
    return _load();
  }

  Future<TweaksSnapshot> _load() async {
    final results = await Future.wait([_bridge.capabilities(), _bridge.states()]);
    return TweaksSnapshot(
      capabilities: results[0] as TweakCapabilities,
      states: results[1] as Map<String, TweakState>,
      busy: state.valueOrNull?.busy ?? const {},
    );
  }

  Future<void> refresh() async {
    final next = await AsyncValue.guard(_load);
    state = next;
  }

  void _setBusy(String id, bool busy) {
    final current = state.valueOrNull ?? const TweaksSnapshot();
    final ids = Set<String>.from(current.busy);
    busy ? ids.add(id) : ids.remove(id);
    state = AsyncData(current.copyWith(busy: ids));
  }

  Map<String, Object?> _paramsFor(String id) => switch (id) {
        'refresh_rate_lock' => {
            'hz': state.valueOrNull?.capabilities.maxRefreshRate ?? 60.0,
          },
        'animation_scale' => {'scale': 0.5},
        'private_dns' => {'provider': 'cloudflare'},
        _ => const {},
      };

  /// Turns a tweak on or off and returns the device's verdict.
  Future<TweakResult> setEnabled(String id, bool enabled) async {
    _setBusy(id, true);
    final result = enabled ? await _bridge.apply(id, _paramsFor(id)) : await _bridge.revert(id);
    final states = await _bridge.states();
    final current = state.valueOrNull ?? const TweaksSnapshot();
    final busy = Set<String>.from(current.busy)..remove(id);
    state = AsyncData(current.copyWith(states: states, busy: busy));
    return result;
  }

  Future<TweakResult> runAction(String id, {String? packageName, String? mode}) async {
    _setBusy(id, true);
    final result = await _bridge.runAction(id, packageName: packageName, mode: mode);
    _setBusy(id, false);
    return result;
  }

  /// Switches on the given recommended tweaks that are available and not
  /// already active. Unlike presets it never turns anything off.
  /// Returns (succeeded, attempted).
  Future<(int, int)> applyRecommended(Set<String> ids) async {
    final snapshot = state.valueOrNull ?? const TweaksSnapshot();
    var ok = 0;
    var attempted = 0;
    for (final def in TweakCatalog.all) {
      if (!ids.contains(def.id) || !snapshot.canRun(def) || snapshot.isActive(def.id)) continue;
      attempted++;
      if ((await setEnabled(def.id, true)).success) ok++;
    }
    return (ok, attempted);
  }

  /// Requests root from the device's root manager, then re-reads state.
  Future<TweakResult> requestRoot() async {
    final res = await _bridge.requestRoot();
    await refresh();
    return res;
  }

  Future<TweakResult> disableRoot() async {
    final res = await _bridge.disableRoot();
    await refresh();
    return res;
  }

  /// Applies a preset: its tweaks on, every other available tweak off.
  /// Returns (succeeded, attempted).
  Future<(int, int)> applyPreset(TweakPreset preset) async {
    ref.read(selectedPresetProvider.notifier).select(preset);
    final snapshot = state.valueOrNull ?? const TweaksSnapshot();
    var ok = 0;
    var attempted = 0;
    for (final def in TweakCatalog.all) {
      if (!snapshot.canRun(def)) continue;
      final want = preset.enabledIds.contains(def.id);
      if (snapshot.isActive(def.id) == want) continue;
      attempted++;
      final res = await setEnabled(def.id, want);
      if (res.success) ok++;
    }
    return (ok, attempted);
  }
}

final tweaksControllerProvider =
    AsyncNotifierProvider<TweaksController, TweaksSnapshot>(TweaksController.new);

/// The preset the user last chose — persisted so it survives restarts.
class SelectedPresetNotifier extends Notifier<TweakPreset?> {
  static const _key = 'tweak_preset_v1';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null; // Not initialised (tests / previews).
    }
  }

  @override
  TweakPreset? build() {
    final name = _prefs?.getString(_key);
    for (final p in TweakPreset.values) {
      if (p.name == name) return p;
    }
    return null;
  }

  void select(TweakPreset preset) {
    state = preset;
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.setString(_key, preset.name));
  }
}

final selectedPresetProvider =
    NotifierProvider<SelectedPresetNotifier, TweakPreset?>(SelectedPresetNotifier.new);
