import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ads/ad_placement.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/tokens/app_glass.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/ads/moha_banner_ad_widget.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/glass/animated_entry.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_section.dart';
import '../../../../shared/widgets/live_system_snapshot.dart';
import '../../../community/presentation/widgets/startup_community_dialog.dart';
import '../../../diagnostics/data/providers/full_device_info_provider.dart';
import '../../../onboarding/presentation/tour/feature_tour.dart';
import '../../../onboarding/presentation/widgets/how_to_use_dialog.dart';
import '../../../optimization/domain/tweak_catalog.dart';
import '../../../optimization/presentation/providers/tweak_providers.dart';
import '../../../optimization/presentation/widgets/tweak_widgets.dart';
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MohaAppBar(
        title: 'Optimization',
        subtitle: _greeting(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'How to use Moha Lab',
            onPressed: () => HowToUseDialog.showExplicit(context),
          ),
        ],
      ),
      body: ListView(
        // Build every section up front so the feature tour can find them.
        cacheExtent: 3000,
        padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppShell.bottomInset(context)),
        children: [
          AnimatedEntry.staggered(
            index: 0,
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: KeyedSubtree(key: TourKeys.homeHero, child: const _HeroCard()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedEntry.staggered(
            index: 1,
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: KeyedSubtree(key: TourKeys.homeTelemetry, child: const LiveSystemSnapshot()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedEntry.staggered(
            index: 2,
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: KeyedSubtree(
                key: TourKeys.homeVitals,
                child: const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: CpuUsageChart()),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: TemperatureMonitorWidget()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedEntry.staggered(
            index: 3,
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: KeyedSubtree(key: TourKeys.homeStorage, child: const StorageCleanerWidget()),
            ),
          ),
          AnimatedEntry.staggered(
            index: 4,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassSectionLabel('Quick Actions', icon: Icons.bolt_rounded),
                _QuickActionsGrid(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedEntry.staggered(
            index: 5,
            child: const Padding(padding: AppSpacing.screenPadding, child: _PrinciplesCard()),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedEntry.staggered(
            index: 6,
            child: const Padding(padding: AppSpacing.screenPadding, child: _SocialLinksCard()),
          ),
          const SizedBox(height: AppSpacing.md),
          const MohaBannerAdWidget(placement: AdPlacement.homeBanner),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero: device identity, real tweak status and a measured one-tap boost.
// ---------------------------------------------------------------------------

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final identity = ref.watch(fullDeviceInfoProvider).valueOrNull?.identity;
    final snapshot = ref.watch(tweaksControllerProvider).valueOrNull ?? const TweaksSnapshot();
    final boosting = snapshot.isBusy(TweakCatalog.ramBoost.id);
    final active = snapshot.activeCount;
    final caps = snapshot.capabilities;

    final name = (identity != null && identity.manufacturer != 'Unavailable')
        ? '${identity.manufacturer} ${identity.model}'
        : 'Your device';
    final android = (identity != null && identity.androidVersion != 'Unavailable')
        ? 'Android ${identity.androidVersion}'
        : 'Android';

    return GlassCard(
      level: AppGlassLevel.level3,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      android,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: caps.shizukuReady
                    ? 'Shizuku'
                    : (caps.secureSettingsGranted ? 'ADB grant' : 'Standard'),
                on: caps.shizukuReady || caps.secureSettingsGranted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$active',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color:
                            active > 0 ? theme.colorScheme.tertiary : theme.colorScheme.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active == 1 ? 'tweak active' : 'tweaks active',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.optimization),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Manage'),
              ),
              const SizedBox(width: AppSpacing.xs),
              KeyedSubtree(
                key: TourKeys.homeBoost,
                child: _BoostButton(
                  busy: boosting,
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final res = await ref
                        .read(tweaksControllerProvider.notifier)
                        .runAction(TweakCatalog.ramBoost.id);
                    ref.invalidate(liveMemoryProvider);
                    if (context.mounted) showTweakResult(context, res);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = on ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: AppRadius.radiusFull,
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BoostButton extends StatelessWidget {
  const _BoostButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'RAM Boost',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusFull,
          gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.radiusFull,
            onTap: busy ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Boost',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    _QuickAction(Icons.tune_rounded, 'Tweaks', 'Display, clocks, focus', RouteNames.optimization,
        Color(0xFF7AA5FF)),
    _QuickAction(Icons.sports_esports_rounded, 'Games', 'Per-game Game Mode', RouteNames.games,
        Color(0xFFB4A8FF)),
    _QuickAction(Icons.network_check_rounded, 'Network', 'Ping, jitter, loss', RouteNames.network,
        Color(0xFF4FE3C8)),
    _QuickAction(Icons.monitor_heart_rounded, 'Device', 'Hardware details', RouteNames.diagnostics,
        Color(0xFFFFB86B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: KeyedSubtree(
        key: TourKeys.homeQuickActions,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.3,
          children: [for (final a in _actions) _QuickActionTile(action: a)],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.subtitle, this.route, this.color);

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Color color;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${action.label}: ${action.subtitle}',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        onTap: () => action.route == RouteNames.network
            ? context.push(action.route)
            : context.go(action.route),
        child: Row(
          children: [
            GlassIconTile(icon: action.icon, color: action.color, size: 38),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.label,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
// Principles & social
// ---------------------------------------------------------------------------

class _PrinciplesCard extends StatelessWidget {
  const _PrinciplesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: AppSpacing.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconTile(
              icon: Icons.verified_user_rounded, color: theme.colorScheme.tertiary, size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No placebo tweaks',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Every tweak writes a documented Android setting, is read back to confirm it applied, '
                  'and restores your original value when turned off. No fake FPS boosts, spoofing or thermal bypasses.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Follow Moha Lab',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            'Tips, updates and gaming content.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'TikTok',
                  icon: Icons.play_circle_outline_rounded,
                  color: const Color(0xFFEE1D52),
                  onTap: () => _launch(_tiktokUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _SocialButton(
                  label: 'Telegram',
                  icon: Icons.send_rounded,
                  color: const Color(0xFF2AABEE),
                  onTap: () => _launch(_telegramUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _SocialButton(
                  label: 'Website',
                  icon: Icons.language_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => _launch(_websiteUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.35))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
