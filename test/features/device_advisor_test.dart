import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/features/optimization/domain/device_advisor.dart';
import 'package:mohalab_optimization/features/optimization/domain/tweak_catalog.dart';

void main() {
  Set<String> recIds(DeviceAdvice a) => a.recommended.map((e) => e.id).toSet();
  Set<String> avoidIds(DeviceAdvice a) => a.avoid.map((e) => e.id).toSet();

  const coolFlagship = DeviceSignals(
    sdkInt: 36,
    ramGb: 12,
    availableRamPercent: 60,
    cpuCores: 8,
    maxCpuGhz: 3.2,
    maxRefreshHz: 144,
    batteryPercent: 80,
    batteryTempC: 31,
    thermalStatus: 0,
    thermalHeadroom: 0.3,
    storageFreePercent: 55,
    onWifi: true,
  );

  test('tiers are derived from RAM and CPU', () {
    expect(coolFlagship.tier, DeviceTier.flagship);
    expect(const DeviceSignals(ramGb: 4, maxCpuGhz: 2.0, cpuCores: 8).tier, DeviceTier.entry);
    expect(const DeviceSignals(ramGb: 8, maxCpuGhz: 2.4, cpuCores: 8).tier, DeviceTier.midRange);
  });

  test('cool flagship on Wi-Fi gets refresh lock, stable clocks and Wi-Fi latency', () {
    final a = DeviceAdvisor.analyze(coolFlagship);
    expect(recIds(a), containsAll(['refresh_rate_lock', 'fixed_performance', 'wifi_low_latency']));
    // Flagship GPU does not need the blur trade-off.
    expect(recIds(a), isNot(contains('disable_blurs')));
    expect(a.avoid, isEmpty);
    expect(a.recommended.first.priority, greaterThanOrEqualTo(a.recommended.last.priority));
  });

  test('hot phone: fixed performance is flagged to skip, with the temperature', () {
    const hot = DeviceSignals(sdkInt: 34, ramGb: 8, maxCpuGhz: 2.4, batteryTempC: 44.2, thermalStatus: 2);
    final a = DeviceAdvisor.analyze(hot);
    expect(avoidIds(a), contains('fixed_performance'));
    expect(recIds(a), isNot(contains('fixed_performance')));
    expect(a.avoid.first.reason, contains('44.2'));
  });

  test('low battery skips power-hungry tweaks and suggests stopping scans', () {
    const low = DeviceSignals(sdkInt: 34, maxRefreshHz: 120, batteryPercent: 12);
    final a = DeviceAdvisor.analyze(low);
    expect(avoidIds(a), containsAll(['refresh_rate_lock', 'fixed_performance']));
    expect(recIds(a), contains('scan_off'));
  });

  test('entry device with little free RAM and storage gets maintenance actions', () {
    const entry = DeviceSignals(
      sdkInt: 33,
      ramGb: 4,
      availableRamPercent: 18,
      cpuCores: 8,
      maxCpuGhz: 1.8,
      storageFreePercent: 8,
    );
    final a = DeviceAdvisor.analyze(entry);
    expect(recIds(a), containsAll(['ram_boost', 'trim_caches', 'disable_blurs', 'animation_scale']));
    expect(recIds(a), isNot(contains('wifi_low_latency')), reason: 'not on Wi-Fi');
    // Tight storage → smaller profile-guided compile.
    expect(a.compile.maxSpeed, isFalse);
    expect(a.compile.gamesOnly, isTrue);
  });

  test('gaming compile advice is games-only full speed when storage allows', () {
    final a = DeviceAdvisor.analyze(coolFlagship);
    expect(a.compile.gamesOnly, isTrue);
    expect(a.compile.compilerFilter, 'speed');
    expect(recIds(a), contains(TweakCatalog.compileApps.id));
  });

  test('old Android versions never get tweaks they cannot run', () {
    const old = DeviceSignals(sdkInt: 29, maxRefreshHz: 90, onWifi: true, ramGb: 6, maxCpuGhz: 2.2);
    final ids = recIds(DeviceAdvisor.analyze(old));
    expect(ids, isNot(contains('refresh_rate_lock'))); // API 30+
    expect(ids, isNot(contains('fixed_performance'))); // API 31+
    expect(ids, isNot(contains('wifi_low_latency'))); // API 31+
    expect(ids, isNot(contains('disable_blurs'))); // API 31+
  });

  test('recommended tweak ids exclude actions', () {
    final a = DeviceAdvisor.analyze(coolFlagship);
    expect(a.recommendedTweakIds.every((id) => TweakCatalog.byId(id) != null), isTrue);
  });
}
