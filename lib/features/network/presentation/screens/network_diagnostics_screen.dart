import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/ad_guard.dart';
import '../../../../core/ads/ad_placement.dart';
import '../../../../core/ads/ad_providers.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/ads/rewarded_ad_button.dart';
import '../../../../shared/widgets/app_bars/moha_app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/network_diagnostics_providers.dart';
import '../widgets/network_history_section.dart';
import '../widgets/network_metrics_grid.dart';
import '../widgets/network_overview_card.dart';
import '../widgets/network_recommendations_list.dart';
import '../widgets/network_verdict_badge.dart';

/// Screen executing gaming network diagnostics, displaying latency, jitter, packet loss,
/// and factual recommendations without exaggerated speed-boost claims.
class NetworkDiagnosticsScreen extends ConsumerStatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  ConsumerState<NetworkDiagnosticsScreen> createState() =>
      _NetworkDiagnosticsScreenState();
}

class _NetworkDiagnosticsScreenState
    extends ConsumerState<NetworkDiagnosticsScreen> {
  bool _wasRunning = false;
  bool _bandwidthUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(networkDiagnosticsControllerProvider);
    final session = state.latestSession;

    // Detect run completion and trigger interstitial at that natural point.
    if (_wasRunning && !state.isRunning && session != null) {
      _wasRunning = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(adServiceProvider).showInterstitial(
                AdPlacement.postDiagnosticsInterstitial,
                canShow: canShowAd(ref),
              );
        }
      });
    }
    if (state.isRunning) _wasRunning = true;

    return Scaffold(
      appBar: const MohaAppBar(
        title: 'Network Diagnostics',
        subtitle: 'Real-time gaming latency & packet health',
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // Safety & Transparency banner
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: AppSizes.iconMd,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diagnostic Transparency',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This tool diagnoses packet timing, jitter, and loss to external gaming edge servers. '
                            'It does not modify your carrier APN, routing tables, or install VPN profiles.',
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
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Active Connection Overview
          const SectionHeader(
            title: 'Active Connection',
            subtitle: 'Current interface transport and local gateway.',
            icon: Icons.router_outlined,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: NetworkOverviewCard(metrics: session?.metrics),
          ),

          // Action button / Execution progress
          Padding(
            padding: AppSpacing.screenPadding,
            child: state.isRunning
                ? Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                state.progressStep,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sending discrete probe pulses to measure RTT, jitter, and packet loss...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    key: const Key('run_network_diagnostics_button'),
                    onPressed: () {
                      ref
                          .read(networkDiagnosticsControllerProvider.notifier)
                          .runDiagnostics();
                    },
                    icon: const Icon(Icons.network_check_rounded),
                    label: Text(
                      session == null ? 'Run Network Diagnostics' : 'Re-Run Diagnostics',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
          ),

          // Rewarded ad: watch an ad to unlock manual bandwidth speed test.
          if (!state.isRunning)
            Padding(
              padding: AppSpacing.screenPadding,
              child: _bandwidthUnlocked
                  ? _BandwidthTestUnlocked(theme: theme)
                  : RewardedAdButton(
                      label: 'Watch ad to unlock bandwidth test',
                      onRewarded: () {
                        setState(() => _bandwidthUnlocked = true);
                      },
                    ),
            ),

          if (state.errorMessage != null)
            Padding(
              padding: AppSpacing.screenPadding,
              child: Container(
                padding: AppSpacing.cardPaddingCompact,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: AppRadius.radiusSm,
                  border: Border.all(color: theme.colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Diagnostic Results (if available)
          if (session != null) ...[
            const SectionHeader(
              title: 'Gaming Quality Verdict',
              subtitle: 'Multiplayer responsiveness and stability assessment.',
              icon: Icons.sports_esports_outlined,
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: NetworkVerdictBadge(
                verdict: session.primaryVerdict,
                secondaryVerdicts: session.secondaryVerdicts,
              ),
            ),

            const SectionHeader(
              title: 'Telemetry Metrics',
              subtitle: 'Discrete packet probe timing measurements.',
              icon: Icons.analytics_outlined,
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: NetworkMetricsGrid(metrics: session.metrics),
            ),

            if (session.recommendations.isNotEmpty) ...[
              const SectionHeader(
                title: 'Factual Recommendations',
                subtitle: 'Grounded in observed telemetry without unsubstantiated blaming.',
                icon: Icons.tips_and_updates_outlined,
              ),
              Padding(
                padding: AppSpacing.screenPadding,
                child: NetworkRecommendationsList(
                  recommendations: session.recommendations,
                ),
              ),
            ],
          ],

          // Historical Sessions
          const SectionHeader(
            title: 'Diagnostic History',
            subtitle: 'Locally stored past network test records.',
            icon: Icons.history_rounded,
          ),
          Padding(
            padding: AppSpacing.screenPadding,
            child: NetworkHistorySection(history: state.history),
          ),
        ],
      ),
    );
  }
}

/// Shown once the user has earned the bandwidth test reward.
class _BandwidthTestUnlocked extends StatelessWidget {
  const _BandwidthTestUnlocked({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPaddingCompact,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_rounded,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandwidth Test Unlocked',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Manual bandwidth test is now available for this session.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
