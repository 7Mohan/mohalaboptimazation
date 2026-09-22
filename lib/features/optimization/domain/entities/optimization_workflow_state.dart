import '../../../games/domain/entities/game_entity.dart';
import '../../../games/domain/entities/game_profile_entity.dart';
import 'optimization_outcome.dart';
import 'pre_flight_report.dart';

/// Sealed class hierarchy representing every possible step in the optimization
/// workflow wizard.  The notifier holds exactly one of these at a time.
sealed class OptimizationWorkflowStep {
  const OptimizationWorkflowStep();
}

/// Step 1 — user picks a game from the installed library.
final class WorkflowStepSelectGame extends OptimizationWorkflowStep {
  const WorkflowStepSelectGame({this.selectedGame});
  final GameEntity? selectedGame;
}

/// Step 2 — user picks or confirms the optimization profile for the game.
final class WorkflowStepSelectProfile extends OptimizationWorkflowStep {
  const WorkflowStepSelectProfile({
    required this.game,
    this.selectedProfile,
  });
  final GameEntity game;
  final GameProfile? selectedProfile;
}

/// Step 3 — pre-flight checks run asynchronously.
final class WorkflowStepPreFlight extends OptimizationWorkflowStep {
  const WorkflowStepPreFlight({
    required this.game,
    required this.profile,
    this.isRunning = true,
    this.report,
  });
  final GameEntity game;
  final GameProfile profile;
  final bool isRunning;
  final PreFlightReport? report;
}

/// Step 4 — list of proposed changes shown to the user before confirmation.
final class WorkflowStepReview extends OptimizationWorkflowStep {
  const WorkflowStepReview({
    required this.game,
    required this.profile,
    required this.report,
    required this.proposedIds,
    required this.skippedOutcomes,
  });
  final GameEntity game;
  final GameProfile profile;
  final PreFlightReport report;

  /// IDs of optimizations that will be executed (passed pre-flight).
  final List<String> proposedIds;

  /// Optimizations already resolved to Skipped/Unavailable before execution.
  final List<OptimizationOutcome> skippedOutcomes;
}

/// Step 5 — user must explicitly confirm before execution begins.
final class WorkflowStepConfirmation extends OptimizationWorkflowStep {
  const WorkflowStepConfirmation({
    required this.game,
    required this.profile,
    required this.report,
    required this.proposedIds,
    required this.skippedOutcomes,
  });
  final GameEntity game;
  final GameProfile profile;
  final PreFlightReport report;
  final List<String> proposedIds;
  final List<OptimizationOutcome> skippedOutcomes;
}

/// Step 6 — execution in progress; updated per-optimization.
final class WorkflowStepExecuting extends OptimizationWorkflowStep {
  const WorkflowStepExecuting({
    required this.game,
    required this.profile,
    required this.totalCount,
    required this.completedCount,
    this.currentOptimizationName,
    this.currentStageLabel,
    this.completedOutcomes = const [],
  });
  final GameEntity game;
  final GameProfile profile;
  final int totalCount;
  final int completedCount;
  final String? currentOptimizationName;
  final String? currentStageLabel;
  final List<OptimizationOutcome> completedOutcomes;

  double get progress =>
      totalCount == 0 ? 0 : completedCount / totalCount;
}

/// Step 7 — final result with per-optimization outcome and optional rollback.
final class WorkflowStepResult extends OptimizationWorkflowStep {
  const WorkflowStepResult({
    required this.game,
    required this.profile,
    required this.outcomes,
    this.isRollingBack = false,
    this.rollbackCompleted = false,
  });
  final GameEntity game;
  final GameProfile profile;
  final List<OptimizationOutcome> outcomes;
  final bool isRollingBack;
  final bool rollbackCompleted;

  bool get canRollback => outcomes.any((o) => o.hasRollback);
  int get completedCount =>
      outcomes.where((o) => o.status == OutcomeStatus.completed).length;
  int get skippedCount =>
      outcomes.where((o) => o.status == OutcomeStatus.skipped).length;
  int get unavailableCount =>
      outcomes.where((o) => o.status == OutcomeStatus.unavailable).length;
  int get failedCount =>
      outcomes.where((o) => o.status == OutcomeStatus.failed).length;
}
