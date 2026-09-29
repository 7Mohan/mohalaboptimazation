import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/ad_guard.dart';
import '../../../../core/ads/ad_placement.dart';
import '../../../../core/ads/ad_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../onboarding/presentation/tour/feature_tour.dart';
import '../../../shizuku/presentation/widgets/shizuku_status_banner.dart';
import '../../domain/tweak.dart';
import '../../domain/tweak_catalog.dart';
import '../providers/tweak_providers.dart';
import '../widgets/recommendations_card.dart';
import '../widgets/share_results_card.dart';
import '../widgets/tweak_widgets.dart';

/// The single hub for every system tweak, preset and maintenance action.
class OptimizationScreen extends ConsumerWidget {
  const OptimizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tweaksControllerProvider);
    final snapshot = async.valueOrNull ?? const TweaksSnapshot();
    final preset = ref.watch(selectedPresetProvider);
    final rootView = ref.watch(rootViewProvider) ?? snapshot.capabilities.hasRoot;

    return Scaffold(
      appBar: MohaAppBar(
        title: 'Tweaks',
        subtitle: 'Real Android settings · verified on device',
        actions: [
          IconButton(
            tooltip: 'Share results',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => ShareResultsHelper.captureAndShare(
              context: context,
              profileName: preset?.label ?? 'Custom',
              toolsCount: snapshot.activeCount,
              deviceModel:
                  ref.read(fullDeviceInfoProvider).valueOrNull?.identity.model ?? 'Android Device',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tweaksControllerProvider.notifier).refresh(),
        child: ListView(
          // Build every section up front so the feature tour can find them.
          cacheExtent: 3000,
          padding: EdgeInsets.only(bottom: AppShell.bottomInset(context)),
          children: [
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: AppSpacing.screenPadding,
              child: KeyedSubtree(
                key: TourKeys.tweaksStatus,
                child:
                    _StatusHeader(snapshot: snapshot, loading: async.isLoading && !async.hasValue),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: AppSpacing.screenPadding,
              child: _ModeSwitch(
                rootView: rootView,
                hasRoot: snapshot.capabilities.hasRoot,
                onChanged: (v) => ref.read(rootViewProvider.notifier).state = v,
              ),
            ),
            if (rootView)
              ..._rootSections(context, ref, snapshot)
            else ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: AppSpacing.screenPadding,
                child: KeyedSubtree(key: TourKeys.tweaksAdvice, child: const RecommendationsCard()),
              ),
              const SizedBox(height: AppSpacing.md),
              const ShizukuStatusBanner(),
              _AccessHints(capabilities: snapshot.capabilities),
              const GlassSectionLabel('Presets', icon: Icons.auto_awesome_rounded),
              Padding(
                padding: AppSpacing.screenPadding,
                child: Row(
                  key: TourKeys.tweaksPresets,
                  children: [
                    for (final p in TweakPreset.values) ...[
                      if (p != TweakPreset.values.first) const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: PresetChip(
                          preset: p,
                          selected: preset == p,
                          onTap:
                              snapshot.busy.isNotEmpty ? null : () => _applyPreset(context, ref, p),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (preset != null)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(AppSpacing.md + 4, AppSpacing.xs, AppSpacing.md, 0),
                  child: Text(
                    preset.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              const GlassSectionLabel('Quick actions', icon: Icons.flash_on_rounded),
              Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  key: TourKeys.tweaksActions,
                  children: [
                    for (final row in [TweakCatalog.quickActions, TweakCatalog.artActions]) ...[
                      if (row != TweakCatalog.quickActions) const SizedBox(height: AppSpacing.xs),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final a in row) ...[
                              if (a != row.first) const SizedBox(width: AppSpacing.xs),
                              Expanded(child: TweakActionButton(action: a)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ..._categorySections(TweakCatalog.nonRoot, firstKey: TourKeys.tweaksList),
            ],
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Every tweak writes a documented Android setting and is read back to confirm it '
                'stuck. Originals are saved on the device and restored when you switch a tweak off.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One glass group per category for the given tweaks.
  List<Widget> _categorySections(List<TweakDefinition> tweaks, {GlobalKey? firstKey}) {
    final categories =
        TweakCategory.values.where((c) => tweaks.any((t) => t.category == c)).toList();
    return [
      for (final category in categories) ...[
        GlassSectionLabel(category.label, icon: category.icon),
        Padding(
          padding: AppSpacing.screenPadding,
          child: GlassGroup(
            key: category == categories.first ? firstKey : null,
            margin: EdgeInsets.zero,
            children: [
              for (final t in tweaks.where((t) => t.category == category)) TweakTile(definition: t),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _rootSections(BuildContext context, WidgetRef ref, TweaksSnapshot snapshot) => [
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: AppSpacing.screenPadding,
          child: _RootStatusCard(capabilities: snapshot.capabilities),
        ),
        const GlassSectionLabel('Root actions', icon: Icons.flash_on_rounded),
        Padding(
          padding: AppSpacing.screenPadding,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in TweakCatalog.rootActions) ...[
                  if (a != TweakCatalog.rootActions.first) const SizedBox(width: AppSpacing.xs),
                  Expanded(child: TweakActionButton(action: a)),
                ],
              ],
            ),
          ),
        ),
        ..._categorySections(TweakCatalog.rootOnly),
      ];

  Future<void> _applyPreset(BuildContext context, WidgetRef ref, TweakPreset preset) async {
    HapticFeedback.mediumImpact();
    final (ok, attempted) = await ref.read(tweaksControllerProvider.notifier).applyPreset(preset);
    if (!context.mounted) return;
    final message = attempted == 0
        ? '${preset.label} is already active'
        : '${preset.label}: $ok of $attempted changes applied';
    showTweakResult(context, TweakResult(success: ok == attempted, message: message));
    if (ok > 0) {
      ref.read(adServiceProvider).showInterstitial(
            AdPlacement.postOptimizationInterstitial,
            canShow: canShowAd(ref),
          );
    }
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.snapshot, required this.loading});

  final TweaksSnapshot snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caps = snapshot.capabilities;
    final total = TweakCatalog.all.length;
    final active = snapshot.activeCount;
    final available = TweakCatalog.all.where(snapshot.canRun).length;

    return GlassCard(
      level: AppGlassLevel.level3,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: total == 0 ? 0 : active / total),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: loading ? 0 : v,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Center(
                  child: Text(
                    '$active',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active == 0 ? 'System defaults' : '$active of $total tweaks active',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$available available on this device',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _AccessChip(label: 'Shizuku', on: caps.shizukuReady),
                    _AccessChip(label: 'ADB grant', on: caps.secureSettingsGranted),
                    _AccessChip(label: 'DND access', on: caps.notificationPolicyGranted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = on ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(on ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? Icons.check_rounded : Icons.close_rounded, size: 12, color: c),
          const SizedBox(width: 3),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c, fontWeight: FontWeight.w700, fontSize: 10.5)),
        ],
      ),
    );
  }
}

/// Explains the no-Shizuku alternatives when neither privilege path exists.
class _AccessHints extends ConsumerWidget {
  const _AccessHints({required this.capabilities});

  final TweakCapabilities capabilities;

  static const _grantCommand =
      'adb shell pm grant com.mohalab.optimization android.permission.WRITE_SECURE_SETTINGS';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showAdb = !capabilities.shizukuReady && !capabilities.secureSettingsGranted;
    final showDnd = !capabilities.shizukuReady && !capabilities.notificationPolicyGranted;
    if (!showAdb && !showDnd) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: GlassCard(
        margin: AppSpacing.screenPadding,
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAdb) ...[
              Text('No Shizuku? Grant once over USB',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'This one-time ADB permission unlocks every settings-based tweak without Shizuku.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              Material(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _grantCommand));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Command copied')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_grantCommand,
                              style: AppTypography.monoStyle(
                                  fontSize: 10.5, color: theme.colorScheme.onSurface)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (showAdb && showDnd) const SizedBox(height: AppSpacing.sm),
            if (showDnd)
              OutlinedButton.icon(
                onPressed: () => ref.read(tweakBridgeProvider).openDndSettings(),
                icon: const Icon(Icons.do_not_disturb_on_outlined, size: 18),
                label: const Text('Allow Do Not Disturb access'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Which half of the Tweaks screen is showing; null = follow root status.
final rootViewProvider = StateProvider<bool?>((ref) => null);

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.rootView, required this.hasRoot, required this.onChanged});

  final bool rootView;
  final bool hasRoot;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: [
        const ButtonSegment(
          value: false,
          label: Text('Non-root'),
          icon: Icon(Icons.shield_outlined, size: 18),
        ),
        ButtonSegment(
          value: true,
          label: const Text('Root'),
          icon: Icon(hasRoot ? Icons.admin_panel_settings_rounded : Icons.lock_outline_rounded,
              size: 18),
        ),
      ],
      selected: {rootView},
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
      onSelectionChanged: (s) {
        HapticFeedback.selectionClick();
        onChanged(s.first);
      },
    );
  }
}

/// Root manager detection, grant button and root-mode status.
class _RootStatusCard extends ConsumerStatefulWidget {
  const _RootStatusCard({required this.capabilities});

  final TweakCapabilities capabilities;

  @override
  ConsumerState<_RootStatusCard> createState() => _RootStatusCardState();
}

class _RootStatusCardState extends ConsumerState<_RootStatusCard> {
  bool _requesting = false;

  Future<void> _request() async {
    HapticFeedback.mediumImpact();
    setState(() => _requesting = true);
    final res = await ref.read(tweaksControllerProvider.notifier).requestRoot();
    if (!mounted) return;
    setState(() => _requesting = false);
    showTweakResult(context, res);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final caps = widget.capabilities;
    final manager = caps.rootManager;

    final (IconData icon, Color color, String title, String body) = caps.rootGranted
        ? (
            Icons.verified_user_rounded,
            scheme.tertiary,
            'Root active${manager != null ? ' · $manager' : ''}',
            'Kernel tweaks are unlocked. Commands run in one persistent root shell built only from '
                'the app\'s fixed templates.',
          )
        : caps.shizukuRoot
            ? (
                Icons.verified_user_rounded,
                scheme.tertiary,
                'Root via Shizuku',
                'Shizuku is running as root, so kernel tweaks work through it.',
              )
            : caps.rootAvailable
                ? (
                    Icons.admin_panel_settings_outlined,
                    scheme.primary,
                    '${manager ?? 'Root'} detected',
                    'Tap Grant root — ${manager ?? 'your root manager'} will ask you to allow Moha Lab.',
                  )
                : (
                    Icons.no_encryption_gmailerrorred_rounded,
                    scheme.onSurfaceVariant,
                    'No root detected',
                    'Root tweaks need Magisk, KernelSU or APatch. Everything in Non-root works without it.',
                  );

    return GlassCard(
      level: caps.hasRoot ? AppGlassLevel.level3 : AppGlassLevel.level2,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(0.16),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          if (caps.rootAvailable && !caps.rootGranted && !caps.shizukuRoot) ...[
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
              ),
              child: FilledButton.icon(
                onPressed: _requesting ? null : _request,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                ),
                icon: _requesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.key_rounded),
                label:
                    Text(_requesting ? 'Waiting for ${manager ?? 'root manager'}…' : 'Grant root'),
              ),
            ),
          ],
          if (caps.rootGranted) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final res = await ref.read(tweaksControllerProvider.notifier).disableRoot();
                  if (context.mounted) showTweakResult(context, res);
                },
                icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                label: const Text('Turn off root mode'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
