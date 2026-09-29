import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak_catalog.dart';
import 'package:mohalab_optimization/features/optimization/presentation/providers/long_task_provider.dart';
import 'package:mohalab_optimization/features/optimization/presentation/providers/tweak_providers.dart';

/// Simulates TweakEngine.kt: device state lives here, outside any provider,
/// just like Android settings live outside the app process.
class _FakeDevice {
  final Set<String> active = {};
  bool shizuku = true;
  final List<String> calls = [];

  Future<Object?> handle(MethodCall call) async {
    final args = (call.arguments as Map?) ?? const {};
    calls.add('${call.method}:${args['id'] ?? ''}');
    switch (call.method) {
      case 'getCapabilities':
        return {
          'sdkInt': 34,
          'manufacturer': 'Test',
          'shizukuReady': shizuku,
          'secureSettingsGranted': false,
          'notificationPolicyGranted': false,
          'refreshRates': [60.0, 120.0],
        };
      case 'getStates':
        return {
          for (final t in TweakCatalog.all)
            t.id: {'supported': true, 'active': active.contains(t.id), 'detail': null},
        };
      case 'apply':
        if (!shizuku) return {'success': false, 'message': 'Requires Shizuku'};
        active.add(args['id'] as String);
        return {'success': true, 'message': 'Applied and verified'};
      case 'revert':
        active.remove(args['id']);
        return {'success': true, 'message': 'Original settings restored'};
      case 'runAction':
        return {'success': true, 'message': 'done', 'freedBytes': 104857600};
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.mohalab.optimization/tweaks');
  late _FakeDevice device;

  setUp(() {
    device = _FakeDevice();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, device.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Tweak catalog', () {
    test('ids are unique', () {
      final ids = TweakCatalog.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('contains no known placebo tweaks', () {
      const banned = [
        'net.tcp.buffersize',
        'debug.hwc',
        'tap_duration_threshold',
        'touch_blocking_period',
        'ro.',
        'omx_default_rank',
        'disable_backpressure',
      ];
      for (final t in TweakCatalog.all) {
        for (final b in banned) {
          expect(t.changes.contains(b), isFalse, reason: '${t.id} uses placebo "$b"');
        }
      }
    });

    test('presets only reference real catalog tweaks', () {
      final ids = TweakCatalog.all.map((t) => t.id).toSet();
      for (final p in TweakPreset.values) {
        expect(ids.containsAll(p.enabledIds), isTrue, reason: p.name);
      }
    });
  });

  group('TweakCapabilities', () {
    test('settings tweaks accept Shizuku or ADB grant', () {
      const adbOnly = TweakCapabilities(secureSettingsGranted: true);
      expect(adbOnly.allows(TweakAccess.settings), isTrue);
      expect(adbOnly.allows(TweakAccess.shell), isFalse);
    });

    test('max refresh rate picks the highest mode', () {
      const caps = TweakCapabilities(refreshRates: [60, 144, 90]);
      expect(caps.maxRefreshRate, 144);
    });
  });

  group('TweaksController', () {
    test('toggle state is read from the device, not memory — survives a restart', () async {
      final first = ProviderContainer();
      await first.read(tweaksControllerProvider.future);
      final res = await first.read(tweaksControllerProvider.notifier).setEnabled('disable_blurs', true);
      expect(res.success, isTrue);
      expect(first.read(tweaksControllerProvider).value!.isActive('disable_blurs'), isTrue);
      first.dispose();

      // Simulate leaving the app: a brand-new provider graph.
      final second = ProviderContainer();
      addTearDown(second.dispose);
      final snapshot = await second.read(tweaksControllerProvider.future);
      expect(snapshot.isActive('disable_blurs'), isTrue);
    });

    test('a rejected change leaves the switch off', () async {
      device.shizuku = false;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(tweaksControllerProvider.future);
      final res = await c.read(tweaksControllerProvider.notifier).setEnabled('fixed_performance', true);
      expect(res.success, isFalse);
      expect(c.read(tweaksControllerProvider).value!.isActive('fixed_performance'), isFalse);
    });

    test('refresh-rate lock asks for the panel maximum', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
        calls.add(call);
        return device.handle(call);
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(tweaksControllerProvider.future);
      await c.read(tweaksControllerProvider.notifier).setEnabled('refresh_rate_lock', true);
      final apply = calls.firstWhere((m) => m.method == 'apply');
      expect((apply.arguments as Map)['hz'], 120.0);
    });

    test('presets switch their tweaks on and everything else off', () async {
      device.active.addAll({'private_dns', 'scan_off'});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(tweaksControllerProvider.future);
      await c.read(tweaksControllerProvider.notifier).applyPreset(TweakPreset.balanced);
      expect(device.active, TweakPreset.balanced.enabledIds);
      expect(c.read(selectedPresetProvider), TweakPreset.balanced);
    });

    test('compile-all streams live progress, then the final result', () async {
      final c = ProviderContainer();
      c.read(longTaskProvider); // registers the progress listener
      final seen = <double?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'compileApps') return device.handle(call);
        expect((call.arguments as Map)['mode'], 'speed-profile');
        for (var i = 0; i < 3; i++) {
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(MethodCall('taskProgress', {
              'task': 'compile_apps', 'done': i, 'total': 3, 'packageName': 'com.game.$i',
              'label': 'Game $i', 'ok': i, 'failed': 0, 'finished': false,
            })),
            (_) {},
          );
          seen.add(c.read(longTaskProvider)?.progress);
        }
        return {'success': true, 'message': 'Compiled 3 apps (speed-profile)'};
      });
      addTearDown(c.dispose);
      final res = await c.read(longTaskProvider.notifier).compileApps(maxSpeed: false, includeSystem: false);
      expect(res.success, isTrue);
      expect(seen, [0.0, 1 / 3, 2 / 3]);
      final done = c.read(longTaskProvider)!;
      expect(done.running, isFalse);
      expect(done.progress, 1.0);
      expect(done.label, 'Game 2');
    });

    test('actions report measured freed bytes', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(tweaksControllerProvider.future);
      final res = await c.read(tweaksControllerProvider.notifier).runAction('ram_boost');
      expect(res.freedBytes, 104857600);
    });
  });
}
