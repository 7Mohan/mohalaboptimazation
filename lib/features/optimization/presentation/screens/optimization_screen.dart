import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/dialogs/moha_bottom_sheet.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shizuku/presentation/widgets/shizuku_status_banner.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../domain/entities/optimization_profile.dart';
import '../providers/optimization_providers.dart';
import '../widgets/optimization_card.dart';
import '../widgets/schedule_optimizer_tile.dart';
import '../widgets/share_results_card.dart';

class OptimizationScreen extends ConsumerWidget {
  const OptimizationScreen({super.key});

  static const _categories = [
    _OptimizationCategory(
      icon: Icons.speed_rounded,
      title: 'Performance Engine',
      description: 'CPU/GPU clock governor lock, 144Hz pipeline bypass & hardware controls.',
      tier: MohaStatusType.safe,
      tierLabel: 'Governor',
      apiDetails: 'Calls Android Power HAL cmd power set-fixed-performance-mode.',
      route: RouteNames.performance,
    ),
    _OptimizationCategory(
      icon: Icons.memory_outlined,
      title: 'Memory Management',
      description: 'System RAM cache sweep to maximize game memory headroom.',
      tier: MohaStatusType.safe,
      tierLabel: 'RAM Purge',
      apiDetails: 'Runs pm trim-caches 999G and reclaims inactive memory pages.',
      targetToolId: 'deep_ram_clean',
    ),
    _OptimizationCategory(
      icon: Icons.touch_app_outlined,
      title: 'Touch & Input Response',
      description: 'Zero touch latency response for competitive shooting and rhythm games.',
      tier: MohaStatusType.safe,
      tierLabel: 'Zero Latency',
      apiDetails: 'Sets tap duration threshold and touch blocking period to 0.0.',
      targetToolId: 'ultra_touch_latency',
    ),
    _OptimizationCategory(
      icon: Icons.blur_off_rounded,
      title: 'Surface Blurs Disabler',
      description: 'Reclaim GPU fillrate by disabling Gaussian background blurs.',
      tier: MohaStatusType.safe,
      tierLabel: 'GPU Fillrate',
      apiDetails: 'Toggles global disable_window_blurs system setting.',
      targetToolId: 'disable_window_blurs',
    ),
    _OptimizationCategory(
      icon: Icons.tv_rounded,
      title: 'Display Refresh Rate',
      description: 'Locks refresh rate to 120Hz/144Hz to eliminate dynamic downclocking.',
      tier: MohaStatusType.safe,
      tierLabel: 'Refresh Rate',
      apiDetails: 'Locks min_refresh_rate equal to peak_refresh_rate.',
      targetToolId: 'peak_refresh_rate',
    ),
    _OptimizationCategory(
      icon: Icons.wifi_tethering_rounded,
      title: 'Gaming TCP Tuning',
      description: 'Optimizes network socket buffers for lowest latency & jitter.',
      tier: MohaStatusType.safe,
      tierLabel: 'Low Jitter',
      apiDetails: 'Tunes net.tcp.buffersize for Wi-Fi and high-speed mobile data.',
      targetToolId: 'tcp_network_buffer',
    ),
    _OptimizationCategory(
      icon: Icons.notifications_off_outlined,
      title: 'Disturbance Blocker',
      description: 'Suppress notifications and banners during gaming sessions.',
      tier: MohaStatusType.safe,
      tierLabel: 'Gaming DND',
      apiDetails: 'Utilizes Android NotificationManager Zen Mode interruption filter.',
      targetToolId: 'gaming_dnd_zen',
    ),
    _OptimizationCategory(
      icon: Icons.thermostat_outlined,
      title: 'Thermal & Battery Telemetry',
      description: 'Monitor device temperature zones and battery health in real-time.',
      tier: MohaStatusType.safe,
      tierLabel: 'Telemetry',
      apiDetails: 'Reads hardware thermal sensors and battery discharge telemetry.',
      route: RouteNames.diagnostics,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optimizations = ref.watch(optimizationRegistryProvider).getAll();
    final optState = ref.watch(optimizationControllerProvider);
    final selectedProfile = ref.watch(selectedProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'Optimization',
        subtitle: 'System & per-game performance controls',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // ── Profile Selector ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: _ProfileSelectorRow(
              selected: selectedProfile,
              onSelect: (p) =>
                  ref.read(selectedProfileProvider.notifier).state = p,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Live Applied Status & One-Tap Batch Optimizer
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              0,
            ),
            child: _OptimizationSummaryBanner(
              appliedCount: optState.appliedOptimizationIds.length,
              totalCount: optimizations.length,
              isBusy: optState.isBusy,
              selectedProfile: selectedProfile,
              onApplyProfile: () async {
                final results = await ref
                    .read(optimizationControllerProvider.notifier)
                    .applyProfile(profile: selectedProfile);
                if (context.mounted) {
                  final successCount = results.where((r) => r.success).length;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${selectedProfile.label} profile: $successCount of ${results.length} tools applied.',
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                }
              },
              onShare: () {
                final deviceModel = ref
                        .read(fullDeviceInfoProvider)
                        .valueOrNull
                        ?.identity
                        .model ??
                    'Android Device';
                ShareResultsHelper.captureAndShare(
                  context: context,
                  profileName: selectedProfile.label,
                  toolsCount: optState.appliedOptimizationIds.isNotEmpty
                      ? optState.appliedOptimizationIds.length
                      : 6,
                  deviceModel: deviceModel,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Shizuku status banner — hidden when service is ready
          const ShizukuStatusBanner(),
          const SizedBox(height: AppSpacing.sm),

          // Scheduled Auto-Optimization Section
          const Padding(
            padding: AppSpacing.screenPadding,
            child: ScheduleOptimizerTile(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Safe Optimization Tools Section
          const SectionHeader(
            title: 'Safe Optimization Tools',
            subtitle: 'Legitimate Android APIs with full reversibility & safety checks.',
            icon: Icons.shield_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: optimizations
                  .map((def) => OptimizationCard(definition: def))
                  .toList(),
            ),
          ),

          // Categories Reference Section
          const SectionHeader(
            title: 'Optimization Categories',
            subtitle: 'Safe, targeted tools for gaming performance.',
            icon: Icons.check_circle_outline,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Card(
              child: Column(
                children: _categories
                    .asMap()
                    .entries
                    .map(
                      (entry) => Column(
                        children: [
                          _CategoryTile(category: entry.value),
                          if (entry.key < _categories.length - 1)
                            Divider(
                              height: 1,
                              indent: 64,
                              endIndent: AppSpacing.md,
                              color: theme.colorScheme.outlineVariant,
                            ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizationSummaryBanner extends StatelessWidget {
  const _OptimizationSummaryBanner({
    required this.appliedCount,
    required this.totalCount,
    required this.isBusy,
    required this.selectedProfile,
    required this.onApplyProfile,
    this.onShare,
  });

  final int appliedCount;
  final int totalCount;
  final bool isBusy;
  final OptimizationProfile selectedProfile;
  final VoidCallback onApplyProfile;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      level: AppGlassLevel.level3,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: theme.colorScheme.primary,
                  size: AppSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appliedCount > 0
                          ? '$appliedCount of $totalCount Optimizations Active'
                          : 'Hardware Safety Active',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedProfile.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onApplyProfile,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    isBusy
                        ? 'Applying ${selectedProfile.label}...'
                        : 'Apply ${selectedProfile.label} Profile',
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              if (onShare != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Share Optimization Card',
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Three segmented chips for profile selection.
class _ProfileSelectorRow extends StatelessWidget {
  const _ProfileSelectorRow({
    required this.selected,
    required this.onSelect,
  });

  final OptimizationProfile selected;
  final ValueChanged<OptimizationProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPTIMIZATION PROFILE',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: OptimizationProfile.values.map((profile) {
            final isSelected = profile == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(profile),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


class _OptimizationCategory {
  const _OptimizationCategory({
    required this.icon,
    required this.title,
    required this.description,
    required this.tier,
    required this.tierLabel,
    required this.apiDetails,
    this.targetToolId,
    this.route,
  });

  final IconData icon;
  final String title;
  final String description;
  final MohaStatusType tier;
  final String tierLabel;
  final String apiDetails;
  final String? targetToolId;
  final String? route;
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final _OptimizationCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final optState = ref.watch(optimizationControllerProvider);
    final isApplied = category.targetToolId != null &&
        optState.appliedOptimizationIds.contains(category.targetToolId);

    return InkWell(
      onTap: () => _handleTap(context, ref),
      borderRadius: AppRadius.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
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
                isApplied ? Icons.check_circle_rounded : category.icon,
                size: AppSizes.iconSm,
                color: isApplied ? const Color(0xFF10B981) : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                          ] else ...[
                            MohaStatusBadge(
                              type: category.tier,
                              customLabel: category.tierLabel,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    category.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (category.route != null) {
      context.go(category.route!);
      return;
    }
    _showCategoryDetails(context, ref);
  }

  void _showCategoryDetails(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    MohaBottomSheet.show(
      context: context,
      title: category.title,
      subtitle: category.tierLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How This Optimization Works',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Underlying Android API',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: AppSpacing.cardPaddingCompact,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.radiusSm,
            ),
            child: Text(
              category.apiDetails,
              style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (category.targetToolId != null) ...[
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await ref
                    .read(optimizationControllerProvider.notifier)
                    .executeOptimization(id: category.targetToolId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            result.success
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.success
                                  ? '${category.title} executed successfully!'
                                  : result.message,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: result.success
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bolt_rounded),
              label: Text('Execute ${category.title} Now'),
            ),
          ] else if (category.route != null) ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(category.route!);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text('Open ${category.title}'),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(optimizationBridgeProvider).cleanSystemCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Battery & process hints optimized!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Apply Battery Profile Hints'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
