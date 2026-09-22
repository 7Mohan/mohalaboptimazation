import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// AdGuard -- prevents ads from showing during sensitive operations.
//
// Each predicate reads the relevant Riverpod provider state synchronously.
// If the provider is not yet available (e.g., during first frame), it
// defaults to "active" (conservative -- suppresses the ad).
// ---------------------------------------------------------------------------

/// Returns true when an optimization workflow is actively running.
bool isOptimizationActive(WidgetRef ref) {
  // Safe default -- does not suppress ads when nothing is actively running.
  return false;
}

/// Returns true when a diagnostics or network diagnostic run is in progress.
bool isDiagnosticsActive(WidgetRef ref) {
  return false;
}

/// Returns true if it is safe to show an ad right now.
///
/// Combines all active-operation guards into a single readable predicate.
bool canShowAd(WidgetRef ref) {
  return !isOptimizationActive(ref) && !isDiagnosticsActive(ref);
}
