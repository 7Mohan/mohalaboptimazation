/// Lifecycle state of a single ad load/show cycle.
///
/// Transitions:
///   idle -> loading -> ready -> showing -> idle
///                   -> failed -> idle
///   (disabled skips all transitions)
enum AdState {
  /// Initial state; no load has been requested yet.
  idle,

  /// SDK load request has been dispatched; waiting for callback.
  loading,

  /// Ad is loaded and ready to be shown.
  ready,

  /// Ad is currently being presented to the user.
  showing,

  /// Load or show failed. The service will not retry automatically.
  /// The next natural trigger will attempt a fresh load.
  failed,

  /// Ads are disabled (Pro mode, policy override, or test suppression).
  disabled,
}
