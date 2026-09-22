import '../../../games/domain/entities/game_profile_entity.dart';
import 'optimization_capability.dart';

/// Risk level classification for safe optimizations.
enum OptimizationRiskLevel {
  /// Completely safe operation with no potential side-effects or system state disruption.
  none('No Risk', 'Zero side-effects; completely harmless to system stability'),

  /// Low risk; minor user experience changes like altered animation timing or silent notifications.
  low('Low Risk', 'Temporary behavioral change; fully reversible without restart'),

  /// Medium risk; adjusts background resource constraints or refresh frequency.
  medium('Medium Risk', 'May affect background application resumption or battery consumption'),

  /// High risk; prohibited from automated execution in this framework.
  high('High Risk', 'Potentially destabilizing; requires explicit manual intervention');

  const OptimizationRiskLevel(this.label, this.description);
  final String label;
  final String description;
}

/// Verification method used to ensure an optimization was successfully applied.
enum VerificationMethod {
  /// Verifies state via system settings query (e.g., Settings.Global).
  settingsVerification('Settings Verification', 'Queries system settings to verify parameter changes'),

  /// Verifies memory delta or system process state via ActivityManager.
  memoryStateVerification('Memory State Verification', 'Checks available memory or process trim signals'),

  /// Verifies notification policy manager state.
  notificationPolicyVerification('Policy Verification', 'Probes NotificationManager interruption filter'),

  /// Verifies display mode or refresh rate parameters.
  displayModeVerification('Display Mode Verification', 'Queries current display refresh rate and limits'),

  /// Custom programmatic verification callback.
  custom('Custom Verification', 'Runs specific verification routine');

  const VerificationMethod(this.label, this.description);
  final String label;
  final String description;
}

/// Defines a concrete, safe Android system optimization.
///
/// Every optimization MUST provide honest explanations for what will change,
/// why it helps, and what risk exists, without promising artificial FPS increases.
class OptimizationDefinition {
  const OptimizationDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requiredCapability,
    required this.riskLevel,
    required this.minAndroidSdk,
    this.maxAndroidSdk,
    required this.isReversible,
    this.requiredPermission,
    required this.verificationMethod,
    required this.whatWillChange,
    required this.whyItHelps,
    required this.whatRiskExists,
    this.defaultParameters = const {},
  });

  /// Unique immutable identifier for this optimization (e.g., 'ram_trim_caches').
  final String id;

  /// User-facing display title.
  final String name;

  /// Detailed technical description of the optimization mechanism.
  final String description;

  /// The category this optimization belongs to.
  final OptimizationCategory category;

  /// System or platform capability required to perform this optimization.
  final OptimizationCapability requiredCapability;

  /// Risk classification. High risk optimizations are prohibited.
  final OptimizationRiskLevel riskLevel;

  /// Minimum Android API level (SDK int) required for this optimization.
  final int minAndroidSdk;

  /// Maximum Android API level if an API was deprecated or restricted in newer versions.
  final int? maxAndroidSdk;

  /// Whether the changes made by this optimization can be rolled back to pre-execution state.
  final bool isReversible;

  /// Specific Android or platform permission string required (null if unprivileged).
  final String? requiredPermission;

  /// The method used to verify that the optimization executed successfully.
  final VerificationMethod verificationMethod;

  /// Transparent UX disclosure: exact parameters, settings, or processes modified.
  final String whatWillChange;

  /// Transparent UX disclosure: honest explanation of potential benefit (e.g. "May reduce background activity").
  final String whyItHelps;

  /// Transparent UX disclosure: any trade-off or risk involved (e.g. "Background apps may reload when reopened").
  final String whatRiskExists;

  /// Optional default configuration parameters.
  final Map<String, dynamic> defaultParameters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizationDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OptimizationDefinition(id: $id, name: $name, risk: ${riskLevel.name})';
}
