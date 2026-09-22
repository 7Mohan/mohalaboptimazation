/// Route name constants for GoRouter.
///
/// Use these constants instead of raw strings throughout the codebase
/// to prevent typo-related navigation bugs.
library;

abstract final class RouteNames {
  RouteNames._();

  static const String home = '/';
  static const String games = '/games';
  static const String optimization = '/optimization';
  static const String performance = '/performance';
  static const String diagnostics = '/diagnostics';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String network = '/network';
  static const String dataManagement = '/settings/data';
  static const String onboarding = '/onboarding';
}
