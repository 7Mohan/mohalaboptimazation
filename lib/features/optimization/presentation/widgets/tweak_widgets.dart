import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';
import '../providers/long_task_provider.dart';
import '../providers/tweak_providers.dart';
import 'long_task_sheet.dart';

void showTweakResult(BuildContext context, TweakResult result, {String? prefix}) {
  final text = [
    if (prefix != null) prefix,
    result.message,
    if (result.freedBytes != null) '· ${formatBytes(result.freedBytes!)} freed',
  ].join(' ');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: result.success ? AppColors.success : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
}

/// One switchable tweak row. The switch reflects the device's real state and
/// snaps back if Android rejects the change.
class TweakTile extends ConsumerWidget {
  const TweakTile({super.key, required this.definition});

  final TweakDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(tweaksControllerProvider).valueOrNull ?? const TweaksSnapshot();
    final state = snapshot.stateOf(definition.id);
    final busy = snapshot.isBusy(definition.id);
    final canRun = snapshot.canRun(definition);
    final active = state.active;

    String? blocker;
    if (snapshot.capabilities.sdkInt > 0 && snapshot.capabilities.sdkInt < definition.minSdk) {
      blocker = 'Needs Android API ${definition.minSdk}+';
    } else if (!state.supported) {
      blocker = state.detail ?? 'Not supported on this device';
    } else if (!snapshot.capabilities.allows(definition.access)) {
      blocker = 'Needs ${definition.access.label}';
    }

    Future<void> toggle(bool value) async {
      HapticFeedback.lightImpact();
      final res = await ref.read(tweaksControllerProvider.notifier).setEnabled(definition.id, value);
      if (context.mounted && !res.success) showTweakResult(context, res);
    }

    return InkWell(
      onTap: () => showTweakDetails(context, definition),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.sm, 14),
        child: Row(
          children: [
            GlassIconTile(
              icon: definition.category.icon,
              active: active,
              color: active ? theme.colorScheme.tertiary : theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blocker ?? (active && state.detail != null ? 'Active · ${state.detail}' : definition.summary),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: blocker != null
                          ? theme.colorScheme.error.withOpacity(0.85)
                          : active
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 56,
              height: 40,
              child: Center(
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Switch(
                        value: active,
                        onChanged: canRun || active ? toggle : null,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showTweakDetails(BuildContext context, TweakDefinition def) {
  final theme = Theme.of(context);
  MohaBottomSheet.show(
    context: context,
    title: def.title,
    subtitle: '${def.category.label} · ${def.impact.label} impact',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(def.summary, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
        const SizedBox(height: AppSpacing.md),
        _DetailBlock(
          icon: Icons.terminal_rounded,
          title: 'Exactly what changes',
          child: Text(
            def.changes,
            style: AppTypography.monoStyle(fontSize: 12, color: theme.colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailBlock(
          icon: Icons.balance_rounded,
          title: 'Trade-off',
          child: Text(def.tradeoff, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailBlock(
          icon: Icons.restore_rounded,
          title: 'Reversible',
          child: Text(
            'Your original values are saved on the device before the first change and restored '
            'when you switch this off — even after restarting the app. '
            '${def.persistsReboot ? 'Survives reboots.' : 'Android resets this on reboot; the app re-applies it when Shizuku reconnects.'}',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailBlock(
          icon: Icons.key_rounded,
          title: 'Requires',
          child: Text(
            '${def.access.label} · Android API ${def.minSdk}+',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: AppSpacing.cardPaddingCompact,
      borderRadius: BorderRadius.circular(16),
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Square glass button for a measured one-shot action.
class TweakActionButton extends ConsumerWidget {
  const TweakActionButton({super.key, required this.action});

  final TweakAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(tweaksControllerProvider).valueOrNull ?? const TweaksSnapshot();
    final longTask = action.longRunning ? ref.watch(longTaskProvider) : null;
    final longRunning = longTask != null && longTask.running && longTask.task == action.id;
    final busy = snapshot.isBusy(action.id) || longRunning;
    final allowed = snapshot.capabilities.allows(action.access);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: !allowed || (busy && !action.longRunning)
          ? null
          : () async {
              if (action.longRunning) {
                await LongTaskSheet.show(context, action);
                return;
              }
              final res = await ref.read(tweaksControllerProvider.notifier).runAction(action.id);
              if (context.mounted) showTweakResult(context, res);
            },
      child: Opacity(
        opacity: allowed ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassIconTile(icon: action.icon, size: 34),
                const Spacer(),
                if (busy)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, value: longTask?.progress),
                  )
                else
                  Icon(
                    allowed ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              action.title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              !allowed
                  ? 'Needs ${action.access.label}'
                  : longRunning
                      ? (longTask.progress != null
                          ? '${(longTask.progress! * 100).round()}% · ${longTask.label ?? 'working'}'
                          : 'Running… tap to view')
                      : action.summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable preset pill.
class PresetChip extends StatelessWidget {
  const PresetChip({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final TweakPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme.primary;
    return GlassCard(
      level: selected ? AppGlassLevel.level3 : AppGlassLevel.level2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(preset.icon, color: selected ? c : theme.colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(height: 6),
          Text(
            preset.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? c : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
