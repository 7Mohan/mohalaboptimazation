import 'optimization_definition.dart';

/// The three global optimization profiles the user can select.
enum OptimizationProfile {
  balanced(
    id: 'balanced',
    label: 'Balanced',
    description: 'Only zero-risk tools. Recommended for daily use.',
    icon: '⚖',
  ),
  extreme(
    id: 'extreme',
    label: 'Extreme',
    description: 'Zero + low-risk tools. More aggressive tuning.',
    icon: '⚡',
  ),
  batterySaver(
    id: 'battery_saver',
    label: 'Battery Saver',
    description: 'Only disturbance blocker + RAM trim. Maximises battery life.',
    icon: '🔋',
  );

  const OptimizationProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final String icon;

  /// Returns whether this profile should apply a given optimization definition.
  /// High-risk tools are always excluded.
  bool shouldApply(OptimizationDefinition def) {
    switch (this) {
      case OptimizationProfile.balanced:
        return def.riskLevel == OptimizationRiskLevel.none;
      case OptimizationProfile.extreme:
        return def.riskLevel == OptimizationRiskLevel.none ||
            def.riskLevel == OptimizationRiskLevel.low;
      case OptimizationProfile.batterySaver:
        return def.id == 'gaming_dnd_zen' || def.id == 'ram_trim_caches';
    }
  }
}
