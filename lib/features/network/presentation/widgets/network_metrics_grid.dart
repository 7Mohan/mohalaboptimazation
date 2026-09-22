import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../domain/entities/network_metrics.dart';

/// 2x2 grid displaying latency, jitter, packet loss, and DNS resolution timing.
class NetworkMetricsGrid extends StatelessWidget {
  const NetworkMetricsGrid({
    super.key,
    required this.metrics,
  });

  final NetworkMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.speed_rounded,
                label: 'Ping (Latency)',
                value: metrics.latencyDisplay,
                subtitle: metrics.minLatencyMs != null && metrics.maxLatencyMs != null
                    ? '${metrics.minLatencyMs!.toStringAsFixed(0)}–${metrics.maxLatencyMs!.toStringAsFixed(0)} ms range'
                    : null,
                color: _latencyColor(metrics.latencyMs),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.graphic_eq_rounded,
                label: 'Jitter',
                value: metrics.jitterDisplay,
                subtitle: 'Packet variance',
                color: _jitterColor(metrics.jitterMs),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.disc_full_rounded,
                label: 'Packet Loss',
                value: metrics.packetLossDisplay,
                subtitle: '${metrics.probeSamplesCount} probes tested',
                color: _packetLossColor(metrics.packetLossPercent),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.dns_rounded,
                label: 'DNS Resolution',
                value: metrics.dnsDisplay,
                subtitle: 'Host lookup timing',
                color: _dnsColor(metrics.dnsResolutionMs),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _latencyColor(double? ms) {
    if (ms == null) return Colors.grey;
    if (ms <= 40) return Colors.green;
    if (ms <= 90) return Colors.teal;
    if (ms <= 140) return Colors.amber;
    return Colors.red;
  }

  Color _jitterColor(double? ms) {
    if (ms == null) return Colors.grey;
    if (ms <= 8) return Colors.green;
    if (ms <= 18) return Colors.teal;
    return Colors.orange;
  }

  Color _packetLossColor(double percent) {
    if (percent == 0.0) return Colors.green;
    if (percent <= 2.0) return Colors.amber;
    return Colors.red;
  }

  Color _dnsColor(double? ms) {
    if (ms == null) return Colors.grey;
    if (ms <= 50) return Colors.green;
    if (ms <= 120) return Colors.teal;
    return Colors.amber;
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPaddingCompact,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
