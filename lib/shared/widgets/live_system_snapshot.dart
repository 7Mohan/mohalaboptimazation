import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens/app_glass.dart';
import '../../../core/theme/tokens/app_radius.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../features/diagnostics/data/providers/full_device_info_provider.dart';
import '../../features/network/presentation/providers/network_diagnostics_providers.dart';
import 'feedback/moha_loading_state.dart';
import 'glass/glass_card.dart';

/// Live system snapshot card displaying real-time telemetry:
/// Battery status, RAM availability, and Network health.
class LiveSystemSnapshot extends ConsumerWidget {
  const LiveSystemSnapshot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final batteryAsync = ref.watch(liveBatteryProvider);
    final memoryAsync = ref.watch(liveMemoryProvider);
    final networkState = ref.watch(networkDiagnosticsControllerProvider);

    return GlassCard(
      level: AppGlassLevel.level2,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: AppSizes.iconSm,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Live System Telemetry',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    ref.read(liveBatteryProvider.notifier).refresh();
                    ref.read(liveMemoryProvider.notifier).refresh();
                  },
                  borderRadius: AppRadius.radiusFull,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Refresh',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Battery Card
                Expanded(
                  child: batteryAsync.when(
                    data: (b) => _TelemetryTile(
                      icon: b.isCharging
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_std_rounded,
                      title: 'Battery',
                      value: b.percentage != null ? '${b.percentage}%' : 'N/A',
                      subtitle: b.isCharging
                          ? 'Charging'
                          : (b.temperatureC != null
                              ? '${b.temperatureC!.toStringAsFixed(1)}°C'
                              : b.status),
                      statusColor: (b.percentage ?? 100) < 20
                          ? Colors.orange
                          : const Color(0xFF10B981),
                    ),
                    loading: () => const _TelemetryLoadingTile(title: 'Battery'),
                    error: (_, __) => const _TelemetryTile(
                      icon: Icons.battery_unknown_rounded,
                      title: 'Battery',
                      value: 'Unavailable',
                      subtitle: 'Sensor error',
                      statusColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // RAM Card
                Expanded(
                  child: memoryAsync.when(
                    data: (m) {
                      final usedPercent = m.usedPercent;
                      final availGb = m.availableRamGb;
                      final isHigh = (usedPercent ?? 0) > 85;
                      return _TelemetryTile(
                        icon: Icons.memory_rounded,
                        title: 'RAM Active',
                        value: usedPercent != null ? '$usedPercent%' : 'N/A',
                        subtitle: availGb != null
                            ? '${availGb.toStringAsFixed(1)} GB Free'
                            : 'Active',
                        statusColor: isHigh ? Colors.orange : const Color(0xFF3B82F6),
                      );
                    },
                    loading: () => const _TelemetryLoadingTile(title: 'RAM Active'),
                    error: (_, __) => const _TelemetryTile(
                      icon: Icons.memory_rounded,
                      title: 'RAM Active',
                      value: 'Unavailable',
                      subtitle: 'Sensor error',
                      statusColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Network / Latency Card
                Expanded(
                  child: _buildNetworkTile(networkState),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildNetworkTile(NetworkDiagnosticsState state) {
    if (state.isRunning) {
      return const _TelemetryLoadingTile(title: 'Network');
    }

    final session = state.latestSession;
    if (session != null) {
      final ping = session.metrics.latencyMs?.round() ?? 0;
      final isGood = ping < 60;
      return _TelemetryTile(
        icon: Icons.wifi_tethering_rounded,
        title: 'Ping',
        value: '${ping}ms',
        subtitle: isGood ? 'Optimal' : 'High Jitter',
        statusColor: isGood ? const Color(0xFF10B981) : Colors.orange,
      );
    }

    return const _TelemetryTile(
      icon: Icons.wifi_rounded,
      title: 'Network',
      value: 'Ready',
      subtitle: 'Tap to test',
      statusColor: Color(0xFF10B981),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  const _TelemetryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.statusColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: statusColor),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TelemetryLoadingTile extends StatelessWidget {
  const _TelemetryLoadingTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MohaSkeleton(width: 16, height: 16),
          SizedBox(height: AppSpacing.xs),
          MohaSkeleton(width: 48, height: 16),
          SizedBox(height: 4),
          MohaSkeleton(width: 32, height: 12),
        ],
      ),
    );
  }
}
