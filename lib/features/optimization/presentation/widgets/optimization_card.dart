import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/ads/ad_guard.dart';
import '../../../../core/ads/ad_placement.dart';
import '../../../../core/ads/ad_providers.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../domain/entities/optimization_definition.dart';
import '../providers/optimization_providers.dart';

/// Card displaying an optimization tool with complete transparency disclosures,
/// pipeline stage indicators, and instant rollback support.
class OptimizationCard extends ConsumerWidget {
  const OptimizationCard({
    super.key,
    required this.definition,
  });

  final OptimizationDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(optimizationControllerProvider);
    final isExecuting = state.isBusy && state.executingOptimizationId == definition.id;
    final isApplied = state.appliedOptimizationIds.contains(definition.id);

    final isLastResult = state.lastResult != null && state.lastResult!.optimizationId == definition.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isApplied
              ? const Color(0xFF10B981)
              : (isExecuting
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant),
          width: isApplied ? 1.5 : 1.0,
        ),
        boxShadow: isApplied
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailsSheet(context, ref, isApplied),
          borderRadius: AppRadius.radiusLg,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Category icon, Name, Status badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isApplied
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isApplied
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isApplied ? Icons.check_circle_rounded : definition.category.icon,
                        size: AppSizes.iconSm,
                        color: isApplied ? const Color(0xFF10B981) : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            definition.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            definition.category.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isApplied) ...[
                          const MohaStatusBadge(
                            type: MohaStatusType.safe,
                            customLabel: 'Active',
                          ),
                          const SizedBox(width: 6),
                        ],
                        _RiskBadge(risk: definition.riskLevel),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

              // Transparent description & why it helps
              Text(
                definition.whyItHelps,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                definition.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Capabilities and Reversibility row
              Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      definition.requiredCapability.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (definition.isReversible) ...[
                    Icon(
                      Icons.undo_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reversible',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Irreversible',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),

              // Recent Execution Result Feedback Snippet
              if (isLastResult && state.lastResult != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: state.lastResult!.success
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : theme.colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: AppRadius.radiusSm,
                    border: Border.all(
                      color: state.lastResult!.success
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : theme.colorScheme.error.withOpacity(0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.lastResult!.success
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 14,
                        color: state.lastResult!.success
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          state.lastResult!.message,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: state.lastResult!.success
                                ? const Color(0xFF10B981)
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: AppSpacing.lg),

              // Action buttons & Pipeline progress
              if (isExecuting) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Stage: ${state.currentStage?.label ?? "Executing"}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDetailsSheet(context, ref, isApplied),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Disclosures'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    if (isApplied && definition.isReversible) ...[
                      OutlinedButton.icon(
                        key: Key('rollback_${definition.id}'),
                        onPressed: state.isBusy
                            ? null
                            : () async {
                                final res = await ref
                                    .read(optimizationControllerProvider.notifier)
                                    .rollbackOptimization(definition.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Rollback'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        key: Key('apply_${definition.id}'),
                        onPressed: state.isBusy
                            ? null
                            : () async {
                                final res = await ref
                                    .read(optimizationControllerProvider.notifier)
                                    .executeOptimization(id: definition.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.error,
                                    ),
                                  );
                                  // Trigger interstitial at this natural
                                  // completion point — only when no other
                                  // operations are active.
                                  if (res.success) {
                                    ref.read(adServiceProvider).showInterstitial(
                                      AdPlacement.postOptimizationInterstitial,
                                      canShow: canShowAd(ref),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: Text(isApplied ? 'Re-Apply' : 'Apply'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showDetailsSheet(BuildContext context, WidgetRef ref, bool isApplied) {
    final theme = Theme.of(context);

    MohaBottomSheet.show(
      context: context,
      title: definition.name,
      subtitle: definition.category.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DisclosureSection(
            title: 'Why It May Help',
            icon: Icons.lightbulb_outline_rounded,
            content: definition.whyItHelps,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _DisclosureSection(
            title: 'What Will Change',
            icon: Icons.settings_suggest_outlined,
            content: definition.whatWillChange,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          _DisclosureSection(
            title: 'What Risk Exists',
            icon: Icons.warning_amber_rounded,
            content: definition.whatRiskExists,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          _DisclosureSection(
            title: 'Rollback & Reversibility',
            icon: Icons.undo_rounded,
            content: definition.isReversible
                ? 'Fully reversible. Previous configuration snapshots are captured before execution and can be restored at any time.'
                : 'Irreversible directly via this toggle (e.g. cleared memory naturally reallocates as apps run).',
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});
  final OptimizationRiskLevel risk;

  @override
  Widget build(BuildContext context) {
    final (type, label) = switch (risk) {
      OptimizationRiskLevel.none => (MohaStatusType.safe, 'No Risk'),
      OptimizationRiskLevel.low => (MohaStatusType.safe, 'Low Risk'),
      OptimizationRiskLevel.medium => (MohaStatusType.shizuku, 'Medium Risk'),
      OptimizationRiskLevel.high => (MohaStatusType.root, 'Prohibited'),
    };

    return MohaStatusBadge(type: type, customLabel: label);
  }
}

class _DisclosureSection extends StatelessWidget {
  const _DisclosureSection({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  final String title;
  final IconData icon;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPaddingCompact,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
