import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/presentation/providers/theme_provider.dart';

const _kOnboardingCompletedKey = 'has_completed_onboarding_v1';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._prefs)
      : super(_prefs.getBool(_kOnboardingCompletedKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_kOnboardingCompletedKey, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(_kOnboardingCompletedKey, false);
    state = false;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});
