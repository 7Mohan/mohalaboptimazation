import '../entities/optimization_definition.dart';

/// Result of validating an optimization definition and its execution parameters.
class ValidationReport {
  const ValidationReport({
    required this.isValid,
    this.reason,
    this.isProhibited = false,
  });

  const ValidationReport.valid()
      : isValid = true,
        reason = null,
        isProhibited = false;

  const ValidationReport.invalid(String this.reason)
      : isValid = false,
        isProhibited = false;

  const ValidationReport.prohibited(String this.reason)
      : isValid = false,
        isProhibited = true;

  final bool isValid;
  final String? reason;
  final bool isProhibited;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $reason (prohibited: $isProhibited)';
}

/// Enforces platform constraints, parameter validity, and strict safety rules
/// prohibiting benchmark manipulation, frequency spoofing, thermal tampering,
/// and arbitrary shell execution.
class OptimizationValidator {
  const OptimizationValidator();

  /// Prohibited keywords and mechanisms that must NEVER be allowed.
  static const _prohibitedPatterns = [
    'spoof_cpu',
    'spoof_gpu',
    'fake_fps',
    'disable_thermal',
    'disable_throttling',
    'benchmark_cheat',
    'bypass_drm',
    'bypass_anticheat',
    'arbitrary_shell',
    'rm -rf',
    'chmod 777',
    'setenforce 0',
  ];

  /// Validates an [OptimizationDefinition] against device SDK version and parameter bounds.
  ValidationReport validate({
    required OptimizationDefinition definition,
    required int currentSdkInt,
    Map<String, dynamic> parameters = const {},
  }) {
    // 1. Prohibited safety rules check
    final safetyCheck = checkSafety(definition, parameters);
    if (!safetyCheck.isValid) {
      return safetyCheck;
    }

    // 2. High-risk prohibition check
    if (definition.riskLevel == OptimizationRiskLevel.high) {
      return const ValidationReport.prohibited(
        'High-risk system modifications are strictly prohibited by the safety policy.',
      );
    }

    // 3. Android SDK minimum bound check
    if (currentSdkInt < definition.minAndroidSdk) {
      return ValidationReport.invalid(
        'Requires Android SDK ${definition.minAndroidSdk} or higher. Current device is API $currentSdkInt.',
      );
    }

    // 4. Android SDK maximum bound check (if specified)
    if (definition.maxAndroidSdk != null && currentSdkInt > definition.maxAndroidSdk!) {
      return ValidationReport.invalid(
        'Incompatible with Android SDK $currentSdkInt. Maximum supported API is ${definition.maxAndroidSdk}.',
      );
    }

    // 5. Parameter boundaries validation
    final paramCheck = validateParameters(definition.id, parameters);
    if (!paramCheck.isValid) {
      return paramCheck;
    }

    return const ValidationReport.valid();
  }

  /// Verifies that an optimization does not violate core security and safety boundaries.
  ValidationReport checkSafety(
    OptimizationDefinition definition, [
    Map<String, dynamic> parameters = const {},
  ]) {
    final lowerId = definition.id.toLowerCase();
    final lowerName = definition.name.toLowerCase();
    final lowerDesc = definition.description.toLowerCase();

    for (final pattern in _prohibitedPatterns) {
      if (lowerId.contains(pattern) ||
          lowerName.contains(pattern) ||
          lowerDesc.contains(pattern)) {
        return ValidationReport.prohibited(
          'Security policy violation: Optimization violates prohibited mechanism "$pattern".',
        );
      }
    }

    // Inspect parameter strings for arbitrary shell command injection
    for (final entry in parameters.entries) {
      if (entry.value is String) {
        final val = (entry.value as String).toLowerCase();
        for (final pattern in _prohibitedPatterns) {
          if (val.contains(pattern)) {
            return ValidationReport.prohibited(
              'Security policy violation: Parameter "${entry.key}" contains prohibited token "$pattern".',
            );
          }
        }
      }
    }

    return const ValidationReport.valid();
  }

  /// Validates known parameter ranges for specific optimization types.
  ValidationReport validateParameters(String optimizationId, Map<String, dynamic> parameters) {
    switch (optimizationId) {
      case 'window_animation_scale':
        // Animation scales must be between 0.0 and 2.0
        final scale = parameters['scale'];
        if (scale != null) {
          if (scale is! num || scale < 0.0 || scale > 2.0) {
            return const ValidationReport.invalid(
              'Animation scale parameter must be a number between 0.0 and 2.0.',
            );
          }
        }
        break;

      case 'peak_refresh_rate':
        final rate = parameters['targetRefreshRate'];
        if (rate != null) {
          if (rate is! num || rate < 30.0 || rate > 240.0) {
            return const ValidationReport.invalid(
              'Refresh rate must be between 30 Hz and 240 Hz.',
            );
          }
        }
        break;
    }

    return const ValidationReport.valid();
  }
}
