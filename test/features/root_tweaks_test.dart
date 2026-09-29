import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/features/optimization/domain/device_advisor.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak_catalog.dart';

void main() {
  group('Root / non-root classification', () {
    test('every tweak lands in exactly one group', () {
      final nonRoot = TweakCatalog.nonRoot.map((t) => t.id).toSet();
      final root = TweakCatalog.rootOnly.map((t) => t.id).toSet();
      expect(nonRoot.intersection(root), isEmpty);
      expect(nonRoot.length + root.length, TweakCatalog.all.length);
    });

    test('kernel tweaks and Wi-Fi low-latency are root-only', () {
      final root = TweakCatalog.rootOnly.map((t) => t.id).toSet();
      expect(root, containsAll(['cpu_governor_perf', 'gpu_perf', 'tcp_bbr', 'swappiness_low', 'wifi_low_latency']));
      expect(TweakCatalog.rootActions.every((a) => a.access.isRoot), isTrue);
    });

    test('kernel tweaks are marked as reset on reboot', () {
      for (final t in TweakCatalog.rootOnly.where((t) => t.category == TweakCategory.kernel)) {
        expect(t.persistsReboot, isFalse, reason: t.id);
      }
    });
  });

  group('Root capabilities', () {
    test('Shizuku alone does not unlock root tweaks', () {
      const caps = TweakCapabilities(shizukuReady: true);
      expect(caps.allows(TweakAccess.root), isFalse);
      expect(caps.allows(TweakAccess.shell), isTrue);
    });

    test('su grant unlocks root and every shell-level tweak', () {
      const caps = TweakCapabilities(rootGranted: true);
      expect(caps.allows(TweakAccess.root), isTrue);
      expect(caps.allows(TweakAccess.shell), isTrue);
      expect(caps.allows(TweakAccess.settings), isTrue);
    });

    test('Shizuku running as root counts as root', () {
      expect(const TweakCapabilities(shizukuReady: true, shizukuRoot: true).hasRoot, isTrue);
    });
  });

  group('Root advice', () {
    const base = DeviceSignals(sdkInt: 34, ramGb: 8, maxCpuGhz: 2.4, cpuCores: 8, availableRamPercent: 20);

    test('non-rooted phones never get kernel recommendations', () {
      final ids = DeviceAdvisor.analyze(base).items.map((a) => a.id).toSet();
      expect(ids.intersection({'cpu_governor_perf', 'gpu_perf', 'tcp_bbr', 'drop_caches'}), isEmpty);
    });

    test('cool rooted mid-range phone gets CPU/GPU governors, BBR and drop caches', () {
      const s = DeviceSignals(sdkInt: 34, ramGb: 8, maxCpuGhz: 2.4, cpuCores: 8, availableRamPercent: 20, rooted: true);
      final a = DeviceAdvisor.analyze(s);
      final rec = a.recommended.map((e) => e.id).toSet();
      expect(rec, containsAll(['cpu_governor_perf', 'gpu_perf', 'tcp_bbr', 'drop_caches']));
      expect(a.recommended.firstWhere((e) => e.id == 'gpu_perf').reason, startsWith('Mid-range GPU'));
      expect(a.recommended.firstWhere((e) => e.id == 'drop_caches').reason, contains('20%'));
    });

    test('hot rooted phone is told to skip the CPU governor', () {
      const s = DeviceSignals(sdkInt: 34, rooted: true, batteryTempC: 45);
      final a = DeviceAdvisor.analyze(s);
      expect(a.avoid.map((e) => e.id), contains('cpu_governor_perf'));
      expect(a.recommended.map((e) => e.id), isNot(contains('gpu_perf')));
    });
  });
}
