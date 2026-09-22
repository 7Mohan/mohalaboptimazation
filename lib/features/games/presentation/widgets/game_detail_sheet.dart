import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/buttons/moha_action_button.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../data/services/game_stats_service.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/game_profile_entity.dart';
import '../providers/game_profile_provider.dart';
import '../../../optimization/presentation/providers/optimization_providers.dart';

/// Modal sheet displaying game information and local tuning profile configuration.
///
/// Hierarchy strictly follows:
/// 1. Game information
/// 2. Profile status
/// 3. Available categories
/// 4. Current configuration
/// 5. Save / Reset
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

  void _initProfile(GameProfile profile) {
    if (!_isInitialized) {
      _localProfile = profile;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arg = GameProfileArg(
      packageName: widget.game.packageName,
      gameName: widget.game.appName,
    );
    final profileAsync = ref.watch(gameProfileFamily(arg));

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
              // =============================================================
              // 1. GAME INFORMATION
              // =============================================================
              _buildGameInformation(theme),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // =============================================================
              // 2. PROFILE STATUS
              // =============================================================
              _buildProfileStatus(theme, profile),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // =============================================================
              // 3. AVAILABLE CATEGORIES
              // =============================================================
              _buildAvailableCategories(theme, profile),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // =============================================================
              // 4. CURRENT CONFIGURATION
              // =============================================================
              _buildCurrentConfiguration(theme, profile),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // =============================================================
              // 5. SAVE / RESET / ACTIONS
              // =============================================================
              _buildActionRow(theme, profile),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Game Information
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGameInformation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: widget.game.iconBytes != null
                  ? Image.memory(
                      widget.game.iconBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.sports_esports,
                        color: theme.colorScheme.primary,
                        size: AppSizes.iconLg,
                      ),
                    )
                  : Icon(
                      Icons.sports_esports,
                      color: theme.colorScheme.primary,
                      size: AppSizes.iconLg,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.game.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    widget.game.packageName,
                    style: AppTypography.monoStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        widget.game.versionDisplay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      MohaStatusBadge(
                        type: widget.game.confidence == GameConfidence.high
                            ? MohaStatusType.safe
                            : MohaStatusType.optimal,
                        customLabel: widget.game.confidence.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Per-Game Performance Stats & Quick Presets
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'PERFORMANCE & STATS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${ref.watch(gameStatsServiceProvider).getStats(widget.game.packageName).launchCount} Launches',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Quick Tuning Presets:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _localProfile = (_localProfile ??
                                  GameProfile.defaultForGame(
                                    widget.game.packageName,
                                    widget.game.appName,
                                  ))
                              .copyWith(
                            performance: PerformancePreference.highPerformance,
                            display: DisplayPreference.fps120,
                            touch: TouchPreference.ultraResponsive,
                            network: NetworkPreference.lowLatency,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Applied Extreme Gaming preset! Tap Save.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Extreme FPS', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _localProfile = (_localProfile ??
                                  GameProfile.defaultForGame(
                                    widget.game.packageName,
                                    widget.game.appName,
                                  ))
                              .copyWith(
                            performance: PerformancePreference.balanced,
                            display: DisplayPreference.auto,
                            touch: TouchPreference.standard,
                            network: NetworkPreference.normal,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Applied Balanced preset! Tap Save.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Balanced', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          _localProfile = (_localProfile ??
                                  GameProfile.defaultForGame(
                                    widget.game.packageName,
                                    widget.game.appName,
                                  ))
                              .copyWith(
                            performance: PerformancePreference.powerSaving,
                            display: DisplayPreference.fps60,
                            battery: BatteryPreference.batterySaver,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Applied Battery Saver preset! Tap Save.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Battery Saver', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Profile Status
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileStatus(ThemeData theme, GameProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROFILE STATUS',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'Profile Options',
              onSelected: (val) => _handleMenuAction(val, profile),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Export JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Import JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Duplicate Profile'),
                    ],
                  ),
                ),
                if (profile.isCustomized)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Profile', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: AppSpacing.paddingSm,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                profile.isCustomized
                    ? Icons.check_circle_rounded
                    : Icons.tune_rounded,
                color: profile.isCustomized
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.isCustomized
                          ? 'Active Custom Profile (Saved)'
                          : 'Factory Default Profile (Unconfigured)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.lastUsed != null
                          ? 'Last configured: ${profile.lastUsed!.year}-${profile.lastUsed!.month.toString().padLeft(2, '0')}-${profile.lastUsed!.day.toString().padLeft(2, '0')}'
                          : 'Standard system baseline values active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              MohaStatusBadge(
                type: profile.isCustomized ? MohaStatusType.active : MohaStatusType.safe,
                customLabel: profile.isCustomized ? 'Configured' : 'Default',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Available Categories
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAvailableCategories(ThemeData theme, GameProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE CATEGORIES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Toggle which optimization domains are managed for this title:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: OptimizationCategory.values.map((cat) {
            final isEnabled = profile.enabledCategories.contains(cat);
            return FilterChip(
              avatar: Icon(
                cat.icon,
                size: 16,
                color: isEnabled
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(cat.label),
              selected: isEnabled,
              onSelected: (selected) {
                setState(() {
                  final newCategories = Set<OptimizationCategory>.from(
                    profile.enabledCategories,
                  );
                  if (selected) {
                    newCategories.add(cat);
                  } else {
                    if (newCategories.length > 1) {
                      newCategories.remove(cat);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('At least one optimization category must remain active.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                  _localProfile = profile.copyWith(enabledCategories: newCategories);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Current Configuration
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentConfiguration(ThemeData theme, GameProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT CONFIGURATION',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Performance
        if (profile.enabledCategories.contains(OptimizationCategory.performance))
          _buildDropdownTile<PerformancePreference>(
            theme: theme,
            title: 'Performance Target',
            icon: Icons.speed_rounded,
            value: profile.performance,
            items: PerformancePreference.values,
            itemLabel: (e) => '${e.label} — ${e.description}',
            onChanged: (val) {
              if (val != null) {
                setState(() => _localProfile = profile.copyWith(performance: val));
              }
            },
          ),

        // Battery & Thermals
        if (profile.enabledCategories.contains(OptimizationCategory.battery))
          _buildDropdownTile<BatteryPreference>(
            theme: theme,
            title: 'Thermal & Battery Target',
            icon: Icons.battery_charging_full_rounded,
            value: profile.battery,
            items: BatteryPreference.values,
            itemLabel: (e) => '${e.label} — ${e.description}',
            onChanged: (val) {
              if (val != null) {
                setState(() => _localProfile = profile.copyWith(battery: val));
              }
            },
          ),

        // Network
        if (profile.enabledCategories.contains(OptimizationCategory.network))
          _buildDropdownTile<NetworkPreference>(
            theme: theme,
            title: 'Network Optimization',
            icon: Icons.wifi_tethering_rounded,
            value: profile.network,
            items: NetworkPreference.values,
            itemLabel: (e) => '${e.label} — ${e.description}',
            onChanged: (val) {
              if (val != null) {
                setState(() => _localProfile = profile.copyWith(network: val));
              }
            },
          ),

        // Touch
        if (profile.enabledCategories.contains(OptimizationCategory.touch))
          _buildDropdownTile<TouchPreference>(
            theme: theme,
            title: 'Touch Response & Polling',
            icon: Icons.touch_app_rounded,
            value: profile.touch,
            items: TouchPreference.values,
            itemLabel: (e) => '${e.label} — ${e.description}',
            onChanged: (val) {
              if (val != null) {
                setState(() => _localProfile = profile.copyWith(touch: val));
              }
            },
          ),

        // Display
        if (profile.enabledCategories.contains(OptimizationCategory.display))
          _buildDropdownTile<DisplayPreference>(
            theme: theme,
            title: 'Display & Refresh Rate',
            icon: Icons.tv_rounded,
            value: profile.display,
            items: DisplayPreference.values,
            itemLabel: (e) => '${e.label} — ${e.description}',
            onChanged: (val) {
              if (val != null) {
                setState(() => _localProfile = profile.copyWith(display: val));
              }
            },
          ),

        const SizedBox(height: AppSpacing.sm),

        // Safe User Settings Toggles
        Text(
          'GAMING ENVIRONMENT TOGGLES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildSettingSwitch(
          theme: theme,
          title: 'Prevent Notification Popups',
          subtitle: 'Suppress heads-up banners during active gaming sessions',
          keyName: SafeUserSettingsKeys.preventNotificationPopups,
          profile: profile,
        ),
        _buildSettingSwitch(
          theme: theme,
          title: 'Lock Screen Brightness',
          subtitle: 'Prevent ambient sensor shifts from dimming display',
          keyName: SafeUserSettingsKeys.lockBrightness,
          profile: profile,
        ),
        _buildSettingSwitch(
          theme: theme,
          title: 'Keep Screen Awake',
          subtitle: 'Prevents display sleep during cutscenes or idle gameplay',
          keyName: SafeUserSettingsKeys.keepScreenAwake,
          profile: profile,
        ),
        _buildSettingSwitch(
          theme: theme,
          title: 'Disable Background Cloud Sync',
          subtitle: 'Reduces CPU contention and background network jitter',
          keyName: SafeUserSettingsKeys.disableAutoSync,
          profile: profile,
        ),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String keyName,
    required GameProfile profile,
  }) {
    final isChecked = profile.userSettings[keyName] == true;

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: isChecked,
      onChanged: (val) {
        final newSettings = Map<String, dynamic>.from(profile.userSettings);
        newSettings[keyName] = val;
        setState(() {
          _localProfile = profile.copyWith(userSettings: newSettings);
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Save / Reset Actions
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionRow(ThemeData theme, GameProfile profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Reset to Default'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
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
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              minimumSize: const Size(0, 50),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
            icon: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
            label: const Text(
              'Turbo Launch (Beast Mode)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              final bridge = ref.read(optimizationBridgeProvider);
              await bridge.setAppGameMode(widget.game.packageName, 'performance');
              await bridge.setFixedPerformanceMode(true);
              await bridge.setTouchLatency(true);
              await bridge.setMinRefreshRate(120.0);
              widget.onLaunch();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Standard Launch ${widget.game.appName}'),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLaunch();
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile Controller Operations
  // ─────────────────────────────────────────────────────────────────────────
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
