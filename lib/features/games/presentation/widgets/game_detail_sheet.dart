import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/buttons/moha_action_button.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../optimization/domain/tweak.dart';
import '../../../optimization/presentation/providers/tweak_providers.dart';
import '../../../optimization/presentation/widgets/tweak_widgets.dart';
import '../../data/services/game_stats_service.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/game_profile_entity.dart';
import '../providers/game_profile_provider.dart';

/// Per-game tuning sheet.
///
/// Every control maps to a real Android mechanism:
/// - Game Mode, resolution downscale and FPS override → GameManager
///   (`cmd game`, Android 13/14+). These are per-app and only active while
///   the game runs, so nothing lingers after you stop playing.
/// - "Block interruptions" → the global Gaming DND / pop-up tweaks.
/// - "Compile" → ART `speed` compilation of the game's code.
class GameDetailSheet extends ConsumerStatefulWidget {
  const GameDetailSheet({
    super.key,
    required this.game,
    required this.onLaunch,
  });

  final GameEntity game;
  final VoidCallback onLaunch;

  static void show({
    required BuildContext context,
    required GameEntity game,
    required VoidCallback onLaunch,
  }) {
    MohaBottomSheet.show(
      context: context,
      title: game.appName,
      subtitle: game.packageName,
      child: GameDetailSheet(game: game, onLaunch: onLaunch),
    );
  }

  @override
  ConsumerState<GameDetailSheet> createState() => _GameDetailSheetState();
}

class _GameDetailSheetState extends ConsumerState<GameDetailSheet> {
  GameProfile? _localProfile;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isLaunching = false;

  static const _renderScales = [1.0, 0.85, 0.7, 0.5];

  void _initProfile(GameProfile profile) {
    if (!_isInitialized) {
      _localProfile = profile;
      _isInitialized = true;
    }
  }

