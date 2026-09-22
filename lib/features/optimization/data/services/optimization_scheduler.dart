import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../settings/presentation/providers/theme_provider.dart';

const _kScheduledOptEnabledKey = 'scheduled_opt_enabled_v1';
const _kScheduledOptIntervalKey = 'scheduled_opt_interval_hours_v1';
const _kScheduledOptProfileKey = 'scheduled_opt_profile_v1';
const _kScheduledOptTaskName = 'moha_scheduled_auto_optimization';

class ScheduledOptConfig {
  const ScheduledOptConfig({
    this.enabled = false,
    this.intervalHours = 12,
    this.profileId = 'balanced',
  });

  final bool enabled;
  final int intervalHours;
  final String profileId;

  ScheduledOptConfig copyWith({
    bool? enabled,
    int? intervalHours,
    String? profileId,
  }) {
    return ScheduledOptConfig(
      enabled: enabled ?? this.enabled,
      intervalHours: intervalHours ?? this.intervalHours,
      profileId: profileId ?? this.profileId,
    );
  }
}

class OptimizationSchedulerNotifier extends StateNotifier<ScheduledOptConfig> {
  OptimizationSchedulerNotifier(this._prefs)
      : super(
          ScheduledOptConfig(
            enabled: _prefs?.getBool(_kScheduledOptEnabledKey) ?? false,
            intervalHours: _prefs?.getInt(_kScheduledOptIntervalKey) ?? 12,
            profileId: _prefs?.getString(_kScheduledOptProfileKey) ?? 'balanced',
          ),
        );

  final SharedPreferences? _prefs;

  Future<void> setEnabled(bool enabled) async {
    await _prefs?.setBool(_kScheduledOptEnabledKey, enabled);
    state = state.copyWith(enabled: enabled);

    try {
      if (enabled) {
        await Workmanager().registerPeriodicTask(
          _kScheduledOptTaskName,
          _kScheduledOptTaskName,
          frequency: Duration(hours: state.intervalHours),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.not_required,
            requiresBatteryNotLow: true,
          ),
        );
      } else {
        await Workmanager().cancelByUniqueName(_kScheduledOptTaskName);
      }
    } catch (_) {
      // Background worker graceful fallback
    }
  }

  Future<void> setIntervalHours(int hours) async {
    await _prefs?.setInt(_kScheduledOptIntervalKey, hours);
    state = state.copyWith(intervalHours: hours);
    if (state.enabled) {
      await setEnabled(true);
    }
  }

  Future<void> setProfile(String profileId) async {
    await _prefs?.setString(_kScheduledOptProfileKey, profileId);
    state = state.copyWith(profileId: profileId);
  }
}

final optimizationSchedulerProvider =
    StateNotifierProvider<OptimizationSchedulerNotifier, ScheduledOptConfig>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return OptimizationSchedulerNotifier(prefs);
});

