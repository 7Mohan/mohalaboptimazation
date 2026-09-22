import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ads/ad_placement.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/tailwind_tokens.dart';
import '../../../../shared/widgets/tailwind/tailwind_badge.dart';
import '../../../../shared/widgets/tailwind/tailwind_card.dart';
import '../../../../shared/widgets/ads/moha_banner_ad_widget.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/glass/animated_entry.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/indicators/moha_status_badge.dart';
import '../../../../shared/widgets/live_system_snapshot.dart';
import '../../../../shared/widgets/moha_gradient_hero.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../community/presentation/widgets/startup_community_dialog.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../onboarding/presentation/widgets/how_to_use_dialog.dart';
import '../widgets/cpu_usage_chart.dart';
import '../widgets/storage_cleaner_widget.dart';
import '../widgets/temperature_monitor_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupCommunityDialog.showIfFirstLaunch(context, ref);
    });
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceInfoAsync = ref.watch(fullDeviceInfoProvider);

    final deviceModel = deviceInfoAsync.asData?.value.identity.model;
    final deviceManufacturer = deviceInfoAsync.asData?.value.identity.manufacturer;
    final androidVersion = deviceInfoAsync.asData?.value.identity.androidVersion;

    final String heroTitle = (deviceManufacturer != null &&
            deviceModel != null &&
            deviceManufacturer != 'Unavailable')
        ? '$deviceManufacturer $deviceModel'
        : 'Android Gaming Engine';

    final String heroSubtitle = (androidVersion != null && androidVersion != 'Unavailable')
        ? 'Android $androidVersion • Non-Root Precision Tuning'
        : 'Hardware-grounded optimization & diagnostics';

    return Scaffold(
      appBar: MohaAppBar(
        title: 'Optimization',
        showBrand: true,
        subtitle: 'Precision Android Gaming & Diagnostics',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'How to use Moha Lab',
            onPressed: () => HowToUseDialog.showExplicit(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Dynamic Greeting Header
          AnimatedEntry.staggered(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    _getTimeGreeting(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  const TailwindBadge(
                    label: 'SYSTEM OPTIMIZED',
                    variant: TailwindBadgeVariant.success,
                    showDot: true,
                  ),
                ],
              ),
            ),
          ),

          // Modern Gradient Hero Header
          AnimatedEntry.staggered(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: MohaGradientHero(
                title: heroTitle,
                subtitle: heroSubtitle,
                statusChip: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    borderRadius: AppRadius.radiusFull,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Safe Mode Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                badge: const MohaStatusBadge(
                  type: MohaStatusType.safe,
                  customLabel: 'Zero Risk',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Live System Telemetry Snapshot
          AnimatedEntry.staggered(
            index: 2,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: LiveSystemSnapshot(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Real-time Hardware Telemetry (CPU, Thermal & Storage Cleaner)
          AnimatedEntry.staggered(
            index: 3,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  CpuUsageChart(),
                  SizedBox(height: AppSpacing.sm),
                  TemperatureMonitorWidget(),
                  SizedBox(height: AppSpacing.sm),
                  StorageCleanerWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Performance Engine Card (Tailwind / Bootstrap Style)
          AnimatedEntry.staggered(
            index: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TailwindCard(
                onTap: () => context.push(RouteNames.performance),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TailwindColors.blue950.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: TailwindColors.blue500.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: TailwindColors.blue400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'HARDWARE PERFORMANCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: TailwindColors.blue400,
                                ),
                              ),
                              Spacer(),
                              TailwindBadge(
                                label: '144Hz & KERNEL',
                                variant: TailwindBadgeVariant.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Performance Engine Controls',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: TailwindColors.zinc100,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sustain peak clocks, bypass display frame limits & zero touch lag.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: TailwindColors.zinc400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: TailwindColors.zinc500,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Actions Grid
          AnimatedEntry.staggered(
            index: 5,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Direct shortcuts to system utilities and diagnostics.',
                  icon: Icons.bolt,
                ),
                _QuickActionsGrid(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Safety & Architecture Overview
          AnimatedEntry.staggered(
            index: 6,
            child: const Padding(
              padding: AppSpacing.screenPadding,
              child: _SafetyOverviewCard(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Social Links — TikTok & Telegram
          AnimatedEntry.staggered(
            index: 7,
            child: const Padding(
              padding: AppSpacing.screenPadding,
              child: _SocialLinksCard(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Banner ad — below all content, never covering controls.
          const MohaBannerAdWidget(placement: AdPlacement.homeBanner),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Grid
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickAction(
        icon: Icons.flash_on_rounded,
        label: 'Engine',
        subtitle: 'Beast Mode & Governor',
        route: RouteNames.performance,
        accentColor: Color(0xFFEF4444),
      ),
      _QuickAction(
        icon: Icons.sports_esports_outlined,
        label: 'Games',
        subtitle: 'Game catalog & specs',
        route: RouteNames.games,
        accentColor: Color(0xFF3B82F6),
      ),
      _QuickAction(
        icon: Icons.tune_outlined,
        label: 'Optimize',
        subtitle: 'Performance tools',
        route: RouteNames.optimization,
        accentColor: Color(0xFF10B981),
      ),
      _QuickAction(
        icon: Icons.monitor_heart_outlined,
        label: 'Diagnostics',
        subtitle: 'Hardware telemetry',
        route: RouteNames.diagnostics,
        accentColor: Color(0xFF8B5CF6),
      ),
      _QuickAction(
        icon: Icons.network_check_rounded,
        label: 'Network',
        subtitle: 'Gaming ping & jitter',
        route: RouteNames.network,
        accentColor: Color(0xFF06B6D4),
      ),
      _QuickAction(
        icon: Icons.info_outline_rounded,
        label: 'About',
        subtitle: 'App details & specs',
        route: RouteNames.about,
        accentColor: Color(0xFFF59E0B),
      ),
    ];

    return Padding(
      padding: AppSpacing.screenPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 480 ? 3 : 2;
          return GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, index) => _QuickActionTile(action: actions[index]),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Color accentColor;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '${action.label}: ${action.subtitle}',
      child: GlassCard(
        level: AppGlassLevel.level2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        onTap: () => context.go(action.route),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? action.accentColor.withOpacity(0.15)
                    : action.accentColor.withOpacity(0.1),
                borderRadius: AppRadius.radiusMd,
                border: Border.all(
                  color: action.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                action.icon,
                size: AppSizes.iconSm,
                color: action.accentColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    action.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Safety Overview Card
// ---------------------------------------------------------------------------

class _SafetyOverviewCard extends StatelessWidget {
  const _SafetyOverviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      level: AppGlassLevel.level2,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: AppSizes.iconSm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Engineering Principles',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Moha Lab Optimization does not apply fake FPS boosts, benchmark spoofing, or thermal bypasses. All optimizations are transparent, user-consented, and based on legitimate Android system APIs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social Links Card
// ---------------------------------------------------------------------------

class _SocialLinksCard extends StatelessWidget {
  const _SocialLinksCard();

  static const _tiktokUrl = 'https://www.tiktok.com/@professor0011110';
  static const _telegramUrl = 'https://t.me/Mohagaminglab';
  static const _websiteUrl = 'https://mohagaminglab.vercel.app/';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      level: AppGlassLevel.level2,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: TailwindColors.zinc400,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Follow Moha Lab',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TailwindColors.zinc100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tips, updates and gaming content.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: TailwindColors.zinc500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Buttons row
          Row(
            children: [
              // TikTok button
              Expanded(
                child: _SocialButton(
                  label: 'TikTok',
                  handle: '@professor0011110',
                  icon: Icons.play_circle_outline_rounded,
                  accentColor: const Color(0xFFEE1D52),
                  bgColor: const Color(0xFF2A0A10),
                  borderColor: const Color(0xFFEE1D52),
                  onTap: () => _launch(_tiktokUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Telegram button
              Expanded(
                child: _SocialButton(
                  label: 'Telegram',
                  handle: '@Mohagaminglab',
                  icon: Icons.send_rounded,
                  accentColor: const Color(0xFF2AABEE),
                  bgColor: const Color(0xFF06121D),
                  borderColor: const Color(0xFF2AABEE),
                  onTap: () => _launch(_telegramUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Website — full width
          _SocialButton(
            label: 'Website',
            handle: 'mohagaminglab.vercel.app',
            icon: Icons.language_rounded,
            accentColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF041A10),
            borderColor: const Color(0xFF10B981),
            onTap: () => _launch(_websiteUrl),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.handle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final String handle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      handle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: TailwindColors.zinc500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 13,
                color: accentColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
