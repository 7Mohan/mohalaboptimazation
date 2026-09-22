import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_configuration.dart';
import 'ad_service.dart';

/// Provides the active [AdConfiguration].
///
/// In debug/profile builds this automatically selects test IDs.
/// In release builds this selects production IDs.
///
/// Override in tests to inject [AdConfiguration.test()] explicitly.
final adConfigurationProvider = Provider<AdConfiguration>((ref) {
  return AdConfiguration.forCurrentBuild();
});

/// Provides the initialized [AdServiceBase] singleton.
///
/// Override in widget tests by injecting [FakeAdService]:
/// ```dart
/// ProviderScope(
///   overrides: [
///     adServiceProvider.overrideWithValue(FakeAdService()),
///   ],
///   child: ...,
/// )
/// ```
///
/// The real [AdService] is initialized by calling [AdServiceBase.initialize]
/// in main.dart before runApp.
final adServiceProvider = Provider<AdServiceBase>((ref) {
  final config = ref.watch(adConfigurationProvider);
  final service = AdService(configuration: config);
  ref.onDispose(service.dispose);
  return service;
});