  void _update(GameProfile Function(GameProfile p) change) {
    final base =
        _localProfile ?? GameProfile.defaultForGame(widget.game.packageName, widget.game.appName);
    setState(() => _localProfile = change(base).copyWith(isCustomized: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arg = GameProfileArg(
      packageName: widget.game.packageName,
      gameName: widget.game.appName,
    );
    final profileAsync = ref.watch(gameProfileFamily(arg));
    final caps =
        ref.watch(tweaksControllerProvider).valueOrNull?.capabilities ?? const TweakCapabilities();

    return profileAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('Failed to load profile: $err'),
      ),
      data: (savedProfile) {
        _initProfile(savedProfile);
        final profile = _localProfile ?? savedProfile;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGameInformation(theme),
              const SizedBox(height: AppSpacing.md),
              _buildProfileStatus(theme, profile),
              const SizedBox(height: AppSpacing.md),
              _buildCurrentConfiguration(theme, profile, caps),
              const SizedBox(height: AppSpacing.lg),
              _buildActionRow(theme, profile, caps),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  // Game information
  Widget _buildGameInformation(ThemeData theme) {
    final launches =
        ref.watch(gameStatsServiceProvider).getStats(widget.game.packageName).launchCount;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppGlass.hairline(context)),
          ),
          child: widget.game.iconBytes != null
              ? Image.memory(
                  widget.game.iconBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.sports_esports,
                    color: theme.colorScheme.primary,
                    size: AppSizes.iconLg,
                  ),
                )
              : Icon(Icons.sports_esports, color: theme.colorScheme.primary, size: AppSizes.iconLg),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.appName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.game.packageName,
                style: AppTypography.monoStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    widget.game.versionDisplay,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  MohaStatusBadge(
                    type: widget.game.confidence == GameConfidence.high
                        ? MohaStatusType.safe
                        : MohaStatusType.optimal,
                    customLabel: widget.game.confidence.label,
                  ),
                  Text(
                    '$launches launches',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Profile status
  Widget _buildProfileStatus(ThemeData theme, GameProfile profile) {
    return GlassCard(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      shadows: const [],
      child: Row(
        children: [
          Icon(
            profile.isCustomized ? Icons.tune_rounded : Icons.settings_backup_restore_rounded,
            color: profile.isCustomized
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROFILE STATUS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.isCustomized ? 'Custom tuning saved' : 'Factory Default Profile',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile Options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) => _handleMenuAction(v, profile),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('Export JSON')),
              PopupMenuItem(value: 'import', child: Text('Import JSON')),
              PopupMenuItem(value: 'duplicate', child: Text('Duplicate Profile')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Profile', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tuning controls
  Widget _buildCurrentConfiguration(ThemeData theme, GameProfile profile, TweakCapabilities caps) {
    final sdk = caps.sdkInt;
    final gameModeOk = sdk == 0 || sdk >= 33;
    final fpsOk = sdk == 0 || sdk >= 34;
    final overridesEnabled = profile.performance != PerformancePreference.balanced;

    String? gate;
    if (!gameModeOk) {
      gate = 'Game Mode needs Android 13 or newer — this device is on API $sdk.';
    } else if (!caps.shizukuReady && sdk != 0) {
      gate = 'Connect Shizuku to apply Game Mode settings.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT CONFIGURATION',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (gate != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(gate, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: AppSpacing.sm),
        _OptionGroup<PerformancePreference>(
          title: 'Game Mode',
          icon: Icons.speed_rounded,
          values: PerformancePreference.values,
          selected: profile.performance,
          labelOf: (v) => v.label,
          description: profile.performance.description,
          onSelected: (v) => _update((p) => p.copyWith(performance: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionGroup<double>(
          title: 'Render Resolution',
          icon: Icons.photo_size_select_large_rounded,
          values: _renderScales,
          selected: _renderScales.contains(profile.renderScale) ? profile.renderScale : 1.0,
          labelOf: (v) => v == 1.0 ? 'Native' : '${(v * 100).round()}%',
          enabled: overridesEnabled,
          description: overridesEnabled
              ? (profile.renderScale >= 1.0
                  ? 'Full native resolution.'
                  : 'Renders at ${(profile.renderScale * 100).round()}% and upscales — less GPU load, less heat.')
              : 'Choose Performance or Battery mode to enable.',
          onSelected: (v) => _update((p) => p.copyWith(renderScale: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionGroup<DisplayPreference>(
          title: 'Frame Rate',
          icon: Icons.slow_motion_video_rounded,
          values: DisplayPreference.values,
          selected: profile.display,
          labelOf: (v) => v == DisplayPreference.auto ? 'Auto' : '${v.fps}',
          enabled: overridesEnabled && fpsOk,
          description: !fpsOk
              ? 'FPS override needs Android 14+.'
              : overridesEnabled
                  ? profile.display.description
                  : 'Choose Performance or Battery mode to enable.',
          onSelected: (v) => _update((p) => p.copyWith(display: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'GAMING ENVIRONMENT TOGGLES',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GlassCard(
          padding: EdgeInsets.zero,
          shadows: const [],
          child: SwitchListTile(
            value: profile.userSettings[SafeUserSettingsKeys.preventNotificationPopups] == true,
            onChanged: (val) => _update((p) => p.copyWith(
                  userSettings: {
                    ...p.userSettings,
                    SafeUserSettingsKeys.preventNotificationPopups: val,
                  },
                )),
            title: Text(
              'Prevent Notification Popups',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Turns on Gaming DND and blocks banners at Turbo Launch. Switch them off in Tweaks.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  // Save / reset / launch
  Widget _buildActionRow(ThemeData theme, GameProfile profile, TweakCapabilities caps) {
    final compileBusy =
        ref.watch(tweaksControllerProvider).valueOrNull?.isBusy('compile_game') ?? false;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Reset to Default'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: _isSaving ? null : () => _resetToDefaults(profile),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MohaActionButton(
                label: _isSaving ? 'Saving...' : 'Save Profile',
                icon: Icons.check_circle_outline,
                onPressed: _isSaving ? null : () => _saveProfile(profile),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusFull,
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
              ),
              icon: _isLaunching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: const Text('Turbo Launch', style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: _isLaunching ? null : () => _turboLaunch(profile, caps),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Standard Launch'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLaunch();
                },
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: compileBusy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt_rounded),
                label: const Text('Compile for gaming'),
                onPressed: compileBusy || !caps.shizukuReady ? null : _compileGame,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Applies the saved Game Mode tuning (and optional interruption blocking),
  /// reports what Android accepted, then launches the game.
  Future<void> _turboLaunch(GameProfile profile, TweakCapabilities caps) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLaunching = true);
    final bridge = ref.read(tweakBridgeProvider);
    final tweaks = ref.read(tweaksControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final notes = <String>[];

    if (caps.shizukuReady && (caps.sdkInt == 0 || caps.sdkInt >= 33)) {
      final res = await bridge.applyGameTuning(
        packageName: widget.game.packageName,
        mode: switch (profile.performance) {
          PerformancePreference.balanced => 'standard',
          PerformancePreference.highPerformance => 'performance',
          PerformancePreference.powerSaving => 'battery',
        },
        downscale: profile.renderScale,
        fps: profile.display.fps,
      );
      notes.add(res.message);
    }

    if (profile.userSettings[SafeUserSettingsKeys.preventNotificationPopups] == true) {
      final dnd = await tweaks.setEnabled('gaming_dnd', true);
      final banners = await tweaks.setEnabled('heads_up_off', true);
      if (!dnd.success || !banners.success) notes.add('Interruptions partly blocked');
    }

    if (!mounted) return;
    setState(() => _isLaunching = false);
    Navigator.of(context).pop();
    widget.onLaunch();
    if (notes.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(notes.join(' · '))));
    }
  }

  /// Games get full `speed` compilation (no JIT warm-up stutter) unless
  /// storage is nearly full, where profile-guided `speed-profile` is kinder.
  String get _gamingCompileFilter {
    final used = ref.read(fullDeviceInfoProvider).valueOrNull?.storage.internalUsedPercent;
    return used != null && used > 90 ? 'speed-profile' : 'speed';
  }

  Future<void> _compileGame() async {
    final res = await ref.read(tweaksControllerProvider.notifier).runAction(
          'compile_game',
          packageName: widget.game.packageName,
          mode: _gamingCompileFilter,
        );
    if (mounted) showTweakResult(context, res);
  }

  Future<void> _saveProfile(GameProfile profile) async {
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(gameProfileControllerProvider);
      await controller.saveProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved optimization profile for ${widget.game.appName}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefaults(GameProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Profile?'),
        content: Text(
          'Revert "${widget.game.appName}" to factory default tuning parameters?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(gameProfileControllerProvider);
      final reset = await controller.resetProfile(
        widget.game.packageName,
        widget.game.appName,
      );
      setState(() => _localProfile = reset);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset ${widget.game.appName} profile to factory defaults.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleMenuAction(String action, GameProfile profile) async {
    final controller = ref.read(gameProfileControllerProvider);

    switch (action) {
      case 'export':
        final json = controller.exportProfile(profile);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Export Profile JSON'),
            content: SelectableText(
              json,
              style: AppTypography.monoStyle(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;

      case 'import':
        final textController = TextEditingController();
        final importedJson = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Profile JSON'),
            content: TextField(
              controller: textController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste valid profile JSON here...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(textController.text),
                child: const Text('Validate & Import'),
              ),
            ],
          ),
        );

        if (importedJson != null && importedJson.trim().isNotEmpty && mounted) {
          try {
            final imported = await controller.importProfile(importedJson.trim());
            setState(() => _localProfile = imported);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile imported and validated successfully.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import rejected: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;

      case 'duplicate':
        final targetPkgController = TextEditingController();
        final targetNameController = TextEditingController();
        final duplicateData = await showDialog<Map<String, String>>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Duplicate Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: targetNameController,
                  decoration: const InputDecoration(
                    labelText: 'Target Game Name',
                    hintText: 'e.g. Action Game Mod',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: targetPkgController,
                  decoration: const InputDecoration(
                    labelText: 'Target Package Name',
                    hintText: 'e.g. com.example.targetgame',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop({
                  'name': targetNameController.text,
                  'pkg': targetPkgController.text,
                }),
                child: const Text('Duplicate'),
              ),
            ],
          ),
        );

        if (duplicateData != null && mounted) {
          try {
            await controller.duplicateProfile(
              sourcePackage: profile.gamePackage,
              targetPackage: duplicateData['pkg']!.trim(),
              targetGameName: duplicateData['name']!.trim(),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Duplicated profile to ${duplicateData['name']}.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Duplication failed: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Profile?'),
            content: Text(
              'Remove saved tuning parameters for "${widget.game.appName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await controller.deleteProfile(
            widget.game.packageName,
            widget.game.appName,
          );
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted profile for ${widget.game.appName}.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
    }
  }
}

/// A labelled row of glass pills for picking one value.
class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.title,
    required this.icon,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.description,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final String? description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GlassCard(
      padding: AppSpacing.cardPaddingCompact,
      shadows: const [],
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(title,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final v in values) ...[
                  if (v != values.first) const SizedBox(width: 6),
                  Expanded(
                    child: _Pill(
                      label: labelOf(v),
                      selected: v == selected,
                      onTap: enabled ? () => onSelected(v) : null,
                    ),
                  ),
                ],
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusFull,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.withOpacity(0.22) : theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.radiusFull,
            border: Border.all(color: selected ? c.withOpacity(0.7) : AppGlass.hairline(context)),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? c : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
