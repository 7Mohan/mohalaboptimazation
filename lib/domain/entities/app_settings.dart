import '../../domain/entities/theme_preference.dart';

/// Language preference — architecture-ready, single locale for now.
enum LanguagePreference {
  systemDefault('System Default', null),
  english('English', 'en');

  const LanguagePreference(this.label, this.languageCode);
  final String label;
  final String? languageCode; // null = follow system
}

/// Default behaviour when entering the optimization workflow.
enum DefaultOptimizationBehaviour {
  askEveryTime('Ask Every Time',
      'Show the full optimization wizard each session'),
  useLastProfile('Use Last Profile',
      'Re-apply the most recently used profile without confirmation'),
  skipToReview('Skip to Review',
      'Jump straight to the proposed-changes review step');

  const DefaultOptimizationBehaviour(this.label, this.description);
  final String label;
  final String description;
}

/// Controls how aggressively the performance monitor samples metrics.
enum PerformanceMonitoringMode {
  disabled('Disabled', 'No background sampling'),
  minimal('Minimal', 'Battery-friendly: sample every 5 seconds'),
  balanced('Balanced', 'Sample every 2 seconds (recommended)'),
  detailed('Detailed', 'Sample every 500ms — may increase battery use');

  const PerformanceMonitoringMode(this.label, this.description);
  final String label;
  final String description;
}

/// Whether the network test runs automatically on the diagnostics screen.
enum NetworkTestAutoRun {
  never('Never', 'Require manual tap to start'),
  onWifiOnly('Wi-Fi Only', 'Auto-run when connected to Wi-Fi'),
  always('Always', 'Auto-run on any connection type');

  const NetworkTestAutoRun(this.label, this.description);
  final String label;
  final String description;
}

/// Immutable value object representing all user-configurable app settings.
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.language = LanguagePreference.systemDefault,
    this.notificationsEnabled = true,
    this.defaultOptimizationBehaviour =
        DefaultOptimizationBehaviour.askEveryTime,
    this.performanceMonitoringMode = PerformanceMonitoringMode.balanced,
    this.networkTestAutoRun = NetworkTestAutoRun.never,
    this.crashReportingOptIn = false,
  });

  final ThemePreference theme;
  final LanguagePreference language;

  /// Whether in-app notification banners are shown (e.g. optimization complete).
  final bool notificationsEnabled;

  final DefaultOptimizationBehaviour defaultOptimizationBehaviour;
  final PerformanceMonitoringMode performanceMonitoringMode;
  final NetworkTestAutoRun networkTestAutoRun;

  /// Opt-in only. Defaults to false. Never enabled silently.
  final bool crashReportingOptIn;

  AppSettings copyWith({
    ThemePreference? theme,
    LanguagePreference? language,
    bool? notificationsEnabled,
    DefaultOptimizationBehaviour? defaultOptimizationBehaviour,
    PerformanceMonitoringMode? performanceMonitoringMode,
    NetworkTestAutoRun? networkTestAutoRun,
    bool? crashReportingOptIn,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultOptimizationBehaviour:
          defaultOptimizationBehaviour ?? this.defaultOptimizationBehaviour,
      performanceMonitoringMode:
          performanceMonitoringMode ?? this.performanceMonitoringMode,
      networkTestAutoRun: networkTestAutoRun ?? this.networkTestAutoRun,
      crashReportingOptIn: crashReportingOptIn ?? this.crashReportingOptIn,
    );
  }

  Map<String, dynamic> toMap() => {
        'theme': theme.name,
        'language': language.name,
        'notificationsEnabled': notificationsEnabled,
        'defaultOptimizationBehaviour': defaultOptimizationBehaviour.name,
        'performanceMonitoringMode': performanceMonitoringMode.name,
        'networkTestAutoRun': networkTestAutoRun.name,
        'crashReportingOptIn': crashReportingOptIn,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      theme: _enumFrom(ThemePreference.values, map['theme'],
          ThemePreference.system),
      language: _enumFrom(LanguagePreference.values, map['language'],
          LanguagePreference.systemDefault),
      notificationsEnabled: map['notificationsEnabled'] is bool
          ? map['notificationsEnabled'] as bool
          : true,
      defaultOptimizationBehaviour: _enumFrom(
          DefaultOptimizationBehaviour.values,
          map['defaultOptimizationBehaviour'],
          DefaultOptimizationBehaviour.askEveryTime),
      performanceMonitoringMode: _enumFrom(
          PerformanceMonitoringMode.values,
          map['performanceMonitoringMode'],
          PerformanceMonitoringMode.balanced),
      networkTestAutoRun: _enumFrom(NetworkTestAutoRun.values,
          map['networkTestAutoRun'], NetworkTestAutoRun.never),
      crashReportingOptIn: map['crashReportingOptIn'] is bool
          ? map['crashReportingOptIn'] as bool
          : false,
    );
  }

  static T _enumFrom<T extends Enum>(
      List<T> values, dynamic raw, T fallback) {
    if (raw is! String) return fallback;
    return values.firstWhere((e) => e.name == raw, orElse: () => fallback);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          theme == other.theme &&
          language == other.language &&
          notificationsEnabled == other.notificationsEnabled &&
          defaultOptimizationBehaviour == other.defaultOptimizationBehaviour &&
          performanceMonitoringMode == other.performanceMonitoringMode &&
          networkTestAutoRun == other.networkTestAutoRun &&
          crashReportingOptIn == other.crashReportingOptIn;

  @override
  int get hashCode => Object.hash(theme, language, notificationsEnabled,
      defaultOptimizationBehaviour, performanceMonitoringMode,
      networkTestAutoRun, crashReportingOptIn);
}
