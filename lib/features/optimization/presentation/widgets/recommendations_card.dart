import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../domain/device_advisor.dart';
import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';
import '../providers/device_advice_provider.dart';
import '../providers/tweak_providers.dart';
import 'long_task_sheet.dart';
import 'tweak_widgets.dart';

/// Scans the device and lists the tweaks worth turning on — and the ones to
/// skip right now — each with the measured reason.
class RecommendationsCard extends ConsumerStatefulWidget {
  const RecommendationsCard({super.key});

  @override
  ConsumerState<RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends ConsumerState<RecommendationsCard> {
  static const _collapsedCount = 4;
  bool _expanded = false;
  bool _applying = false;

  Future<void> _applyAll(DeviceAdvice advice) async {
    HapticFeedback.mediumImpact();
    setState(() => _applying = true);
    final (ok, attempted) = await ref
        .read(tweaksControllerProvider.notifier)
        .applyRecommended(advice.recommendedTweakIds);
    if (!mounted) return;
    setState(() => _applying = false);
    showTweakResult(
      context,
      TweakResult(
        success: ok == attempted,
        message: attempted == 0
            ? 'All recommended tweaks are already on'
            : '$ok of $attempted recommended tweaks applied',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final async = ref.watch(deviceAdviceProvider);
    final snapshot = ref.watch(tweaksControllerProvider).valueOrNull ?? const TweaksSnapshot();

    return GlassCard(
      level: AppGlassLevel.level3,
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: async.when(
          loading: () => const _Scanning(),
          error: (e, _) => Text('Could not analyse this device: $e'),
          data: (advice) {
            // Never recommend what this phone's hardware has proven it lacks.
            final recs = advice.recommended.where((a) {
              final def = TweakCatalog.byId(a.id);
              return def == null || snapshot.stateOf(def.id).supported;
            }).toList();
            final pending = recs.where((a) {
              final def = TweakCatalog.byId(a.id);
              return def != null && snapshot.canRun(def) && !snapshot.isActive(a.id);
            }).length;
            final visible = _expanded ? recs : recs.take(_collapsedCount).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
                      ),
                      child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recommended for your device',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            '${advice.signals.tier.label} · ${signalsSummary(advice.signals)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Re-scan device',
                      onPressed: () => ref.invalidate(deviceAdviceProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final a in visible) _AdviceRow(advice: a, snapshot: snapshot),
                if (recs.length > _collapsedCount)
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    label: Text(_expanded ? 'Show less' : 'Show all ${recs.length}'),
                  ),
                if (advice.avoid.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'SKIP FOR NOW',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  for (final a in advice.avoid) _AdviceRow(advice: a, snapshot: snapshot),
                ],
                const SizedBox(height: AppSpacing.sm),
                _ApplyButton(
                  label: _applying
                      ? 'Applying…'
                      : pending == 0
                          ? 'Recommended tweaks are on'
                          : 'Apply $pending recommended tweak${pending == 1 ? '' : 's'}',
                  busy: _applying,
                  onPressed: _applying || pending == 0 ? null : () => _applyAll(advice),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Analysing RAM, CPU, display, thermals, battery and network…',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceRow extends ConsumerWidget {
  const _AdviceRow({required this.advice, required this.snapshot});

  final Advice advice;
  final TweaksSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final def = TweakCatalog.byId(advice.id);
    final action =
        advice.isAction ? TweakCatalog.actions.firstWhere((a) => a.id == advice.id) : null;
    final avoid = advice.kind == AdviceKind.avoid;
    final active = def != null && snapshot.isActive(def.id);
    final locked =
        def != null ? !snapshot.canRun(def) : !snapshot.capabilities.allows(action!.access);
    final busy = snapshot.isBusy(advice.id);

    final Widget trailing;
    if (avoid) {
      trailing = const Icon(Icons.do_not_disturb_on_outlined, color: AppColors.warning, size: 20);
    } else if (busy) {
      trailing =
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (active) {
      trailing = Icon(Icons.check_circle_rounded, color: scheme.tertiary, size: 22);
    } else if (locked) {
      trailing = Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant, size: 20);
    } else if (action != null) {
      trailing = TextButton(
        onPressed: () async {
          if (action.longRunning) {
            await LongTaskSheet.show(context, action);
            return;
          }
          final res = await ref.read(tweaksControllerProvider.notifier).runAction(action.id);
          if (context.mounted) showTweakResult(context, res);
        },
        child: const Text('Run'),
      );
    } else {
      trailing = TextButton(
        onPressed: () async {
          final res = await ref.read(tweaksControllerProvider.notifier).setEnabled(def!.id, true);
          if (context.mounted && !res.success) showTweakResult(context, res);
        },
        child: const Text('Turn on'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GlassIconTile(
            icon: def?.category.icon ?? action?.icon ?? Icons.tune_rounded,
            size: 32,
            color: avoid ? AppColors.warning : (active ? scheme.tertiary : scheme.primary),
            active: active,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice.title,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                  locked && !avoid && !active
                      ? '${advice.reason} (needs ${(def?.access ?? action!.access).label})'
                      : advice.reason,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: trailing),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || busy ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            colors: enabled || busy
                ? [scheme.primary, scheme.tertiary]
                : [scheme.surfaceContainerHighest, scheme.surfaceContainerHighest],
          ),
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: scheme.onSurfaceVariant,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(enabled ? Icons.auto_fix_high_rounded : Icons.check_rounded),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
